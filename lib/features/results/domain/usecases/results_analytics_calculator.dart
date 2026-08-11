import 'dart:math' as math;

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/entities/exam_subject_setup_entity.dart';
import '../../../exams/domain/services/result_subject_grouping_service.dart';
import '../entities/result_analytics_entity.dart';

/// Pure, read-only aggregations over finalized published result records.
class ResultsAnalyticsCalculator {
  const ResultsAnalyticsCalculator._();

  static List<ExamResultEntity> filteredResults(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    return data.results
        .where((result) {
          return (filter.academicSession == null ||
                  result.academicSession == filter.academicSession) &&
              (filter.examId == null || result.examId == filter.examId) &&
              (filter.classId == null || result.classId == filter.classId) &&
              (filter.sectionId == null ||
                  result.sectionId == filter.sectionId) &&
              (filter.studentId == null ||
                  result.studentId == filter.studentId);
        })
        .toList(growable: false);
  }

  static List<SubjectStudentAnalysisRow> subjectRows(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final rows = <SubjectStudentAnalysisRow>[];
    for (final result in filteredResults(data, filter)) {
      for (final group in ResultSubjectGroupingService.group(
        result.subjectResults,
      )) {
        final subject = group.combined;
        if (filter.subjectName != null &&
            !_sameText(subject.subjectName, filter.subjectName!)) {
          continue;
        }
        rows.add(
          SubjectStudentAnalysisRow(
            result: result,
            subject: subject,
            passingMarks: _passingMarks(data.subjectSetups, result, subject),
          ),
        );
      }
    }
    final query = filter.searchQuery.trim().toLowerCase();
    final searched = query.isEmpty
        ? rows
        : rows
              .where(
                (row) => [
                  row.result.studentName,
                  row.result.rollNumber,
                  row.result.admissionNo,
                  row.subject.subjectName,
                ].join(' ').toLowerCase().contains(query),
              )
              .toList(growable: false);
    final sorted = [...searched]
      ..sort((first, second) {
        switch (filter.sort) {
          case AnalyticsSort.marksAscending:
            return first.subject.obtainedMarks.compareTo(
              second.subject.obtainedMarks,
            );
          case AnalyticsSort.nameAscending:
            return first.result.studentName.compareTo(
              second.result.studentName,
            );
          case AnalyticsSort.passFirst:
            final passOrder = (second.subject.isPassed ? 1 : 0).compareTo(
              first.subject.isPassed ? 1 : 0,
            );
            return passOrder != 0
                ? passOrder
                : second.subject.obtainedMarks.compareTo(
                    first.subject.obtainedMarks,
                  );
          case AnalyticsSort.marksDescending:
            return second.subject.obtainedMarks.compareTo(
              first.subject.obtainedMarks,
            );
        }
      });
    return sorted;
  }

  static SubjectAnalyticsSummary subjectSummary(
    List<SubjectStudentAnalysisRow> rows,
  ) {
    final appeared = rows
        .where((row) => !row.subject.isAbsent)
        .toList(growable: false);
    final passed = rows.where((row) => row.subject.isPassed).length;
    final marks = appeared
        .map((row) => row.subject.obtainedMarks)
        .toList(growable: false);
    final totalMarks = rows.isEmpty ? 0.0 : rows.first.subject.totalMarks;
    final passingMarks = rows
        .map((row) => row.passingMarks)
        .whereType<double>()
        .firstOrNull;
    return SubjectAnalyticsSummary(
      totalStudents: rows.length,
      appearedStudents: appeared.length,
      absentStudents: rows.length - appeared.length,
      passedStudents: passed,
      failedStudents: rows.length - passed,
      passPercentage: rows.isEmpty ? 0 : (passed / rows.length) * 100,
      failPercentage: rows.isEmpty
          ? 0
          : ((rows.length - passed) / rows.length) * 100,
      highestMarks: _max(marks),
      lowestMarks: _min(marks),
      averageMarks: _average(marks),
      totalMarks: totalMarks,
      passingMarks: passingMarks,
    );
  }

