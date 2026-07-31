import 'package:equatable/equatable.dart';

enum ExamDateSheetCreationMode { manual, automatic }

enum ExamDateSheetStatus { draft, published, archived }

class ExamDateSheetPaperEntity extends Equatable {
  const ExamDateSheetPaperEntity({
    required this.id,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.examDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.totalMarks,
    required this.passingMarks,
    required this.instructions,
  });

  final String id;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;
  final DateTime examDate;
  final int startMinutes;
  final int endMinutes;
  final double totalMarks;
  final double passingMarks;
  final String instructions;

  String get classDayKey => '$classId|$sectionId|${_dateKey(examDate)}';

  String get teacherDayKey => '$teacherId|${_dateKey(examDate)}';

  String get subjectKey => '$classId|$sectionId|$subjectId';

  bool overlaps(ExamDateSheetPaperEntity other) {
    if (_dateKey(examDate) != _dateKey(other.examDate)) return false;
    return startMinutes < other.endMinutes && other.startMinutes < endMinutes;
  }

  static String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  @override
  List<Object> get props => [
    id,
    classId,
    className,
    sectionId,
    sectionName,
    subjectId,
    subjectName,
    teacherId,
    teacherName,
    examDate,
    startMinutes,
    endMinutes,
    totalMarks,
    passingMarks,
    instructions,
  ];
}

class ExamDateSheetEntity extends Equatable {
  ExamDateSheetEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.title,
    required this.creationMode,
    required this.status,
    required List<ExamDateSheetPaperEntity> papers,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
    this.generatorOptionLabel,
  }) : papers = List<ExamDateSheetPaperEntity>.unmodifiable(papers);

  final String id;
  final String examId;
  final String examName;
  final String academicSession;
  final String title;
  final ExamDateSheetCreationMode creationMode;
  final ExamDateSheetStatus status;
  final List<ExamDateSheetPaperEntity> papers;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final String? generatorOptionLabel;

  int get paperCount => papers.length;

  ExamDateSheetEntity copyWith({
    String? title,
    ExamDateSheetStatus? status,
    List<ExamDateSheetPaperEntity>? papers,
    DateTime? updatedAt,
    DateTime? publishedAt,
    String? generatorOptionLabel,
  }) {
    return ExamDateSheetEntity(
      id: id,
      examId: examId,
      examName: examName,
      academicSession: academicSession,
      title: title ?? this.title,
      creationMode: creationMode,
      status: status ?? this.status,
      papers: papers ?? this.papers,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      generatorOptionLabel: generatorOptionLabel ?? this.generatorOptionLabel,
    );
  }

  @override
  List<Object?> get props => [
    id,
    examId,
    examName,
    academicSession,
    title,
    creationMode,
    status,
    papers,
    createdAt,
    updatedAt,
    publishedAt,
    generatorOptionLabel,
  ];
}
