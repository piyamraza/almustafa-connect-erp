import 'package:flutter/material.dart';

import '../../../../core/contact/contact_number_helper.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/contact_info_field.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../access_control/domain/entities/user_account_entity.dart';
import '../../../access_control/domain/services/user_account_service.dart';
import '../../../access_control/data/services/user_account_service_impl.dart';
import '../../../academic_structure/presentation/widgets/academic_reference_label.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';

class ParentAccountFormPage extends StatefulWidget {
  const ParentAccountFormPage({super.key, this.existing});

  final ParentAccountEntity? existing;

  @override
  State<ParentAccountFormPage> createState() => _ParentAccountFormPageState();
}

class _ParentAccountFormPageState extends State<ParentAccountFormPage> {
  final _formKey = GlobalKey<FormState>();

  final ParentPortalRepository _parentRepository = sl<ParentPortalRepository>();
  final StudentRepository _studentRepository = sl<StudentRepository>();
  final UserAccountService _userAccountService = UserAccountServiceImpl();

  late final TextEditingController _userId;
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _relationship;
  late final TextEditingController _branchId;
  late final TextEditingController _studentSearch;

  List<StudentEntity> _students = const <StudentEntity>[];
  List<UserAccountEntity> _availableParentUsers = const <UserAccountEntity>[];
  final Set<String> _selectedStudentIds = <String>{};
  final Set<String> _autoMatchedStudentIds = <String>{};

  bool _sameAsMobile = true;
  bool _isPrimaryContact = false;
  bool _loadingStudents = true;
  bool _loadingParentUsers = true;
  bool _saving = false;
  String _accountStatus = ParentAccountEntity.accountStatusActive;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;

    _userId = TextEditingController(text: existing?.userId ?? '');
    _name = TextEditingController(text: existing?.fullName ?? '');
    _mobile = TextEditingController(text: existing?.mobileNumber ?? '');
    _whatsapp = TextEditingController(
      text: existing?.whatsappNumber.isNotEmpty == true
          ? existing!.whatsappNumber
          : existing?.mobileNumber ?? '',
    );
    _sameAsMobile =
        existing == null ||
        ContactNumberHelper.areSameNumbers(_mobile.text, _whatsapp.text);
    _email = TextEditingController(text: existing?.email ?? '');
    _relationship = TextEditingController(
      text: existing?.relationship ?? 'Guardian',
    );
    _branchId = TextEditingController(text: existing?.branchId ?? 'main');
    _studentSearch = TextEditingController()..addListener(_refreshStudentList);

    _selectedStudentIds.addAll(existing?.studentIds ?? const <String>[]);
    _isPrimaryContact = existing?.isPrimaryContact ?? false;
    _accountStatus =
        existing?.normalizedAccountStatus ??
        ParentAccountEntity.accountStatusActive;