  static StudentPerformanceSummary? studentPerformance(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    if (filter.studentId == null) return null;
    final results = filteredResults(data, filter)
        .where((result) => result.studentId == filter.studentId)
        .toList(growable: false);
    if (results.isEmpty) return null;
    final ordered = [...results]
      ..sort((first, second) {
        final firstDate = first.publishedAt ?? first.updatedAt;
        final secondDate = second.publishedAt ?? second.updatedAt;
        return firstDate.compareTo(secondDate);
      });
    final subjectTotals = <String, List<double>>{};
    for (final result in ordered) {
      for (final group in ResultSubjectGroupingService.group(
        result.subjectResults,
      )) {
        final subject = group.combined;
        if (subject.isAbsent || subject.totalMarks == 0) continue;
        subjectTotals
            .putIfAbsent(subject.subjectName, () => <double>[])
            .add((subject.obtainedMarks / subject.totalMarks) * 100);
      }
    }
    final subjectPerformances =
        subjectTotals.entries
            .map(
              (entry) => SubjectPerformanceSummary(
                subjectName: entry.key,
                averagePercentage: _average(entry.value),
                examCount: entry.value.length,
              ),
            )
            .toList()
          ..sort(
            (first, second) =>
                second.averagePercentage.compareTo(first.averagePercentage),
          );
    final first = ordered.first;
    return StudentPerformanceSummary(
      studentName: first.studentName,
      rollNumber: first.rollNumber,
      admissionNo: first.admissionNo,
      examPerformances: ordered
          .map(
            (result) => StudentExamPerformance(
              examId: result.examId,
              examName: result.examName,
              percentage: result.percentage,
              grade: result.grade,
              position: result.overallRank,
              isPassed: result.isPassed,
            ),
          )
          .toList(growable: false),
      subjectPerformances: subjectPerformances,
      averagePercentage: _average(ordered.map((item) => item.percentage)),
      passedExams: ordered.where((item) => item.isPassed).length,
      failedExams: ordered.where((item) => !item.isPassed).length,
    );
  }

  static List<PerformanceGroupSummary> classSummaries(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, List<ExamResultEntity>>{};
    for (final result in filteredResults(data, filter)) {
      groups
          .putIfAbsent(result.classId, () => <ExamResultEntity>[])
          .add(result);
    }
    return _groupSummaries(groups, (result) => result.className);
  }

  static List<PerformanceGroupSummary> sectionSummaries(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, List<ExamResultEntity>>{};
    for (final result in filteredResults(data, filter)) {
      groups
          .putIfAbsent(result.sectionId, () => <ExamResultEntity>[])
          .add(result);
    }
    return _groupSummaries(groups, (result) => result.sectionName);
  }

  static List<SubjectPerformanceSummary> subjectPerformances(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, List<double>>{};
    for (final row in subjectRows(data, filter.copyWith(clearSubject: true))) {
      if (row.subject.isAbsent || row.subject.totalMarks == 0) continue;
      groups
          .putIfAbsent(row.subject.subjectName, () => <double>[])
          .add(row.percentage);
    }
    final values =
        groups.entries
            .map(
              (entry) => SubjectPerformanceSummary(
                subjectName: entry.key,
                averagePercentage: _average(entry.value),
                examCount: entry.value.length,
              ),
            )
            .toList()
          ..sort(
            (first, second) =>
                second.averagePercentage.compareTo(first.averagePercentage),
          );
    return values;
  }

  static List<ResultChartPoint> subjectPassPercentages(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, List<SubjectStudentAnalysisRow>>{};
    for (final row in subjectRows(data, filter.copyWith(clearSubject: true))) {
      groups
          .putIfAbsent(
            row.subject.subjectName,
            () => <SubjectStudentAnalysisRow>[],
          )
          .add(row);
    }
    final values =
        groups.entries
            .map(
              (entry) => ResultChartPoint(
                label: entry.key,
                value: entry.value.isEmpty
                    ? 0
                    : (entry.value.where((row) => row.subject.isPassed).length /
                              entry.value.length) *
                          100,
              ),
            )
            .toList()
          ..sort((first, second) => first.label.compareTo(second.label));
    return values;
  }

  static ResultAnalyticsOverview overview(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final results = filteredResults(data, filter);
    final classes = classSummaries(data, filter);
    final subjects = subjectPerformances(data, filter);
    final sortedClasses = [...classes]
      ..sort(
        (first, second) =>
            second.averagePercentage.compareTo(first.averagePercentage),
      );
    final passed = results.where((result) => result.isPassed).length;
    return ResultAnalyticsOverview(
      totalPublishedResults: results.length,
      totalStudentsEvaluated: results
          .map((result) => result.studentId)
          .toSet()
          .length,
      passedResults: passed,
      failedResults: results.length - passed,
      passPercentage: results.isEmpty ? 0 : (passed / results.length) * 100,
      failPercentage: results.isEmpty
          ? 0
          : ((results.length - passed) / results.length) * 100,
      averagePercentage: _average(results.map((result) => result.percentage)),
      highestPercentage: _max(results.map((result) => result.percentage)),
      lowestPercentage: _min(results.map((result) => result.percentage)),
      bestClass: sortedClasses.isEmpty ? null : sortedClasses.first,
      weakestClass: sortedClasses.isEmpty ? null : sortedClasses.last,
      bestSubject: subjects.isEmpty ? null : subjects.first,
      weakestSubject: subjects.isEmpty ? null : subjects.last,
    );
  }

  static List<StudentRiskSummary> studentRiskSummaries(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    return filteredResults(data, filter)
        .map((result) {
          final subjects = filter.subjectName == null
              ? result.subjectResults
              : result.subjectResults
                    .where(
                      (subject) =>
                          _sameText(subject.subjectName, filter.subjectName!),
                    )
                    .toList(growable: false);
          return StudentRiskSummary(
            result: result,
            failedSubjects: subjects
                .where((subject) => !subject.isPassed)
                .length,
            absentSubjects: subjects
                .where((subject) => subject.isAbsent)
                .length,
          );
        })
        .toList(growable: false);
  }

