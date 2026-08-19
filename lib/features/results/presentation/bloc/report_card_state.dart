import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/student_development_profile_entity.dart';

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
    this.attendanceDays = 0,
    this.attendedDays = 0,
    this.punctualityRating = 0,
    this.developmentProfile,
    this.classAverage,
    this.highestPercentage,
    this.termProgress = const [],
  });

  final ExamResultEntity result;
  final StudentEntity? student;
  final double? attendancePercentage;
  final int attendanceDays;
  final int attendedDays;
  final int punctualityRating;
  final StudentDevelopmentProfileEntity? developmentProfile;
  final double? classAverage;
  final double? highestPercentage;
  final List<String> termProgress;

  @override
  List<Object?> get props => [
    result,
    student,
    attendancePercentage,
    attendanceDays,
    attendedDays,
    punctualityRating,
    developmentProfile,
    classAverage,
    highestPercentage,
    termProgress,
  ];
}

class ReportCardFailure extends ReportCardState {
  const ReportCardFailure({required this.result, required this.message});

  final ExamResultEntity result;
  final String message;

  @override
  List<Object?> get props => [result, message];
}
