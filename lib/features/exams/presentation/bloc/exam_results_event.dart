import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_result_entity.dart';

sealed class ExamResultsEvent extends Equatable {
  const ExamResultsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadResultSummary extends ExamResultsEvent {
  const LoadResultSummary();
}

class RefreshResultSummary extends ExamResultsEvent {
  const RefreshResultSummary();
}

class SelectResultExam extends ExamResultsEvent {
  const SelectResultExam(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class SelectResultClass extends ExamResultsEvent {
  const SelectResultClass(this.classId);

  final String? classId;

  @override
  List<Object?> get props => [classId];
}

class SelectResultSection extends ExamResultsEvent {
  const SelectResultSection(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

class GenerateSelectedExamResults extends ExamResultsEvent {
  const GenerateSelectedExamResults();
}

class ChangeFilteredResultsStatus extends ExamResultsEvent {
  const ChangeFilteredResultsStatus(this.status);

  final ResultStatus status;

  @override
  List<Object?> get props => [status];
}

class UnlockFilteredResults extends ExamResultsEvent {
  const UnlockFilteredResults();
}
