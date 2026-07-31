import 'package:equatable/equatable.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';

sealed class ClassTimetableEvent extends Equatable {
  const ClassTimetableEvent();

  @override
  List<Object?> get props => [];
}

class LoadClassTimetableEvent extends ClassTimetableEvent {
  const LoadClassTimetableEvent({
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
  });

  final String branchId;
  final String academicSession;
  final String classId;
  final String sectionId;

  @override
  List<Object> get props => [branchId, academicSession, classId, sectionId];
}

class SaveClassTimetableEntryEvent extends ClassTimetableEvent {
  const SaveClassTimetableEntryEvent(this.entry);

  final ClassTimetableEntryEntity entry;

  @override
  List<Object> get props => [entry];
}

class DeleteClassTimetableEntryEvent extends ClassTimetableEvent {
  const DeleteClassTimetableEntryEvent({
    required this.entryId,
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
  });

  final String entryId;
  final String branchId;
  final String academicSession;
  final String classId;
  final String sectionId;

  @override
  List<Object> get props => [
    entryId,
    branchId,
    academicSession,
    classId,
    sectionId,
  ];
}
