import 'package:equatable/equatable.dart';

import '../../../students/domain/entities/student_entity.dart';

class ParentStudentLinkEntity extends Equatable {
  const ParentStudentLinkEntity({
    required this.parentId,
    required this.student,
    required this.relationship,
    required this.isPrimaryContact,
  });

  final String parentId;
  final StudentEntity student;
  final String relationship;
  final bool isPrimaryContact;

  @override
  List<Object> get props => [
    parentId,
    student.id,
    relationship,
    isPrimaryContact,
  ];
}
