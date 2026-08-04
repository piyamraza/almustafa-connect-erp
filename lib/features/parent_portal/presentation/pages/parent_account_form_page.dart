import 'package:flutter/material.dart';

import '../../../../core/contact/contact_number_helper.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/contact_info_field.dart';
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

  late final TextEditingController _userId;
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _whatsapp;
  late final TextEditingController _email;
  late final TextEditingController _relationship;
  late final TextEditingController _branchId;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _emergencyRelationship;
  late final TextEditingController _studentSearch;

  List<StudentEntity> _students = const <StudentEntity>[];
  final Set<String> _selectedStudentIds = <String>{};

  bool _sameAsMobile = true;
  bool _isPrimaryContact = false;
  bool _loadingStudents = true;
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
    _emergencyName = TextEditingController(
      text: existing?.emergencyContactName ?? '',
    );
    _emergencyPhone = TextEditingController(
      text: existing?.emergencyContactPhone ?? '',
    );
    _emergencyRelationship = TextEditingController(
      text: existing?.emergencyContactRelationship ?? '',
    );
    _studentSearch = TextEditingController()..addListener(_refreshStudentList);

    _selectedStudentIds.addAll(existing?.studentIds ?? const <String>[]);
    _isPrimaryContact = existing?.isPrimaryContact ?? false;
    _accountStatus =
        existing?.normalizedAccountStatus ??
        ParentAccountEntity.accountStatusActive;

    _loadStudents();
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
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _emergencyRelationship.dispose();
    _studentSearch
      ..removeListener(_refreshStudentList)
      ..dispose();
    super.dispose();
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
        emergencyContactName: _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim(),
        emergencyContactRelationship: _emergencyRelationship.text.trim(),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? 'Create Parent Account'
              : 'Edit Parent Account',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionTitle(context, 'Account & Identity'),
            const SizedBox(height: 10),
            _responsiveRow(
              children: [
                TextFormField(
                  controller: _userId,
                  decoration: const InputDecoration(
                    labelText: 'Firebase User ID',
                    helperText: 'Leave empty until a login is assigned.',
                    border: OutlineInputBorder(),
                  ),
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
                    'Preferred contact for school communication.',
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
            _sectionTitle(context, 'Emergency Contact'),
            const SizedBox(height: 10),
            _responsiveRow(
              children: [
                TextFormField(
                  controller: _emergencyName,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  controller: _emergencyPhone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Contact Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextFormField(
                  controller: _emergencyRelationship,
                  decoration: const InputDecoration(
                    labelText: 'Emergency Relationship',
                    border: OutlineInputBorder(),
                  ),
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
            else if (filteredStudents.isEmpty)
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
              Card(
                child: Column(
                  children: [
                    for (final student in filteredStudents)
                      CheckboxListTile(
                        value: _selectedStudentIds.contains(student.id),
                        title: Text(student.fullName),
                        subtitle: Row(
                          children: [
                            Text(
                              '${student.admissionNo} â€¢ '
                              '${student.rollNumber} â€¢ ',
                            ),
                            Expanded(
                              child: AcademicReferenceLabel(
                                classReference: student.classId,
                                sectionReference: student.sectionId,
                              ),
                            ),
                          ],
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
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(
              '${_selectedStudentIds.length} student(s) selected',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 22),
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
          ],
        ),
      ),
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
