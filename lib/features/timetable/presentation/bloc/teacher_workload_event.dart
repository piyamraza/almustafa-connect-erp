import 'package:equatable/equatable.dart';

sealed class TeacherWorkloadEvent extends Equatable {
  const TeacherWorkloadEvent();

  @override
  List<Object> get props => const [];
}

class LoadTeacherWorkloadEvent extends TeacherWorkloadEvent {
  const LoadTeacherWorkloadEvent({
    required this.branchId,
    required this.academicSession,
  });

  final String branchId;
  final String academicSession;

  @override
  List<Object> get props => [branchId, academicSession];
}
