import 'package:equatable/equatable.dart';

enum ExamType { monthly, quarterly, midTerm, finalExam }

enum ExamWorkflowStatus { draft, active, completed, archived }

/// Master examination configuration.
///
/// Class, section, subject, individual paper date and marks criteria belong to
/// exam subject setup and date-sheet records. Legacy fields remain temporarily
/// for backward-compatible reads during the staged migration.
class ExamEntity extends Equatable {
  const ExamEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.academicSession,
    required this.createdAt,
    this.academicYearId = '',
    this.startDate,
    this.endDate,
    this.resultDate,
    this.description = '',
    ExamWorkflowStatus? status,
    bool? isActive,
    this.createdBy = '',
    this.updatedAt,
    this.classId = '',
    this.sectionId = '',
    this.subject = '',
    DateTime? examDate,
    this.totalMarks = 0,
    this.passingMarks = 0,
  }) : status =
           status ??
           ((isActive ?? true)
               ? ExamWorkflowStatus.active
               : ExamWorkflowStatus.draft),
       examDate = examDate ?? startDate ?? createdAt;

  final String id;
  final String name;
  final ExamType type;

  /// Human-readable session snapshot, for example 2026-2027.
  final String academicSession;

  /// Stable academic-year reference. It may remain empty for migrated records.
  final String academicYearId;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? resultDate;
  final String description;
  final ExamWorkflowStatus status;
  final String createdBy;

  /// Legacy compatibility fields.
  ///
  /// New writes must keep these empty. Their data belongs to subject setup or
  /// the date sheet and is retained only so older records remain readable.
  final String classId;
  final String sectionId;
  final String subject;
  final DateTime examDate;
  final double totalMarks;
  final double passingMarks;

  bool get isActive => status == ExamWorkflowStatus.active;

  bool get isEditable =>
      status == ExamWorkflowStatus.draft || status == ExamWorkflowStatus.active;

  ExamEntity copyWith({
    String? id,
    String? name,
    ExamType? type,
    String? academicSession,
    String? academicYearId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? resultDate,
    String? description,
    ExamWorkflowStatus? status,
    bool? isActive,
    String? createdBy,
    String? classId,
    String? sectionId,
    String? subject,
    DateTime? examDate,
    double? totalMarks,
    double? passingMarks,
  }) {
    final resolvedStatus =
        status ??
        (isActive == null
            ? this.status
            : isActive
            ? ExamWorkflowStatus.active
            : ExamWorkflowStatus.draft);

    return ExamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      academicSession: academicSession ?? this.academicSession,
      academicYearId: academicYearId ?? this.academicYearId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      resultDate: resultDate ?? this.resultDate,
      description: description ?? this.description,
      status: resolvedStatus,
      createdBy: createdBy ?? this.createdBy,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subject: subject ?? this.subject,
      examDate: examDate ?? this.examDate,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    academicSession,
    academicYearId,
    createdAt,
    updatedAt,
    startDate,
    endDate,
    resultDate,
    description,
    status,
    createdBy,
    classId,
    sectionId,
    subject,
    examDate,
    totalMarks,
    passingMarks,
  ];
}
