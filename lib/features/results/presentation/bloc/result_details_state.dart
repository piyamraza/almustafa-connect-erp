import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../students/domain/entities/student_entity.dart';

sealed class ResultDetailsState extends Equatable {
  const ResultDetailsState();

  @override
  List<Object?> get props => const [];
}

class ResultDetailsInitial extends ResultDetailsState {
  const ResultDetailsInitial();
}

class ResultDetailsLoading extends ResultDetailsState {
  const ResultDetailsLoading(this.result);

  final ExamResultEntity result;

  @override
  List<Object?> get props => [result];
}

class ResultDetailsLoaded extends ResultDetailsState {
  const ResultDetailsLoaded({required this.result, this.student});

  final ExamResultEntity result;
  final StudentEntity? student;

  @override
  List<Object?> get props => [result, student];
}

class ResultDetailsFailure extends ResultDetailsState {
  const ResultDetailsFailure({required this.result, required this.message});

  final ExamResultEntity result;
  final String message;

  @override
  List<Object?> get props => [result, message];
}
