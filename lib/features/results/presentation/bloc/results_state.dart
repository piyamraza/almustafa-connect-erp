import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';

sealed class ResultsState extends Equatable {
  const ResultsState();

  @override
  List<Object?> get props => const [];
}

class ResultsInitial extends ResultsState {
  const ResultsInitial();
}

class ResultsLoading extends ResultsState {
  const ResultsLoading();
}

class ResultsFailure extends ResultsState {
  const ResultsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PublishedResultsStatistics extends Equatable {
  const PublishedResultsStatistics({
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.passPercentage,
    required this.averagePercentage,
  });

  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final double passPercentage;
  final double averagePercentage;

  factory PublishedResultsStatistics.fromResults(List<ExamResultEntity> results) {
    if (results.isEmpty) {
      return const PublishedResultsStatistics(
        totalStudents: 0,
        passedStudents: 0,
        failedStudents: 0,
        passPercentage: 0,
        averagePercentage: 0,
      );
    }
    final passed = results.where((result) => result.isPassed).length;
    final average = results
            .map((result) => result.percentage)
            .reduce((first, second) => first + second) /
        results.length;
    return PublishedResultsStatistics(
      totalStudents: results.length,
      passedStudents: passed,
      failedStudents: results.length - passed,
      passPercentage: (passed / results.length) * 100,
      averagePercentage: average,
    );
  }

  @override
  List<Object?> get props => [
        totalStudents,
        passedStudents,
        failedStudents,
        passPercentage,
        averagePercentage,
      ];
}

class PublishedResultsLoaded extends ResultsState {
  const PublishedResultsLoaded({
    required this.results,
    this.selectedAcademicSession,
    this.selectedExamId,
    this.selectedClassId,
    this.selectedSectionId,
    this.selectedStudentId,
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<ExamResultEntity> results;
  final String? selectedAcademicSession;
  final String? selectedExamId;
  final String? selectedClassId;
  final String? selectedSectionId;
  final String? selectedStudentId;
  final String searchQuery;
  final bool isLoading;

  List<String> get availableSessions {
    final values = results
        .map((result) => result.academicSession.trim())
        .where((session) => session.isNotEmpty)
        .toSet()
        .toList(growable: false);
    values.sort();
    return values.reversed.toList(growable: false);
  }

  List<ExamResultEntity> get availableExams {
    final byId = <String, ExamResultEntity>{};
    for (final result in results.where(
      (result) =>
          selectedAcademicSession == null ||
          result.academicSession == selectedAcademicSession,
    )) {
      byId.putIfAbsent(result.examId, () => result);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.examName.compareTo(second.examName));
    return values;
  }

  List<ExamResultEntity> get availableClasses {
    final byId = <String, ExamResultEntity>{};
    for (final result in results.where(
      (result) =>
          (selectedAcademicSession == null ||
              result.academicSession == selectedAcademicSession) &&
          (selectedExamId == null || result.examId == selectedExamId),
    )) {
      byId.putIfAbsent(result.classId, () => result);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.className.compareTo(second.className));
    return values;
  }

  List<ExamResultEntity> get availableSections {
    if (selectedClassId == null) return const [];
    final byId = <String, ExamResultEntity>{};
    for (final result in results.where(
      (result) =>
          (selectedAcademicSession == null ||
              result.academicSession == selectedAcademicSession) &&
          (selectedExamId == null || result.examId == selectedExamId) &&
          result.classId == selectedClassId,
    )) {
      byId.putIfAbsent(result.sectionId, () => result);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.sectionName.compareTo(second.sectionName));
    return values;
  }

  List<ExamResultEntity> get availableStudents {
    final byId = <String, ExamResultEntity>{};
    for (final result in _filteredWithoutStudent) {
      byId.putIfAbsent(result.studentId, () => result);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.studentName.compareTo(second.studentName));
    return values;
  }

  List<ExamResultEntity> get filteredResults {
    final query = searchQuery.trim().toLowerCase();
    final values = _filteredWithoutStudent.where((result) {
      final studentMatches = selectedStudentId == null ||
          result.studentId == selectedStudentId;
      final searchMatches = query.isEmpty ||
          [
            result.studentName,
            result.rollNumber,
            result.admissionNo,
            result.examName,
            result.className,
            result.sectionName,
          ].join(' ').toLowerCase().contains(query);
      return studentMatches && searchMatches;
    }).toList();
    values.sort((first, second) {
      final examOrder = first.examName.compareTo(second.examName);
      if (examOrder != 0) return examOrder;
      return first.overallRank.compareTo(second.overallRank);
    });
    return values;
  }

  List<ExamResultEntity> get _filteredWithoutStudent => results.where((result) {
        return (selectedAcademicSession == null ||
                result.academicSession == selectedAcademicSession) &&
            (selectedExamId == null || result.examId == selectedExamId) &&
            (selectedClassId == null || result.classId == selectedClassId) &&
            (selectedSectionId == null || result.sectionId == selectedSectionId);
      }).toList(growable: false);

  PublishedResultsStatistics get statistics =>
      PublishedResultsStatistics.fromResults(filteredResults);

  PublishedResultsLoaded copyWith({
    List<ExamResultEntity>? results,
    String? selectedAcademicSession,
    String? selectedExamId,
    String? selectedClassId,
    String? selectedSectionId,
    String? selectedStudentId,
    String? searchQuery,
    bool? isLoading,
    bool clearExam = false,
    bool clearSession = false,
    bool clearClass = false,
    bool clearSection = false,
    bool clearStudent = false,
  }) {
    return PublishedResultsLoaded(
      results: results ?? this.results,
      selectedAcademicSession: clearSession
          ? null
          : selectedAcademicSession ?? this.selectedAcademicSession,
      selectedExamId: clearExam ? null : selectedExamId ?? this.selectedExamId,
      selectedClassId: clearClass ? null : selectedClassId ?? this.selectedClassId,
      selectedSectionId:
          clearSection ? null : selectedSectionId ?? this.selectedSectionId,
      selectedStudentId:
          clearStudent ? null : selectedStudentId ?? this.selectedStudentId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        results,
        selectedAcademicSession,
        selectedExamId,
        selectedClassId,
        selectedSectionId,
        selectedStudentId,
        searchQuery,
        isLoading,
      ];
}
