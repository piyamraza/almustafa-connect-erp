import 'package:equatable/equatable.dart';

/// Subject configuration for one examination, class and section.
///
/// Examination identity and overall dates belong to [ExamEntity].
/// Individual paper dates belong to the examination date-sheet records.
class ExamSubjectSetupEntity extends Equatable {
  const ExamSubjectSetupEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.subjectId,
    required this.subjectName,
    required this.totalMarks,
    required this.passingMarks,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearId = '',
    this.theoryMarks = 0,
    this.practicalMarks = 0,
    this.internalAssessmentMarks = 0,
    this.displayOrder = 0,
  });

  final String id;

  final String examId;
  final String examName;

  /// Human-readable academic-session snapshot.
  ///
  /// Example: 2026-2027
  final String academicSession;

  /// Stable academic-year reference.
  ///
  /// It may remain empty for older migrated records.
  final String academicYearId;

  final String classId;
  final String className;

  final String sectionId;
  final String sectionName;

  final String subjectId;
  final String subjectName;

  /// Maximum marks used for result calculation.
  final double totalMarks;

  /// Minimum marks required to pass the subject.
  final double passingMarks;

  /// Reserved breakdown fields.
  ///
  /// These remain zero until theory, practical or internal-assessment
  /// workflows are enabled.
  final double theoryMarks;
  final double practicalMarks;
  final double internalAssessmentMarks;

  /// Controls subject order in date sheets, marks entry and report cards.
  final int displayOrder;

  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get uniqueKey =>
      '${examId}_${classId}_${sectionId}_$subjectId';

  double get configuredBreakdownMarks =>
      theoryMarks + practicalMarks + internalAssessmentMarks;

  bool get hasMarksBreakdown => configuredBreakdownMarks > 0;

  bool get isMarksBreakdownValid =>
      !hasMarksBreakdown || configuredBreakdownMarks == totalMarks;

  bool get isPassingMarksValid =>
      passingMarks >= 0 && passingMarks <= totalMarks;

  ExamSubjectSetupEntity copyWith({
    String? id,
    String? examId,
    String? examName,
    String? academicSession,
    String? academicYearId,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? subjectId,
    String? subjectName,
    double? totalMarks,
    double? passingMarks,
    double? theoryMarks,
    double? practicalMarks,
    double? internalAssessmentMarks,
    int? displayOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamSubjectSetupEntity(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      examName: examName ?? this.examName,
      academicSession: academicSession ?? this.academicSession,
      academicYearId: academicYearId ?? this.academicYearId,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      totalMarks: totalMarks ?? this.totalMarks,
      passingMarks: passingMarks ?? this.passingMarks,
      theoryMarks: theoryMarks ?? this.theoryMarks,
      practicalMarks: practicalMarks ?? this.practicalMarks,
      internalAssessmentMarks:
          internalAssessmentMarks ?? this.internalAssessmentMarks,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        examId,
        examName,
        academicSession,
        academicYearId,
        classId,
        className,
        sectionId,
        sectionName,
        subjectId,
        subjectName,
        totalMarks,
        passingMarks,
        theoryMarks,
        practicalMarks,
        internalAssessmentMarks,
        displayOrder,
        isActive,
        createdAt,
        updatedAt,
      ];
}