import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
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
  late final TextEditingController _name;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _relationship;

  List<StudentEntity> _matchedStudents = const [];
  final Set<String> _selectedStudentIds = {};
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.fullName ?? '');
    _mobile = TextEditingController(text: existing?.mobileNumber ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _relationship = TextEditingController(
      text: existing?.relationship ?? 'Guardian',
    );
    _selectedStudentIds.addAll(existing?.studentIds ?? const []);
    if (existing != null) {
      _loadExistingStudents(existing);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    _email.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _loadExistingStudents(ParentAccountEntity parent) async {
    setState(() => _searching = true);
    try {
      final values = await sl<ParentPortalRepository>().getLinkedStudents(
        parent,
      );
      if (!mounted) return;
      setState(() => _matchedStudents = values);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _findStudents() async {
    if (_mobile.text.trim().isEmpty && _email.text.trim().isEmpty) {
      _show('Enter mobile number or email address.');
      return;
    }

    setState(() => _searching = true);

    try {
      final values = await sl<ParentPortalRepository>().findStudentsByGuardian(
        mobileNumber: _mobile.text,
        email: _email.text,
      );

      if (!mounted) return;

      setState(() {
        _matchedStudents = values;
        if (values.length == 1) {
          _selectedStudentIds.add(values.first.id);
        }
      });

      if (values.isEmpty) {
        _show('No active student found with this guardian phone/email.');
      }
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStudentIds.isEmpty) {
      _show('Select at least one student.');
      return;
    }

    final old = widget.existing;
    final now = DateTime.now();

    Navigator.pop(
      context,
      ParentAccountEntity(
        id: old?.id ?? sl<ParentPortalRepository>().generateId(),
        fullName: _name.text.trim(),
        mobileNumber: _mobile.text.trim(),
        email: _email.text.trim(),
        relationship: _relationship.text.trim(),
        studentIds: _selectedStudentIds.toList(),
        isActive: old?.isActive ?? true,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()],
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
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Parent / Guardian Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    controller: _mobile,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextFormField(
                    controller: _relationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: _searching ? null : _findStudents,
                icon: _searching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_search),
                label: const Text('Find Linked Students'),
              ),
            ),
            const SizedBox(height: 12),
            if (_matchedStudents.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked Children',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      for (final student in _matchedStudents)
                        CheckboxListTile(
                          value: _selectedStudentIds.contains(student.id),
                          title: Text(student.fullName),
                          subtitle: Text(
                            '${student.admissionNo} • '
                            '${student.classId} / ${student.sectionId}',
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
              ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Parent Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
