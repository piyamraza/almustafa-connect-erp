import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';

sealed class ResultDetailsEvent extends Equatable {
  const ResultDetailsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadResultDetails extends ResultDetailsEvent {
  const LoadResultDetails(this.result);

  final ExamResultEntity result;

  @override
  List<Object?> get props => [result];
}
