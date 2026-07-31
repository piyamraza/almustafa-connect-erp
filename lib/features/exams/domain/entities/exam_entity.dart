import 'package:equatable/equatable.dart';

enum ExamType {
  monthly,
  quarterly,
  midTerm,
  finalExam,
}

/// Immutable examination configuration shared by exam setup, marks entry and
/// result generation.
class ExamEntity extends Equatable {
  const ExamEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
    required this.subject,
    required this.examDate,
    required this.totalMarks,
    required this.passingMarks,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.resultDate,
    this.description = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final ExamType type;
  final String academicSession;
  final String classId;
  final String sectionId;
  final String subject;
  final DateTime examDate;
  final double totalMarks;
  final double passingMarks;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? resultDate;
  final String description;
  final bool isActive;

  ExamEntity copyWith({
    String? id,
    String? name,
    ExamType? type,
    String? academicSession,
    String? classId,
    String? sectionId,
    String? subject,
    DateTime? examDate,
    double? totalMarks,
    double? passingMarks,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? resultDate,
    String? description,
    bool? isActive,
  }) {
    return ExamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      academicSession: academicSession ?? this.academicSession,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      resultDate: resultDate ?? this.resultDate,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        academicSession,
        classId,
        sectionId,
        subject,
        examDate,
        totalMarks,
        passingMarks,
        createdAt,
        startDate,
        endDate,
        resultDate,
        description,
        isActive,
      ];
}
