import 'package:equatable/equatable.dart';

class SyllabusEntryEntity extends Equatable {
  const SyllabusEntryEntity({
    required this.id,
    required this.academicSession,
    required this.syllabusTitle,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String academicSession;
  final String syllabusTitle;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object> get props => [
    id,
    academicSession,
    syllabusTitle,
    classId,
    sectionId,
    subjectId,
    content,
    updatedAt,
  ];
}
