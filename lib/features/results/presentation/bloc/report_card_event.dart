import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';

sealed class ReportCardEvent extends Equatable {
  const ReportCardEvent();

  @override
  List<Object?> get props => const [];
}

class LoadReportCard extends ReportCardEvent {
  const LoadReportCard(this.result);

  final ExamResultEntity result;

  @override
  List<Object?> get props => [result];
}
