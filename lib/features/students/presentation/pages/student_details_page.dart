import 'package:flutter/material.dart';

import '../../domain/entities/student_entity.dart';
import 'add_student_page.dart';

class StudentDetailsPage extends StatelessWidget {
  final StudentEntity student;

  const StudentDetailsPage({
    super.key,
    required this.student,
  });

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }

  Future<void> _editStudent(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddStudentPage(
          student: student,
        ),
      ),
    );

    if (context.mounted && result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop =
        MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1400,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _Header(
                  student: student,
                  onEdit: () => _editStudent(context),
                ),

                const SizedBox(height: 24),

                if (desktop)
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _InfoSection(
                              title:
                                  'Personal Information',
                              icon: Icons.person,
                              children: [
                                _InfoTile(
                                  label: 'Full Name',
                                  value:
                                      student.fullName,
                                ),
                                _InfoTile(
                                  label: 'Gender',
                                  value: student.gender,
                                ),
                                _InfoTile(
                                  label:
                                      'Date of Birth',
                                  value: _formatDate(
                                    student
                                        .dateOfBirth,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 20),

                            _InfoSection(
                              title:
                                  'Academic Information',
                              icon: Icons.school,
                              children: [
                                _InfoTile(
                                  label:
                                      'Admission No.',
                                  value: student
                                      .admissionNo,
                                ),
                                _InfoTile(
                                  label: 'Class',
                                  value:
                                      student.classId,
                                ),
                                _InfoTile(
                                  label: 'Section',
                                  value: student
                                      .sectionId,
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 20),

                            _InfoSection(
                              title:
                                  'Parent Information',
                              icon:
                                  Icons.family_restroom,
                              children: [
                                _InfoTile(
                                  label:
                                      'Father Name',
                                  value: student
                                      .fatherName,
                                ),
                                _InfoTile(
                                  label:
                                      'Mother Name',
                                  value: student
                                      .motherName,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      Expanded(
                        child: Column(
                          children: [
                            _InfoSection(
                              title:
                                  'Contact Information',
                              icon: Icons.contact_mail,
                              children: [
                                _InfoTile(
                                  label:
                                      'Mobile Number',
                                  value: student
                                      .guardianPhone,
                                ),
                                _InfoTile(
                                  label: 'Email',
                                  value: student
                                      .guardianEmail,
                                ),
                                _InfoTile(
                                  label: 'Address',
                                  value:
                                      student.address,
                                  multiline: true,
                                ),
                              ],
                            ),

                            const SizedBox(
                                height: 20),

                            _InfoSection(
                              title:
                                  'System Information',
                              icon: Icons.info,
                              children: [
                                _InfoTile(
                                  label:
                                      'Student ID',
                                  value: student.id,
                                ),
                                _InfoTile(
                                  label:
                                      'Created Date',
                                  value:
                                      _formatDate(
                                    student
                                        .createdAt,
                                  ),
                                ),
                                _InfoTile(
                                  label:
                                      'Updated Date',
                                  value:
                                      _formatDate(
                                    student
                                        .updatedAt,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _InfoSection(
                        title:
                            'Personal Information',
                        icon: Icons.person,
                        children: [
                          _InfoTile(
                            label: 'Full Name',
                            value: student.fullName,
                          ),
                          _InfoTile(
                            label: 'Gender',
                            value: student.gender,
                          ),
                          _InfoTile(
                            label:
                                'Date of Birth',
                            value: _formatDate(
                                student.dateOfBirth),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title:
                            'Academic Information',
                        icon: Icons.school,
                        children: [
                          _InfoTile(
                            label:
                                'Admission No.',
                            value:
                                student.admissionNo,
                          ),
                          _InfoTile(
                            label: 'Class',
                            value: student.classId,
                          ),
                          _InfoTile(
                            label: 'Section',
                            value:
                                student.sectionId,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title:
                            'Parent Information',
                        icon:
                            Icons.family_restroom,
                        children: [
                          _InfoTile(
                            label:
                                'Father Name',
                            value:
                                student.fatherName,
                          ),
                          _InfoTile(
                            label:
                                'Mother Name',
                            value:
                                student.motherName,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title:
                            'Contact Information',
                        icon:
                            Icons.contact_mail,
                        children: [
                          _InfoTile(
                            label:
                                'Mobile Number',
                            value: student
                                .guardianPhone,
                          ),
                          _InfoTile(
                            label: 'Email',
                            value: student
                                .guardianEmail,
                          ),
                          _InfoTile(
                            label: 'Address',
                            value:
                                student.address,
                            multiline: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title:
                            'System Information',
                        icon: Icons.info,
                        children: [
                          _InfoTile(
                            label:
                                'Student ID',
                            value: student.id,
                          ),
                          _InfoTile(
                            label:
                                'Created Date',
                            value: _formatDate(
                                student
                                    .createdAt),
                          ),
                          _InfoTile(
                            label:
                                'Updated Date',
                            value: _formatDate(
                                student
                                    .updatedAt),
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onEdit;

  const _Header({
    required this.student,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final desktop =
        MediaQuery.of(context).size.width >= 800;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: desktop
            ? Row(
                children: [
                  _avatar(),
                  const SizedBox(width: 24),
                  Expanded(child: _info()),
                  FilledButton.icon(
                    onPressed: onEdit,
                    icon:
                        const Icon(Icons.edit),
                    label: const Text(
                        'Edit Student'),
                  ),
                ],
              )
            : Column(
                children: [
                  _avatar(),
                  const SizedBox(height: 16),
                  _info(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(
                          Icons.edit),
                      label: const Text(
                          'Edit Student'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 55,
      backgroundImage:
          student.profileImageUrl.isNotEmpty
              ? NetworkImage(
                  student.profileImageUrl)
              : null,
      child:
          student.profileImageUrl.isEmpty
              ? const Icon(
                  Icons.person,
                  size: 55,
                )
              : null,
    );
  }

  Widget _info() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          student.fullName,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Admission No: ${student.admissionNo}',
        ),
        const SizedBox(height: 14),
        _StatusChip(
          active: student.isActive,
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        active
            ? Icons.check_circle
            : Icons.cancel,
        size: 18,
        color: Colors.white,
      ),
      backgroundColor:
          active
              ? Colors.green
              : Colors.red,
      label: Text(
        active ? 'Active' : 'Inactive',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                        fontWeight:
                            FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _InfoTile({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue =
        value.trim().isEmpty ? '-' : value;

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              displayValue,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}