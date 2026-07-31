import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_entity.dart';

sealed class ExamState extends Equatable {
  const ExamState();

  @override
  List<Object?> get props => [];
}

class ExamInitial extends ExamState {
  const ExamInitial();
}

class ExamLoading extends ExamState {
  const ExamLoading();
}

class ExamLoaded extends ExamState {
  const ExamLoaded(
    this.exams, {
    List<ExamEntity>? allExams,
    this.searchQuery = '',
    this.academicSession,
    this.isActive,
    this.successMessage,
  }) : allExams = allExams ?? exams;

  /// Exams currently visible after applying the local search query.
  final List<ExamEntity> exams;

  /// Complete server result before local search filtering.
  final List<ExamEntity> allExams;
  final String searchQuery;
  final String? academicSession;
  final bool? isActive;
  final String? successMessage;

  @override
  List<Object?> get props => [
        exams,
        allExams,
        searchQuery,
        academicSession,
        isActive,
        successMessage,
      ];
}

class ExamError extends ExamState {
  const ExamError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
