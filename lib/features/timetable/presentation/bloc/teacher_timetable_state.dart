import 'package:equatable/equatable.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';

sealed class TeacherTimetableState extends Equatable {
  const TeacherTimetableState();

  @override
  List<Object?> get props => [];
}

class TeacherTimetableInitial extends TeacherTimetableState {
  const TeacherTimetableInitial();
}

class TeacherTimetableLoading extends TeacherTimetableState {
  const TeacherTimetableLoading();
}

class TeacherTimetableLoaded extends TeacherTimetableState {
  TeacherTimetableLoaded(List<ClassTimetableEntryEntity> entries)
    : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final List<ClassTimetableEntryEntity> entries;

  @override
  List<Object> get props => [entries];
}

class TeacherTimetableError extends TeacherTimetableState {
  const TeacherTimetableError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
