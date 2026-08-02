import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../domain/entities/student_entity.dart';
import '../bloc/student_bloc.dart';
import 'add_student_page.dart';

class StudentDetailsPage extends StatefulWidget {
  final StudentEntity student;

  const StudentDetailsPage({super.key, required this.student});

  @override
  State<StudentDetailsPage> createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  StudentEntity get student => widget.student;
  String? _className;
  String? _sectionName;

  @override
  void initState() {
    super.initState();
    _resolveAcademicNames();
  }

  Future<void> _resolveAcademicNames() async {
    try {
      final repository = sl<AcademicStructureRepository>();
      final values = await Future.wait<Object>([
        repository.getClasses(),
        repository.getSections(),
      ]);
      final classes = values[0] as List<AcademicClassEntity>;
      final sections = values[1] as List<SectionEntity>;

      AcademicClassEntity? matchingClass;
      for (final value in classes) {
        if (value.id == student.classId || value.name == student.classId) {
          matchingClass = value;
          break;
        }
      }

      SectionEntity? matchingSection;
      // A stored section document ID is globally unique and must take
      // precedence. Older records may have a stale/missing classId link.
      for (final value in sections) {
        if (value.id == student.sectionId) {
          matchingSection = value;
          break;
        }
      }
      // Legacy student records sometimes store the section name instead.
      matchingSection ??= _findSectionByName(
        sections,
        student.sectionId,
        matchingClass?.id,
      );
      if (!mounted) return;
      setState(() {
        _className = matchingClass?.name ?? student.classId;
        _sectionName = matchingSection?.name ?? student.sectionId;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _className = student.classId;
        _sectionName = student.sectionId;
      });
    }
  }

