import 'package:equatable/equatable.dart';

enum ExamDateSheetIssueSeverity { warning, error }

enum ExamDateSheetIssueType {
  classDailyLimit,
  teacherDailyLimit,
  duplicateSubject,
  dateOutsideRange,
  invalidTime,
  invalidMarks,
  weekendPaper,
  consecutiveDifficultPapers,
}

class ExamDateSheetValidationIssue extends Equatable {
  const ExamDateSheetValidationIssue({
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.suggestion,
    this.paperId,
  });

  final ExamDateSheetIssueType type;
  final ExamDateSheetIssueSeverity severity;
  final String title;
  final String message;
  final String suggestion;
  final String? paperId;

  @override
  List<Object?> get props => [
    type,
    severity,
    title,
    message,
    suggestion,
    paperId,
  ];
}

class ExamDateSheetValidationResult extends Equatable {
  ExamDateSheetValidationResult({
    required List<ExamDateSheetValidationIssue> issues,
    required this.totalPapers,
  }) : issues = List<ExamDateSheetValidationIssue>.unmodifiable(issues);

  final List<ExamDateSheetValidationIssue> issues;
  final int totalPapers;

  List<ExamDateSheetValidationIssue> get errors => issues
      .where((issue) => issue.severity == ExamDateSheetIssueSeverity.error)
      .toList(growable: false);

  List<ExamDateSheetValidationIssue> get warnings => issues
      .where((issue) => issue.severity == ExamDateSheetIssueSeverity.warning)
      .toList(growable: false);

  bool get isValid => errors.isEmpty;

  int get validPaperCount {
    final affected = errors
        .map((issue) => issue.paperId)
        .whereType<String>()
        .toSet()
        .length;
    final value = totalPapers - affected;
    return value < 0 ? 0 : value;
  }

  int get score {
    final deduction = (errors.length * 20) + (warnings.length * 5);
    final value = 100 - deduction;
    return value < 0 ? 0 : value;
  }

  String get rating {
    if (!isValid) return 'Blocked';
    if (score >= 95) return 'Recommended';
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Needs Review';
    return 'Poor';
  }

  @override
  List<Object> get props => [issues, totalPapers];
}