    _loadStudents();
    _loadParentUsers();
  }

  @override
  void dispose() {
    _userId.dispose();
    _name.dispose();
    _mobile.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _relationship.dispose();
    _branchId.dispose();
    _studentSearch
      ..removeListener(_refreshStudentList)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadParentUsers() async {
    try {
      final values = await Future.wait<Object>([
        _userAccountService.listAccounts(),
        _parentRepository.getParents(),
      ]);
      if (!mounted) return;

      final users = values[0] as List<UserAccountEntity>;
      final parents = values[1] as List<ParentAccountEntity>;
      final currentParentId = widget.existing?.id;
      final assignedUserIds = parents
          .where((parent) => parent.id != currentParentId)
          .map((parent) => parent.userId.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      setState(() {
        _availableParentUsers = users.where((user) {
          final role = '${user.roleId} ${user.roleName}'.toLowerCase();
          return role.contains('parent') &&
              user.isActive &&
              !user.disabled &&
              !assignedUserIds.contains(user.uid);
        }).toList(growable: false);
        _loadingParentUsers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingParentUsers = false);
      _show('Parent login accounts could not be loaded: $error');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final values = await _studentRepository.getStudents();

      if (!mounted) return;

      setState(() {
        _students = values
            .where((student) => student.isActive)
            .toList(growable: false);
        _loadingStudents = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadingStudents = false);
      _show(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', ''),
      );
    }
  }

  void _refreshStudentList() {
    if (mounted) {
      setState(() {});
    }
  }

  List<StudentEntity> get _filteredStudents {
    final query = _studentSearch.text.trim().toLowerCase();

    final values =
        _students.where((student) {
          if (query.isEmpty) return true;

          return student.fullName.toLowerCase().contains(query) ||
              student.admissionNo.toLowerCase().contains(query) ||
              student.rollNumber.toLowerCase().contains(query) ||
              student.classId.toLowerCase().contains(query) ||
              student.sectionId.toLowerCase().contains(query) ||
              student.fatherName.toLowerCase().contains(query);
        }).toList()..sort(
          (first, second) => first.fullName.toLowerCase().compareTo(
            second.fullName.toLowerCase(),
          ),
        );

    return List<StudentEntity>.unmodifiable(values);
  }

  Future<void> _autoFindStudents() async {
    if (_mobile.text.trim().isEmpty && _email.text.trim().isEmpty) {
      _show('Enter mobile number or email address first.');
      return;
    }

    setState(() => _loadingStudents = true);

    try {
      final values = await _parentRepository.findStudentsByGuardian(
        mobileNumber: _mobile.text,
        email: _email.text,
      );

      if (!mounted) return;

      setState(() {
        _autoMatchedStudentIds
          ..clear()
          ..addAll(values.map((student) => student.id));
        for (final student in values) {
          _selectedStudentIds.add(student.id);
        }
        _loadingStudents = false;
      });

      _show(
        values.isEmpty
            ? 'No matching active student was found.'
            : '${values.length} matching student(s) selected.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _loadingStudents = false);
      _show(error.toString());
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudentIds.isEmpty) {
      _show('Select at least one student.');
      return;
    }

    setState(() => _saving = true);

    try {
      final old = widget.existing;
      final now = DateTime.now();

      final parent = ParentAccountEntity(
        id: old?.id ?? _parentRepository.generateId(),
        userId: _userId.text.trim(),
        fullName: _name.text.trim(),
        mobileNumber: _mobile.text.trim(),
        whatsappNumber: _whatsapp.text.trim(),
        email: _email.text.trim(),
        relationship: _relationship.text.trim(),
        studentIds: _selectedStudentIds.toList(growable: false),
        branchId: _branchId.text.trim().isEmpty
            ? 'main'
            : _branchId.text.trim(),
        accountStatus: _accountStatus,
        isPrimaryContact: _isPrimaryContact,
        emergencyContactName: old?.emergencyContactName ?? '',
        emergencyContactPhone: old?.emergencyContactPhone ?? '',
        emergencyContactRelationship:
            old?.emergencyContactRelationship ?? '',
        isActive: _accountStatus == ParentAccountEntity.accountStatusActive,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      );

      await _parentRepository.saveParent(parent);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      _show(
        error
            .toString()
            .replaceFirst('Bad state: ', '')
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    return valid ? null : 'Enter a valid email address';
  }

  void _show(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents;
    final autoMatchedStudents = _students
        .where((student) => _autoMatchedStudentIds.contains(student.id))
        .toList()
      ..sort(
        (first, second) => first.fullName.toLowerCase().compareTo(
          second.fullName.toLowerCase(),
        ),
      );
    final otherStudents = filteredStudents
        .where((student) => !_autoMatchedStudentIds.contains(student.id))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Create Parent Account'
              : 'Edit Parent Account',
        ),
        actions: const [DashboardNavigationButton()],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save Parent Account'),
              ),
            ),
            const SizedBox(height: 18),
            _sectionTitle(context, 'Account & Identity'),
            const SizedBox(height: 10),
            _responsiveRow(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _userId.text.trim().isEmpty
                      ? null
                      : _userId.text.trim(),
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Parent Login Account',
                    helperText: _loadingParentUsers
                        ? 'Loading Parent-role accounts...'
                        : 'Only unused Parent-role accounts are shown.',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                  ),
                  items: [
                    if (_userId.text.trim().isNotEmpty &&
                        !_availableParentUsers.any(
                          (user) => user.uid == _userId.text.trim(),
                        ))
                      DropdownMenuItem(
                        value: _userId.text.trim(),
                        child: Text('Current login - ${_userId.text.trim()}'),
                      ),
                    for (final user in _availableParentUsers)
                      DropdownMenuItem(
                        value: user.uid,
                        child: Text(
                          '${user.displayName.trim().isEmpty ? user.email : user.displayName}'
                          ' - ${user.email}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _loadingParentUsers
                      ? null
                      : (value) {
                          _userId.text = value ?? '';
                          UserAccountEntity? selectedUser;
                          for (final user in _availableParentUsers) {
                            if (user.uid == value) {
                              selectedUser = user;
                              break;
                            }
                          }
                          if (selectedUser != null) {
                            if (_name.text.trim().isEmpty) {
                              _name.text = selectedUser.displayName;
                            }
                            if (_email.text.trim().isEmpty) {
                              _email.text = selectedUser.email;
                            }
                          }
                        },
                ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Parent / Guardian Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _required(value, 'Parent name'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _responsiveRow(
              children: [
                TextFormField(
                  controller: _relationship,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _required(value, 'Relationship'),
                ),
                TextFormField(
                  controller: _branchId,
                  decoration: const InputDecoration(
                    labelText: 'Branch ID',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => _required(value, 'Branch'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ContactInfoField(
              mobileController: _mobile,
              whatsappController: _whatsapp,
              sameAsMobile: _sameAsMobile,
              onSameAsMobileChanged: (value) {
                setState(() => _sameAsMobile = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 18),
            _sectionTitle(context, 'Status & Contact Priority'),
            const SizedBox(height: 10),
            _responsiveRow(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _accountStatus,
                  decoration: const InputDecoration(
                    labelText: 'Account Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: ParentAccountEntity.accountStatusActive,
                      child: Text('Active'),
                    ),
                    DropdownMenuItem(
                      value: ParentAccountEntity.accountStatusInactive,
                      child: Text('Inactive'),
                    ),
                    DropdownMenuItem(
                      value: ParentAccountEntity.accountStatusBlocked,
                      child: Text('Blocked'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _accountStatus =
                          value ?? ParentAccountEntity.accountStatusActive;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Primary Contact'),
                  subtitle: const Text(
                    'If a student has multiple parents, contact this person first.',
                  ),
                  value: _isPrimaryContact,
                  onChanged: (value) {
                    setState(() {
                      _isPrimaryContact = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionTitle(context, 'Linked Students'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _studentSearch,
                    decoration: InputDecoration(
                      labelText:
                          'Search name, admission no., roll no., class or section',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _studentSearch.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _studentSearch.clear,
                              icon: const Icon(Icons.clear),
                            ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(
                  onPressed: _loadingStudents ? null : _autoFindStudents,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Auto Match'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_loadingStudents)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (filteredStudents.isEmpty && autoMatchedStudents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No active students match the search.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (autoMatchedStudents.isNotEmpty) ...[
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${autoMatchedStudents.length} Auto-Matched Student(s)',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (
                              var index = 0;
                              index < autoMatchedStudents.length;
                              index++
                            ) ...[
                              _studentTile(autoMatchedStudents[index]),
                              if (index < autoMatchedStudents.length - 1)
                                const Divider(height: 1),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (otherStudents.isNotEmpty)
                    Card(
                      child: Column(
                        children: [
                          for (
                            var index = 0;
                            index < otherStudents.length;
                            index++
                          ) ...[
                            _studentTile(otherStudents[index]),
                            if (index < otherStudents.length - 1)
                              const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              '${_selectedStudentIds.length} student(s) selected',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentTile(StudentEntity student) {
    final textTheme = Theme.of(context).textTheme;
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      value: _selectedStudentIds.contains(student.id),
      title: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(
            student.fullName,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (student.fatherName.trim().isNotEmpty)
            Text(
              'Father: ${student.fatherName}',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Admission: ${student.admissionNo}'),
            Text('Roll No: ${student.rollNumber}'),
            AcademicReferenceLabel(
              classReference: student.classId,
              sectionReference: student.sectionId,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onChanged: (selected) {
        setState(() {
          if (selected ?? false) {
            _selectedStudentIds.add(student.id);
          } else {
            _selectedStudentIds.remove(student.id);
          }
        });
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _responsiveRow({required List<Widget> children}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index < children.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }
}