  SectionEntity? _findSectionByName(
    List<SectionEntity> sections,
    String storedValue,
    String? classId,
  ) {
    final normalized = storedValue.trim().toLowerCase();
    for (final value in sections) {
      if (value.name.trim().toLowerCase() == normalized &&
          (classId == null || value.classId == classId)) {
        return value;
      }
    }
    return null;
  }

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
        builder: (_) => BlocProvider.value(
          value: context.read<StudentBloc>(),
          child: AddStudentPage(student: student),
        ),
      ),
    );

    if (context.mounted && result == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool desktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Student Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(student: student, onEdit: () => _editStudent(context)),

                const SizedBox(height: 24),

                if (desktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _InfoSection(
                              title: 'Personal Information',
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
                                  label: 'Date of Birth',
                                  value: _formatDate(student.dateOfBirth),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _InfoSection(
                              title: 'Academic Information',
                              icon: Icons.school,
                              children: [
                                _InfoTile(
                                  label: 'Admission No.',
                                  value: student.admissionNo,
                                ),
                                _InfoTile(
                                  label: 'Roll Number',
                                  value: student.rollNumber,
                                ),
                                _InfoTile(
                                  label: 'Class',
                                  value: _className ?? 'Loading...',
                                ),
                                _InfoTile(
                                  label: 'Section',
                                  value: _sectionName ?? 'Loading...',
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _InfoSection(
                              title: 'Parent Information',
                              icon: Icons.family_restroom,
                              children: [
                                _InfoTile(
                                  label: 'Father Name',
                                  value: student.fatherName,
                                ),
                                _InfoTile(
                                  label: 'Father CNIC',
                                  value: student.fatherCnic,
                                ),
                                _InfoTile(
                                  label: 'Father Phone',
                                  value: student.fatherPhone,
                                ),
                                _InfoTile(
                                  label: 'Mother Name',
                                  value: student.motherName,
                                ),
                                _InfoTile(
                                  label: 'Mother CNIC',
                                  value: student.motherCnic,
                                ),
                                _InfoTile(
                                  label: 'Mother Phone',
                                  value: student.motherPhone,
                                ),
                                _InfoTile(
                                  label: 'Guardian Name',
                                  value: student.guardianName,
                                ),
                                _InfoTile(
                                  label: 'Guardian CNIC',
                                  value: student.guardianCnic,
                                ),
                                _InfoTile(
                                  label: 'Guardian Phone',
                                  value: student.guardianPhone,
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
                              title: 'Contact Information',
                              icon: Icons.contact_mail,
                              children: [
                                _InfoTile(
                                  label: 'Guardian Email',
                                  value: student.guardianEmail,
                                ),
                                _InfoTile(
                                  label: 'Address',
                                  value: student.address,
                                  multiline: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _InfoSection(
                              title: 'Medical Information',
                              icon: Icons.medical_information,
                              children: [
                                _InfoTile(
                                  label: 'Blood Group',
                                  value: student.bloodGroup,
                                ),
                                _InfoTile(
                                  label: 'Medical Allergies',
                                  value: student.medicalAllergies,
                                  multiline: true,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            _InfoSection(
                              title: 'System Information',
                              icon: Icons.info,
                              children: [
                                _InfoTile(
                                  label: 'Student ID',
                                  value: student.id,
                                ),
                                _InfoTile(
                                  label: 'Created Date',
                                  value: _formatDate(student.createdAt),
                                ),
                                _InfoTile(
                                  label: 'Updated Date',
                                  value: _formatDate(student.updatedAt),
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
                        title: 'Personal Information',
                        icon: Icons.person,
                        children: [
                          _InfoTile(
                            label: 'Full Name',
                            value: student.fullName,
                          ),
                          _InfoTile(label: 'Gender', value: student.gender),
                          _InfoTile(
                            label: 'Date of Birth',
                            value: _formatDate(student.dateOfBirth),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title: 'Academic Information',
                        icon: Icons.school,
                        children: [
                          _InfoTile(
                            label: 'Admission No.',
                            value: student.admissionNo,
                          ),
                          _InfoTile(
                            label: 'Roll Number',
                            value: student.rollNumber,
                          ),
                          _InfoTile(
                            label: 'Class',
                            value: _className ?? 'Loading...',
                          ),
                          _InfoTile(
                            label: 'Section',
                            value: _sectionName ?? 'Loading...',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title: 'Parent Information',
                        icon: Icons.family_restroom,
                        children: [
                          _InfoTile(
                            label: 'Father Name',
                            value: student.fatherName,
                          ),
                          _InfoTile(
                            label: 'Father CNIC',
                            value: student.fatherCnic,
                          ),
                          _InfoTile(
                            label: 'Father Phone',
                            value: student.fatherPhone,
                          ),
                          _InfoTile(
                            label: 'Mother Name',
                            value: student.motherName,
                          ),
                          _InfoTile(
                            label: 'Mother CNIC',
                            value: student.motherCnic,
                          ),
                          _InfoTile(
                            label: 'Mother Phone',
                            value: student.motherPhone,
                          ),
                          _InfoTile(
                            label: 'Guardian Name',
                            value: student.guardianName,
                          ),
                          _InfoTile(
                            label: 'Guardian CNIC',
                            value: student.guardianCnic,
                          ),
                          _InfoTile(
                            label: 'Guardian Phone',
                            value: student.guardianPhone,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title: 'Contact Information',
                        icon: Icons.contact_mail,
                        children: [
                          _InfoTile(
                            label: 'Guardian Email',
                            value: student.guardianEmail,
                          ),
                          _InfoTile(
                            label: 'Address',
                            value: student.address,
                            multiline: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title: 'Medical Information',
                        icon: Icons.medical_information,
                        children: [
                          _InfoTile(
                            label: 'Blood Group',
                            value: student.bloodGroup,
                          ),
                          _InfoTile(
                            label: 'Medical Allergies',
                            value: student.medicalAllergies,
                            multiline: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _InfoSection(
                        title: 'System Information',
                        icon: Icons.info,
                        children: [
                          _InfoTile(label: 'Student ID', value: student.id),
                          _InfoTile(
                            label: 'Created Date',
                            value: _formatDate(student.createdAt),
                          ),
                          _InfoTile(
                            label: 'Updated Date',
                            value: _formatDate(student.updatedAt),
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

  const _Header({required this.student, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 800;

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
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Student'),
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
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Student'),
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
      backgroundImage: student.profileImageUrl.isNotEmpty
          ? NetworkImage(student.profileImageUrl)
          : null,
      child: student.profileImageUrl.isEmpty
          ? const Icon(Icons.person, size: 55)
          : null,
    );
  }

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          student.fullName,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text('Admission No: ${student.admissionNo}'),
        const SizedBox(height: 4),
        Text(
          'Roll No: ${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
        ),
        const SizedBox(height: 14),
        _StatusChip(active: student.isActive),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        active ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: Colors.white,
      ),
      backgroundColor: active ? Colors.green : Colors.red,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
    final displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
