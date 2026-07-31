import 'package:equatable/equatable.dart';

import 'class_timetable_entry_entity.dart';

class AutoTimetableGenerationRequest extends Equatable {
  const AutoTimetableGenerationRequest({
    required this.branchId,
    required this.academicSession,
    required this.replaceExisting,
  });

  final String branchId;
  final String academicSession;
  final bool replaceExisting;

  @override
  List<Object> get props => [branchId, academicSession, replaceExisting];
}

class AutoTimetableGenerationResult extends Equatable {
  AutoTimetableGenerationResult({
    required List<ClassTimetableEntryEntity> generatedEntries,
    required List<String> warnings,
    required this.totalClassSections,
    required this.totalAvailableSlots,
    required this.preservedEntries,
  }) : generatedEntries = List<ClassTimetableEntryEntity>.unmodifiable(
         generatedEntries,
       ),
       warnings = List<String>.unmodifiable(warnings);

  final List<ClassTimetableEntryEntity> generatedEntries;
  final List<String> warnings;
  final int totalClassSections;
  final int totalAvailableSlots;
  final int preservedEntries;

  int get generatedCount => generatedEntries.length;
  int get warningCount => warnings.length;

  @override
  List<Object> get props => [
    generatedEntries,
    warnings,
    totalClassSections,
    totalAvailableSlots,
    preservedEntries,
  ];
}
