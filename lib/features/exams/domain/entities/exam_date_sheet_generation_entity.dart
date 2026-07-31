import 'package:equatable/equatable.dart';

import 'exam_date_sheet_entity.dart';
import 'exam_date_sheet_validation_entity.dart';

enum ExamDateSheetGenerationStrategy { balanced, maximumGap, compact }

class ExamDateSheetGenerationRequest extends Equatable {
  ExamDateSheetGenerationRequest({
    required this.examId,
    required this.examName,
    required this.academicSession,
    required this.startDate,
    required this.endDate,
    required List<int> allowedWeekdays,
    required List<DateTime> holidays,
    required this.startMinutes,
    required this.paperDurationMinutes,
    required this.includeAllActiveClasses,
  }) : allowedWeekdays = List<int>.unmodifiable(allowedWeekdays),
       holidays = List<DateTime>.unmodifiable(holidays);

  final String examId;
  final String examName;
  final String academicSession;
  final DateTime startDate;
  final DateTime endDate;
  final List<int> allowedWeekdays;
  final List<DateTime> holidays;
  final int startMinutes;
  final int paperDurationMinutes;
  final bool includeAllActiveClasses;

  @override
  List<Object> get props => [
    examId,
    examName,
    academicSession,
    startDate,
    endDate,
    allowedWeekdays,
    holidays,
    startMinutes,
    paperDurationMinutes,
    includeAllActiveClasses,
  ];
}

class ExamDateSheetGeneratedOption extends Equatable {
  ExamDateSheetGeneratedOption({
    required this.label,
    required this.strategy,
    required List<ExamDateSheetPaperEntity> papers,
    required this.validation,
    required this.startDate,
    required this.endDate,
  }) : papers = List<ExamDateSheetPaperEntity>.unmodifiable(papers);

  final String label;
  final ExamDateSheetGenerationStrategy strategy;
  final List<ExamDateSheetPaperEntity> papers;
  final ExamDateSheetValidationResult validation;
  final DateTime startDate;
  final DateTime endDate;

  int get score => validation.score;
  bool get isValid => validation.isValid;

  double get averageGapDays {
    final byClass = <String, List<ExamDateSheetPaperEntity>>{};
    for (final paper in papers) {
      final key = '${paper.classId}|${paper.sectionId}';
      byClass.putIfAbsent(key, () => []).add(paper);
    }

    var totalGap = 0;
    var gapCount = 0;

    for (final values in byClass.values) {
      values.sort((a, b) => a.examDate.compareTo(b.examDate));
      for (var index = 1; index < values.length; index++) {
        totalGap += values[index].examDate
            .difference(values[index - 1].examDate)
            .inDays;
        gapCount++;
      }
    }

    return gapCount == 0 ? 0 : totalGap / gapCount;
  }

  @override
  List<Object> get props => [
    label,
    strategy,
    papers,
    validation,
    startDate,
    endDate,
  ];
}
