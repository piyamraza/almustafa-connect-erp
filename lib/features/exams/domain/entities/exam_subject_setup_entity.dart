import 'package:equatable/equatable.dart';

class ExamSubjectSetupEntity extends Equatable {
  const ExamSubjectSetupEntity({required this.id, required this.examId, required this.examName, required this.academicSession, required this.classId, required this.className, required this.sectionId, required this.sectionName, required this.subjectId, required this.subjectName, required this.totalMarks, required this.passingMarks, required this.isActive, required this.createdAt, required this.updatedAt});
  final String id, examId, examName, academicSession, classId, className, sectionId, sectionName, subjectId, subjectName;
  final double totalMarks, passingMarks;
  final bool isActive;
  final DateTime createdAt, updatedAt;
  String get uniqueKey => '${examId}_${classId}_${sectionId}_${subjectId}';
  ExamSubjectSetupEntity copyWith({String? id, String? examId, String? examName, String? academicSession, String? classId, String? className, String? sectionId, String? sectionName, String? subjectId, String? subjectName, double? totalMarks, double? passingMarks, bool? isActive, DateTime? createdAt, DateTime? updatedAt}) => ExamSubjectSetupEntity(id: id ?? this.id, examId: examId ?? this.examId, examName: examName ?? this.examName, academicSession: academicSession ?? this.academicSession, classId: classId ?? this.classId, className: className ?? this.className, sectionId: sectionId ?? this.sectionId, sectionName: sectionName ?? this.sectionName, subjectId: subjectId ?? this.subjectId, subjectName: subjectName ?? this.subjectName, totalMarks: totalMarks ?? this.totalMarks, passingMarks: passingMarks ?? this.passingMarks, isActive: isActive ?? this.isActive, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt);
  @override List<Object?> get props => [id, examId, examName, academicSession, classId, className, sectionId, sectionName, subjectId, subjectName, totalMarks, passingMarks, isActive, createdAt, updatedAt];
}