  static List<SubjectStudentAnalysisRow> borderlineRows(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    return subjectRows(data, filter)
        .where((row) {
          final passing = row.passingMarks;
          if (passing == null || row.subject.isAbsent || row.subject.isPassed) {
            return false;
          }
          return row.subject.obtainedMarks >=
                  passing - filter.borderlineMargin &&
              row.subject.obtainedMarks < passing;
        })
        .toList(growable: false);
  }

  static List<ExamResultEntity> topResults(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter, {
    int limit = 10,
    bool weakest = false,
  }) {
    final values = [...filteredResults(data, filter)]
      ..sort(
        (first, second) => weakest
            ? first.percentage.compareTo(second.percentage)
            : second.percentage.compareTo(first.percentage),
      );
    return values.take(limit).toList(growable: false);
  }

  static List<ResultChartPoint> gradeDistribution(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, int>{};
    for (final result in filteredResults(data, filter)) {
      groups[result.grade.trim().isEmpty ? 'N/A' : result.grade] =
          (groups[result.grade.trim().isEmpty ? 'N/A' : result.grade] ?? 0) + 1;
    }
    final points =
        groups.entries
            .map(
              (entry) => ResultChartPoint(
                label: entry.key,
                value: entry.value.toDouble(),
              ),
            )
            .toList()
          ..sort((first, second) => first.label.compareTo(second.label));
    return points;
  }

  static List<ResultChartPoint> examTrend(
    ResultAnalyticsData data,
    ResultAnalyticsFilter filter,
  ) {
    final groups = <String, List<ExamResultEntity>>{};
    for (final result in filteredResults(
      data,
      filter.copyWith(clearExam: true),
    )) {
      groups.putIfAbsent(result.examId, () => <ExamResultEntity>[]).add(result);
    }
    final values =
        groups.values
            .map(
              (items) => ResultChartPoint(
                label: items.first.examName,
                value: _average(items.map((item) => item.percentage)),
              ),
            )
            .toList()
          ..sort((first, second) => first.label.compareTo(second.label));
    return values;
  }

  static List<ResultChartPoint> studentTrend(
    StudentPerformanceSummary summary,
  ) => summary.examPerformances
      .map(
        (item) =>
            ResultChartPoint(label: item.examName, value: item.percentage),
      )
      .toList(growable: false);

  static List<PerformanceGroupSummary> _groupSummaries(
    Map<String, List<ExamResultEntity>> groups,
    String Function(ExamResultEntity) nameOf,
  ) {
    final values = groups.entries.map((entry) {
      final results = entry.value;
      final passed = results.where((result) => result.isPassed).length;
      final ordered = [
        ...results,
      ]..sort((first, second) => second.percentage.compareTo(first.percentage));
      return PerformanceGroupSummary(
        id: entry.key,
        name: nameOf(results.first),
        totalStudents: results.map((result) => result.studentId).toSet().length,
        passedStudents: passed,
        failedStudents: results.length - passed,
        passPercentage: results.isEmpty ? 0 : (passed / results.length) * 100,
        averagePercentage: _average(results.map((result) => result.percentage)),
        highestPercentage: _max(results.map((result) => result.percentage)),
        lowestPercentage: _min(results.map((result) => result.percentage)),
        topPerformer: ordered.isEmpty ? null : ordered.first,
        weakestPerformer: ordered.isEmpty ? null : ordered.last,
      );
    }).toList()..sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  static double? _passingMarks(
    List<ExamSubjectSetupEntity> setups,
    ExamResultEntity result,
    SubjectResultEntity subject,
  ) {
    for (final setup in setups) {
      if (setup.examId == result.examId &&
          _sameText(setup.classId, result.classId) &&
          _sameText(setup.sectionId, result.sectionId) &&
          (_sameText(setup.subjectId, subject.subjectId) ||
              _sameText(setup.subjectName, subject.subjectName))) {
        return setup.passingMarks;
      }
    }
    return null;
  }

  static bool _sameText(String first, String second) =>
      first.trim().toLowerCase() == second.trim().toLowerCase();

  static double _average(Iterable<double> values) {
    final list = values.toList(growable: false);
    if (list.isEmpty) return 0;
    return list.reduce((first, second) => first + second) / list.length;
  }

  static double _max(Iterable<double> values) {
    final list = values.toList(growable: false);
    return list.isEmpty
        ? 0
        : list.reduce((first, second) => math.max(first, second).toDouble());
  }

  static double _min(Iterable<double> values) {
    final list = values.toList(growable: false);
    return list.isEmpty
        ? 0
        : list.reduce((first, second) => math.min(first, second).toDouble());
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
