import '../../domain/entities/teacher_assignment_entity.dart';

class TeacherAssignmentModel extends TeacherAssignmentEntity {
  const TeacherAssignmentModel({
    required super.id,
    required super.teacherId,
    required super.teacherName,
    required super.classId,
    required super.sectionId,
    required super.subject,
    required super.academicSession,
    required super.isClassTeacher,
    required super.createdAt,
  });

  factory TeacherAssignmentModel.fromMap(Map<String, dynamic> map) {
    return TeacherAssignmentModel(
      id: map['id'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      teacherName: map['teacherName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      isClassTeacher: map['isClassTeacher'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory TeacherAssignmentModel.fromEntity(TeacherAssignmentEntity value) {
    return TeacherAssignmentModel(
      id: value.id,
      teacherId: value.teacherId,
      teacherName: value.teacherName,
      classId: value.classId,
      sectionId: value.sectionId,
      subject: value.subject,
      academicSession: value.academicSession,
      isClassTeacher: value.isClassTeacher,
      createdAt: value.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'teacherId': teacherId,
        'teacherName': teacherName,
        'classId': classId,
        'sectionId': sectionId,
        'subject': subject,
        'academicSession': academicSession,
        'assignmentKey': assignmentKey,
        'classTeacherKey': classTeacherKey,
        'isClassTeacher': isClassTeacher,
        'createdAt': createdAt.toIso8601String(),
      };
}
