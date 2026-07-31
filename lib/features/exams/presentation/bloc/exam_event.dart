import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_entity.dart';

sealed class ExamEvent extends Equatable {
  const ExamEvent();

  @override
  List<Object?> get props => [];
}

class LoadExams extends ExamEvent {
  const LoadExams({this.academicSession, this.isActive});

  final String? academicSession;
  final bool? isActive;

  @override
  List<Object?> get props => [academicSession, isActive];
}

class RefreshExams extends ExamEvent {
  const RefreshExams({this.academicSession, this.isActive, this.searchQuery});

  final String? academicSession;
  final bool? isActive;
  final String? searchQuery;

  @override
  List<Object?> get props => [academicSession, isActive, searchQuery];
}

class CreateExam extends ExamEvent {
  const CreateExam(this.exam);

  final ExamEntity exam;

  @override
  List<Object?> get props => [exam];
}

class UpdateExam extends ExamEvent {
  const UpdateExam(this.exam);

  final ExamEntity exam;

  @override
  List<Object?> get props => [exam];
}

class DeleteExam extends ExamEvent {
  const DeleteExam(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class ToggleExamActiveStatus extends ExamEvent {
  const ToggleExamActiveStatus({
    required this.examId,
    required this.isActive,
  });

  final String examId;
  final bool isActive;

  @override
  List<Object?> get props => [examId, isActive];
}

class SearchExams extends ExamEvent {
  const SearchExams(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
