import 'package:equatable/equatable.dart';

/// Subject configuration for one examination, class and section.
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
    this.componentTotalMarks = const {},
    this.componentPassingMarks = const {},
  });

  final String id;
  final String examId;
  final String examName;
  final String academicSession;
  final String academicYearId;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String subjectId;
  final String subjectName;
  final double totalMarks;
  final double passingMarks;
  final double theoryMarks;
  final double practicalMarks;
  final double internalAssessmentMarks;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Component ID -> maximum marks.
  ///
  /// Empty maps represent legacy setups and allow equal-distribution fallback.
  final Map<String, double> componentTotalMarks;

  /// Component ID -> passing marks.
  final Map<String, double> componentPassingMarks;

  String get uniqueKey => '${examId}_${classId}_${sectionId}_$subjectId';

  double get configuredBreakdownMarks =>
      theoryMarks + practicalMarks + internalAssessmentMarks;

  bool get hasMarksBreakdown => configuredBreakdownMarks > 0;

  bool get isMarksBreakdownValid =>
      !hasMarksBreakdown || configuredBreakdownMarks == totalMarks;

  bool get isPassingMarksValid =>
      passingMarks >= 0 && passingMarks <= totalMarks;

  bool get hasComponentDistribution => componentTotalMarks.isNotEmpty;

  double get configuredComponentTotal =>
      componentTotalMarks.values.fold(0, (sum, value) => sum + value);

  double get configuredComponentPassing =>
      componentPassingMarks.values.fold(0, (sum, value) => sum + value);

  bool get isComponentDistributionValid {
    if (!hasComponentDistribution) return true;
    return _same(configuredComponentTotal, totalMarks) &&
        componentTotalMarks.keys.every((id) {
          final total = componentTotalMarks[id] ?? 0;
          final passing = componentPassingMarks[id] ?? 0;
          return total > 0 && passing >= 0 && passing <= total;
        });
  }

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
    Map<String, double>? componentTotalMarks,
    Map<String, double>? componentPassingMarks,
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
      componentTotalMarks: componentTotalMarks ?? this.componentTotalMarks,
      componentPassingMarks:
          componentPassingMarks ?? this.componentPassingMarks,
    );
  }

  static bool _same(double first, double second) =>
      (first - second).abs() < 0.001;

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
    componentTotalMarks,
    componentPassingMarks,
  ];
}
