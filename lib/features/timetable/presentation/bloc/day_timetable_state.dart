import 'package:equatable/equatable.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';

sealed class DayTimetableState extends Equatable {
  const DayTimetableState();

  @override
  List<Object?> get props => [];
}

class DayTimetableInitial extends DayTimetableState {
  const DayTimetableInitial();
}

class DayTimetableLoading extends DayTimetableState {
  const DayTimetableLoading();
}

class DayTimetableLoaded extends DayTimetableState {
  DayTimetableLoaded(List<ClassTimetableEntryEntity> entries)
    : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final List<ClassTimetableEntryEntity> entries;

  @override
  List<Object> get props => [entries];
}

class DayTimetableError extends DayTimetableState {
  const DayTimetableError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
