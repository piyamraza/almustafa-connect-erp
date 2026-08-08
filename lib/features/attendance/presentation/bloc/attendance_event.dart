import 'package:equatable/equatable.dart';

import '../../domain/entities/attendance_entity.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceEvent extends AttendanceEvent {
  const LoadAttendanceEvent();
}

class RefreshAttendanceEvent extends AttendanceEvent {
  const RefreshAttendanceEvent();
}

class AddAttendanceEvent extends AttendanceEvent {
  final AttendanceEntity attendance;

  const AddAttendanceEvent(this.attendance);

  @override
  List<Object?> get props => [attendance];
}

class UpdateAttendanceEvent extends AttendanceEvent {
  final AttendanceEntity attendance;

  const UpdateAttendanceEvent(this.attendance);

  @override
  List<Object?> get props => [attendance];
}

class DeleteAttendanceEvent extends AttendanceEvent {
  final String attendanceId;

  const DeleteAttendanceEvent(this.attendanceId);

  @override
  List<Object?> get props => [attendanceId];
}

class LoadAttendanceByDateEvent extends AttendanceEvent {
  final DateTime date;

  const LoadAttendanceByDateEvent(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadAttendanceByStudentEvent extends AttendanceEvent {
  final String studentId;

  const LoadAttendanceByStudentEvent(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

class SaveAttendanceBatchEvent extends AttendanceEvent {
  final List<AttendanceEntity> additions;
  final List<AttendanceEntity> updates;

  const SaveAttendanceBatchEvent({
    required this.additions,
    required this.updates,
  });

  @override
  List<Object?> get props => [additions, updates];
}
