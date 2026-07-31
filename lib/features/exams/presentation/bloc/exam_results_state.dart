import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';

sealed class ExamResultsState extends Equatable {
  const ExamResultsState();

  @override
  List<Object?> get props => const [];
}

class ExamResultsInitial extends ExamResultsState {
  const ExamResultsInitial();
}

class ExamResultsLoading extends ExamResultsState {
  const ExamResultsLoading();
}

class ExamResultsFailure extends ExamResultsState {
  const ExamResultsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ResultStatistics extends Equatable {
  const ResultStatistics({
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.passPercentage,
    required this.highestPercentage,
    required this.lowestPercentage,
    required this.averagePercentage,
  });

  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final double passPercentage;
  final double highestPercentage;
  final double lowestPercentage;
  final double averagePercentage;

  factory ResultStatistics.fromResults(List<ExamResultEntity> results) {
    if (results.isEmpty) {
      return const ResultStatistics(
        totalStudents: 0,
        passedStudents: 0,
        failedStudents: 0,
        passPercentage: 0,
        highestPercentage: 0,
        lowestPercentage: 0,
        averagePercentage: 0,
      );
    }
    final passed = results.where((result) => result.isPassed).length;
    final percentages = results.map((result) => result.percentage).toList();
    percentages.sort();
    final average = percentages.reduce((sum, value) => sum + value) /
        percentages.length;
    return ResultStatistics(
      totalStudents: results.length,
      passedStudents: passed,
      failedStudents: results.length - passed,
      passPercentage: (passed / results.length) * 100,
      highestPercentage: percentages.last,
      lowestPercentage: percentages.first,
      averagePercentage: average,
    );
  }

  @override
  List<Object?> get props => [
        totalStudents,
        passedStudents,
        failedStudents,
        passPercentage,
        highestPercentage,
        lowestPercentage,
        averagePercentage,
      ];
}

class ExamResultsLoaded extends ExamResultsState {
  const ExamResultsLoaded({
    required this.exams,
    this.subjectSetups = const [],
    this.results = const [],
    this.selectedExamId,
    this.selectedClassId,
    this.selectedSectionId,
    this.isLoading = false,
    this.isProcessing = false,
    this.successMessage,
    this.errorMessage,
  });

  final List<ExamEntity> exams;
  final List<ExamSubjectSetupEntity> subjectSetups;
  final List<ExamResultEntity> results;
  final String? selectedExamId;
  final String? selectedClassId;
  final String? selectedSectionId;
  final bool isLoading;
  final bool isProcessing;
  final String? successMessage;
  final String? errorMessage;

  List<ExamEntity> get availableExams {
    final values = [...exams];
    values.sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  List<ExamSubjectSetupEntity> get availableClasses {
    final byId = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where((setup) => setup.isActive)) {
      byId.putIfAbsent(setup.classId, () => setup);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.className.compareTo(second.className));
    return values;
  }

  List<ExamSubjectSetupEntity> get availableSections {
    if (selectedClassId == null) return const [];
    final byId = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where(
      (setup) => setup.isActive && setup.classId == selectedClassId,
    )) {
      byId.putIfAbsent(setup.sectionId, () => setup);
    }
    final values = byId.values.toList(growable: false);
    values.sort((first, second) => first.sectionName.compareTo(second.sectionName));
    return values;
  }

  List<ExamResultEntity> get filteredResults {
    final values = results.where((result) {
      final classMatches = selectedClassId == null ||
          result.classId == selectedClassId;
      final sectionMatches = selectedSectionId == null ||
          result.sectionId == selectedSectionId;
      return classMatches && sectionMatches;
    }).toList();
    values.sort((first, second) {
      final classOrder = first.className.compareTo(second.className);
      if (classOrder != 0) return classOrder;
      final sectionOrder = first.sectionName.compareTo(second.sectionName);
      if (sectionOrder != 0) return sectionOrder;
      final firstRoll = int.tryParse(first.rollNumber.trim());
      final secondRoll = int.tryParse(second.rollNumber.trim());
      if (firstRoll != null && secondRoll != null) {
        return firstRoll.compareTo(secondRoll);
      }
      return first.studentName.compareTo(second.studentName);
    });
    return values;
  }

  ResultStatistics get statistics =>
      ResultStatistics.fromResults(filteredResults);

  ExamResultsLoaded copyWith({
    List<ExamEntity>? exams,
    List<ExamSubjectSetupEntity>? subjectSetups,
    List<ExamResultEntity>? results,
    String? selectedExamId,
    String? selectedClassId,
    String? selectedSectionId,
    bool? isLoading,
    bool? isProcessing,
    bool clearExam = false,
    bool clearClass = false,
    bool clearSection = false,
    bool clearMessages = false,
    String? successMessage,
    String? errorMessage,
  }) {
    return ExamResultsLoaded(
      exams: exams ?? this.exams,
      subjectSetups: subjectSetups ?? this.subjectSetups,
      results: results ?? this.results,
      selectedExamId: clearExam ? null : selectedExamId ?? this.selectedExamId,
      selectedClassId: clearClass ? null : selectedClassId ?? this.selectedClassId,
      selectedSectionId:
          clearSection ? null : selectedSectionId ?? this.selectedSectionId,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      successMessage: successMessage ?? (clearMessages ? null : this.successMessage),
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        exams,
        subjectSetups,
        results,
        selectedExamId,
        selectedClassId,
        selectedSectionId,
        isLoading,
        isProcessing,
        successMessage,
        errorMessage,
      ];
}
