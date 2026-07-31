import 'package:equatable/equatable.dart';

import '../../domain/entities/teacher_workload_entity.dart';

sealed class TeacherWorkloadState extends Equatable {
  const TeacherWorkloadState();

  @override
  List<Object?> get props => const [];
}

class TeacherWorkloadInitial extends TeacherWorkloadState {
  const TeacherWorkloadInitial();
}

class TeacherWorkloadLoading extends TeacherWorkloadState {
  const TeacherWorkloadLoading();
}

class TeacherWorkloadLoaded extends TeacherWorkloadState {
  const TeacherWorkloadLoaded(this.report);

  final TeacherWorkloadReportEntity report;

  @override
  List<Object?> get props => [report];
}

class TeacherWorkloadError extends TeacherWorkloadState {
  const TeacherWorkloadError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
