import 'package:equatable/equatable.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../domain/entities/result_analytics_entity.dart';
import '../../domain/usecases/results_analytics_calculator.dart';
import '../../../exams/domain/services/result_subject_grouping_service.dart';

sealed class ResultsAnalyticsState extends Equatable {
  const ResultsAnalyticsState();

  @override
  List<Object?> get props => const [];
}

class ResultsAnalyticsInitial extends ResultsAnalyticsState {
  const ResultsAnalyticsInitial();
}

class ResultsAnalyticsLoading extends ResultsAnalyticsState {
  const ResultsAnalyticsLoading();
}

class ResultsAnalyticsFailure extends ResultsAnalyticsState {
  const ResultsAnalyticsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ResultsAnalyticsLoaded extends ResultsAnalyticsState {
  const ResultsAnalyticsLoaded({
    required this.data,
    this.filter = const ResultAnalyticsFilter(),
    this.isRefreshing = false,
  });

  final ResultAnalyticsData data;
  final ResultAnalyticsFilter filter;
  final bool isRefreshing;

  List<String> get availableSessions {
    final values = data.results
        .map((result) => result.academicSession.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values.reversed.toList(growable: false);
  }

  List<ExamResultEntity> get availableExams {
    final values = <String, ExamResultEntity>{};
    for (final result in data.results.where(
      (item) =>
          filter.academicSession == null ||
          item.academicSession == filter.academicSession,
    )) {
      values.putIfAbsent(result.examId, () => result);
    }
    final exams = values.values.toList();
    exams.sort((first, second) => first.examName.compareTo(second.examName));
    return exams;
  }

  List<ExamResultEntity> get availableClasses {
    final values = <String, ExamResultEntity>{};
    for (final result in data.results.where(
      (item) =>
          (filter.academicSession == null ||
              item.academicSession == filter.academicSession) &&
          (filter.examId == null || item.examId == filter.examId),
    )) {
      values.putIfAbsent(result.classId, () => result);
    }
    final classes = values.values.toList();
    classes.sort(
      (first, second) =>
          compareAcademicClassNames(first.className, second.className),
    );
    return classes;
  }

  List<ExamResultEntity> get availableSections {
    if (filter.classId == null) return const [];
    final values = <String, ExamResultEntity>{};
    for (final result in data.results.where(
      (item) =>
          (filter.academicSession == null ||
              item.academicSession == filter.academicSession) &&
          (filter.examId == null || item.examId == filter.examId) &&
          item.classId == filter.classId,
    )) {
      values.putIfAbsent(result.sectionId, () => result);
    }
    final sections = values.values.toList();
    sections.sort(
      (first, second) => first.sectionName.compareTo(second.sectionName),
    );
    return sections;
  }

  List<String> get availableSubjects {
    final values = <String>{};
    for (final result in ResultsAnalyticsCalculator.filteredResults(
      data,
      filter.copyWith(clearSubject: true, clearStudent: true),
    )) {
      for (final subject in ResultSubjectGroupingService.group(
        result.subjectResults,
      )) {
        if (subject.subjectName.trim().isNotEmpty) {
          values.add(subject.subjectName);
        }
      }
    }
    final subjects = values.toList();
    subjects.sort();
    return subjects;
  }

  List<ExamResultEntity> get availableStudents {
    final values = <String, ExamResultEntity>{};
    for (final result in ResultsAnalyticsCalculator.filteredResults(
      data,
      filter.copyWith(clearStudent: true),
    )) {
      values.putIfAbsent(result.studentId, () => result);
    }
    final students = values.values.toList();
    students.sort(
      (first, second) => first.studentName.compareTo(second.studentName),
    );
    return students;
  }

  List<ExamResultEntity> get results =>
      ResultsAnalyticsCalculator.filteredResults(data, filter);

  ResultsAnalyticsLoaded copyWith({
    ResultAnalyticsData? data,
    ResultAnalyticsFilter? filter,
    bool? isRefreshing,
  }) {
    return ResultsAnalyticsLoaded(
      data: data ?? this.data,
      filter: filter ?? this.filter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [data, filter, isRefreshing];
}
