import 'package:equatable/equatable.dart';

sealed class TeacherTimetableEvent extends Equatable {
  const TeacherTimetableEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeacherTimetableEvent extends TeacherTimetableEvent {
  const LoadTeacherTimetableEvent({
    required this.branchId,
    required this.academicSession,
    required this.teacherId,
  });

  final String branchId;
  final String academicSession;
  final String teacherId;

  @override
  List<Object> get props => [branchId, academicSession, teacherId];
}
