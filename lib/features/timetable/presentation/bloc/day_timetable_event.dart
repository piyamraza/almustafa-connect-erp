import 'package:equatable/equatable.dart';

sealed class DayTimetableEvent extends Equatable {
  const DayTimetableEvent();

  @override
  List<Object?> get props => [];
}

class LoadDayTimetableEvent extends DayTimetableEvent {
  const LoadDayTimetableEvent({
    required this.branchId,
    required this.academicSession,
    required this.weekday,
  });

  final String branchId;
  final String academicSession;
  final int weekday;

  @override
  List<Object> get props => [branchId, academicSession, weekday];
}
