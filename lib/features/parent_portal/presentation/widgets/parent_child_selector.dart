import 'package:flutter/material.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/services/parent_context_service.dart';

class ParentChildSelector extends StatelessWidget {
  const ParentChildSelector({super.key, required this.parentContext});

  final ParentContextService parentContext;

  @override
  Widget build(BuildContext context) {
    final students = parentContext.linkedStudents;
    final selected = parentContext.currentStudent;

    if (students.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text('No active student is linked to this parent account.'),
        ),
      );
    }

    if (students.length == 1) {
      return _SelectedChildCard(student: students.first);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DropdownButtonFormField<String>(
          initialValue: selected?.id ?? students.first.id,
          decoration: const InputDecoration(
            labelText: 'Current Child',
            prefixIcon: Icon(Icons.child_care_outlined),
            border: OutlineInputBorder(),
          ),
          items: students
              .map(
                (student) => DropdownMenuItem<String>(
                  value: student.id,
                  child: Text('${student.fullName} (${student.admissionNo})'),
                ),
              )
              .toList(growable: false),
          onChanged: (studentId) {
            if (studentId != null) {
              parentContext.selectStudent(studentId);
            }
          },
        ),
      ),
    );
  }
}

class _SelectedChildCard extends StatelessWidget {
  const _SelectedChildCard({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: student.profileImageUrl.isEmpty
              ? null
              : NetworkImage(student.profileImageUrl),
          child: student.profileImageUrl.isEmpty
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${student.admissionNo} | '
          '${student.classId}-${student.sectionId}',
        ),
        trailing: const Chip(label: Text('CURRENT CHILD')),
      ),
    );
  }
}
