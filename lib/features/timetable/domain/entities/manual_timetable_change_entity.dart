import 'package:equatable/equatable.dart';

import 'class_timetable_entry_entity.dart';

class ManualTimetableChangeSet extends Equatable {
  ManualTimetableChangeSet({
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
    required List<String> deletedEntryIds,
    required List<ClassTimetableEntryEntity> entries,
  }) : deletedEntryIds = List<String>.unmodifiable(deletedEntryIds),
       entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final String branchId;
  final String academicSession;
  final String classId;
  final String sectionId;
  final List<String> deletedEntryIds;
  final List<ClassTimetableEntryEntity> entries;

  @override
  List<Object> get props => [
    branchId,
    academicSession,
    classId,
    sectionId,
    deletedEntryIds,
    entries,
  ];
}
