import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_attendance_entity.dart';

sealed class StaffAttendanceEvent extends Equatable {
  const StaffAttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffAttendanceByDateEvent extends StaffAttendanceEvent {
  const LoadStaffAttendanceByDateEvent(this.date);

  final DateTime date;

  @override
  List<Object> get props => [date];
}

class LoadStaffAttendanceByStaffEvent extends StaffAttendanceEvent {
  const LoadStaffAttendanceByStaffEvent({
    required this.staffId,
    required this.startDate,
    required this.endDate,
  });

  final String staffId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        staffId,
        startDate,
        endDate,
      ];
}

class LoadStaffAttendanceByDateRangeEvent extends StaffAttendanceEvent {
  const LoadStaffAttendanceByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        startDate,
        endDate,
      ];
}

class SaveStaffAttendanceEvent extends StaffAttendanceEvent {
  const SaveStaffAttendanceEvent({
    required this.records,
    required this.date,
  });

  final List<StaffAttendanceEntity> records;
  final DateTime date;

  @override
  List<Object> get props => [
        records,
        date,
      ];
}