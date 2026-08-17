import '../entities/exam_date_sheet_entity.dart';
import '../entities/exam_date_sheet_validation_entity.dart';
import '../entities/exam_entity.dart';

class ValidateExamDateSheet {
  const ValidateExamDateSheet();

  ExamDateSheetValidationResult call({
    required ExamEntity exam,
    required List<ExamDateSheetPaperEntity> papers,
  }) {
    final issues = <ExamDateSheetValidationIssue>[];
    final start = _dateOnly(exam.startDate ?? exam.examDate);
    final end = _dateOnly(exam.endDate ?? exam.examDate);

    final classDays = <String, ExamDateSheetPaperEntity>{};
    final teacherDays = <String, ExamDateSheetPaperEntity>{};
    final subjects = <String, ExamDateSheetPaperEntity>{};

    for (final paper in papers) {
      final paperDate = _dateOnly(paper.examDate);

      if (paperDate.isBefore(start) || paperDate.isAfter(end)) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.dateOutsideRange,
            severity: ExamDateSheetIssueSeverity.error,
            title: 'Date outside exam range',
            message:
                '${paper.subjectName} for ${paper.className} - '
                '${paper.sectionName} is outside the configured exam dates.',
            suggestion:
                'Move the paper between ${_date(start)} and ${_date(end)}.',
            paperId: paper.id,
          ),
        );
      }

      if (paper.startMinutes >= paper.endMinutes) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.invalidTime,
            severity: ExamDateSheetIssueSeverity.error,
            title: 'Invalid paper time',
            message: '${paper.subjectName} has an invalid start/end time.',
            suggestion: 'Set the end time after the start time.',
            paperId: paper.id,
          ),
        );
      }

      if (paper.totalMarks <= 0 ||
          paper.passingMarks < 0 ||
          paper.passingMarks > paper.totalMarks) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.invalidMarks,
            severity: ExamDateSheetIssueSeverity.error,
            title: 'Invalid marks',
            message: '${paper.subjectName} has invalid total or passing marks.',
            suggestion:
                'Keep total marks above zero and passing marks within '
                'the total.',
            paperId: paper.id,
          ),
        );
      }

      final existingClass = classDays[paper.classDayKey];
      if (existingClass != null) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.classDailyLimit,
            severity: ExamDateSheetIssueSeverity.error,
            title: 'Class has two papers on one day',
            message:
                '${paper.className} - ${paper.sectionName} has '
                '${existingClass.subjectName} and ${paper.subjectName} '
                'on ${_date(paper.examDate)}.',
            suggestion: 'Move one paper to the next available exam date.',
            paperId: paper.id,
          ),
        );
      } else {
        classDays[paper.classDayKey] = paper;
      }

      if (paper.teacherId.trim().isNotEmpty) {
        final existingTeacher = teacherDays[paper.teacherDayKey];
        if (existingTeacher != null) {
          issues.add(
            ExamDateSheetValidationIssue(
              type: ExamDateSheetIssueType.teacherDailyLimit,
              severity: ExamDateSheetIssueSeverity.warning,
              title: 'Teacher has multiple papers on one day',
              message:
                  '${paper.teacherName} is assigned to '
                  '${existingTeacher.className} - '
                  '${existingTeacher.sectionName} and '
                  '${paper.className} - ${paper.sectionName} on '
                  '${_date(paper.examDate)}.',
              suggestion:
                  'Keep this only when no conflict-free date is available.',
              paperId: paper.id,
            ),
          );
        } else {
          teacherDays[paper.teacherDayKey] = paper;
        }
      }

      final existingSubject = subjects[paper.subjectKey];
      if (existingSubject != null) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.duplicateSubject,
            severity: ExamDateSheetIssueSeverity.error,
            title: 'Duplicate subject',
            message:
                '${paper.subjectName} is repeated for '
                '${paper.className} - ${paper.sectionName}.',
            suggestion: 'Remove the duplicate paper.',
            paperId: paper.id,
          ),
        );
      } else {
        subjects[paper.subjectKey] = paper;
      }

      if (paper.examDate.weekday == DateTime.sunday) {
        issues.add(
          ExamDateSheetValidationIssue(
            type: ExamDateSheetIssueType.weekendPaper,
            severity: ExamDateSheetIssueSeverity.warning,
            title: 'Sunday paper',
            message:
                '${paper.subjectName} for ${paper.className} - '
                '${paper.sectionName} is scheduled on Sunday.',
            suggestion:
                'Move it to a working day unless Sunday exams are intended.',
            paperId: paper.id,
          ),
        );
      }
    }

    _addDistributionWarnings(papers, issues);

    return ExamDateSheetValidationResult(
      issues: issues,
      totalPapers: papers.length,
    );
  }

  void _addDistributionWarnings(
    List<ExamDateSheetPaperEntity> papers,
    List<ExamDateSheetValidationIssue> issues,
  ) {
    final byClass = <String, List<ExamDateSheetPaperEntity>>{};

    for (final paper in papers) {
      final key = '${paper.classId}|${paper.sectionId}';
      byClass.putIfAbsent(key, () => []).add(paper);
    }

    for (final classPapers in byClass.values) {
      classPapers.sort(
        (first, second) => first.examDate.compareTo(second.examDate),
      );

      for (var index = 1; index < classPapers.length; index++) {
        final previous = classPapers[index - 1];
        final current = classPapers[index];
        final difference = _dateOnly(
          current.examDate,
        ).difference(_dateOnly(previous.examDate)).inDays;

        if (difference == 1 &&
            _isDifficult(previous.subjectName) &&
            _isDifficult(current.subjectName)) {
          issues.add(
            ExamDateSheetValidationIssue(
              type: ExamDateSheetIssueType.consecutiveDifficultPapers,
              severity: ExamDateSheetIssueSeverity.warning,
              title: 'Consecutive difficult papers',
              message:
                  '${previous.subjectName} and ${current.subjectName} are '
                  'scheduled on consecutive days for '
                  '${current.className} - ${current.sectionName}.',
              suggestion:
                  'Add at least one gap day between these subjects where '
                  'possible.',
              paperId: current.id,
            ),
          );
        }
      }
    }
  }

  bool _isDifficult(String subject) {
    final value = subject.toLowerCase();
    return value.contains('math') ||
        value.contains('science') ||
        value.contains('computer') ||
        value.contains('physics') ||
        value.contains('chemistry') ||
        value.contains('biology');
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
