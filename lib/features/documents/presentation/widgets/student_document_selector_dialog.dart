import 'package:flutter/material.dart';

import '../../../students/domain/entities/student_entity.dart';

class StudentDocumentSelectorDialog extends StatefulWidget {
  const StudentDocumentSelectorDialog({
    super.key,
    required this.students,
    required this.title,
    required this.onSelected,
  });

  final List<StudentEntity> students;
  final String title;
  final ValueChanged<StudentEntity> onSelected;

  @override
  State<StudentDocumentSelectorDialog> createState() =>
      _StudentDocumentSelectorDialogState();
}

class _StudentDocumentSelectorDialogState
    extends State<StudentDocumentSelectorDialog> {
  final TextEditingController _searchController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filteredStudents();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 720,
          maxHeight: 650,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () =>
                        Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select a student to continue.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Search by name, admission no or father name',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: _clearSearch,
                          icon: const Icon(
                            Icons.close,
                          ),
                        ),
                  border:
                      const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: widget.students.isEmpty
                    ? const _EmptyState(
                        icon:
                            Icons.people_outline,
                        message:
                            'No students available.',
                      )
                    : filteredStudents.isEmpty
                        ? const _EmptyState(
                            icon:
                                Icons.search_off,
                            message:
                                'No matching student found.',
                          )
                        : ListView.separated(
                            itemCount:
                                filteredStudents
                                    .length,
                            separatorBuilder:
                                (_, _) =>
                                    const Divider(
                              height: 1,
                            ),
                            itemBuilder: (
                              context,
                              index,
                            ) {
                              final student =
                                  filteredStudents[
                                      index];

                              return ListTile(
                                contentPadding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                leading:
                                    CircleAvatar(
                                  backgroundImage:
                                      student
                                              .profileImageUrl
                                              .isNotEmpty
                                          ? NetworkImage(
                                              student
                                                  .profileImageUrl,
                                            )
                                          : null,
                                  child: student
                                          .profileImageUrl
                                          .isEmpty
                                      ? const Icon(
                                          Icons
                                              .person,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  student.fullName,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Text(
                                      'Admission No: ${student.admissionNo}',
                                    ),
                                    if (student
                                        .fatherName
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        'Father: ${student.fatherName}',
                                      ),
                                  ],
                                ),
                                trailing:
                                    const Icon(
                                  Icons
                                      .arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pop();

                                  widget.onSelected(
                                    student,
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<StudentEntity> _filteredStudents() {
    final query =
        _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.students;
    }

    return widget.students.where(
      (student) {
        final fullName =
            student.fullName.toLowerCase();

        final admissionNo =
            student.admissionNo.toLowerCase();

        final fatherName =
            student.fatherName.toLowerCase();

        return fullName.contains(query) ||
            admissionNo.contains(query) ||
            fatherName.contains(query);
      },
    ).toList();
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _query = '';
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 44,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}