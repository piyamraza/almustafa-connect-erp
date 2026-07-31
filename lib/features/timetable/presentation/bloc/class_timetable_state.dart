import 'package:equatable/equatable.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';

sealed class ClassTimetableState extends Equatable {
  const ClassTimetableState();

  @override
  List<Object?> get props => [];
}

class ClassTimetableInitial extends ClassTimetableState {
  const ClassTimetableInitial();
}

class ClassTimetableLoading extends ClassTimetableState {
  const ClassTimetableLoading();
}

class ClassTimetableLoaded extends ClassTimetableState {
  ClassTimetableLoaded({
    required List<ClassTimetableEntryEntity> entries,
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
    this.successMessage,
  }) : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final List<ClassTimetableEntryEntity> entries;
  final String branchId;
  final String academicSession;
  final String classId;
  final String sectionId;
  final String? successMessage;

  @override
  List<Object?> get props => [
    entries,
    branchId,
    academicSession,
    classId,
    sectionId,
    successMessage,
  ];
}

class ClassTimetableError extends ClassTimetableState {
  const ClassTimetableError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
