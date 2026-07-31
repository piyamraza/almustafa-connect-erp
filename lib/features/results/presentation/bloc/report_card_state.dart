import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../students/domain/entities/student_entity.dart';

sealed class ReportCardState extends Equatable {
  const ReportCardState();

  @override
  List<Object?> get props => const [];
}

class ReportCardInitial extends ReportCardState {
  const ReportCardInitial();
}

class ReportCardLoading extends ReportCardState {
  const ReportCardLoading(this.result);

  final ExamResultEntity result;

  @override
  List<Object?> get props => [result];
}

class ReportCardLoaded extends ReportCardState {
  const ReportCardLoaded({
    required this.result,
    this.student,
    this.attendancePercentage,
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final double? attendancePercentage;

  @override
  List<Object?> get props => [result, student, attendancePercentage];
}

class ReportCardFailure extends ReportCardState {
  const ReportCardFailure({required this.result, required this.message});

  final ExamResultEntity result;
  final String message;

  @override
  List<Object?> get props => [result, message];
}
