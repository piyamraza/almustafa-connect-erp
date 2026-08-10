import 'package:equatable/equatable.dart';

import '../../domain/entities/timetable_configuration_entity.dart';

sealed class TimetableConfigurationEvent extends Equatable {
  const TimetableConfigurationEvent();

  @override
  List<Object?> get props => [];
}

class LoadTimetableConfigurationEvent extends TimetableConfigurationEvent {
  const LoadTimetableConfigurationEvent({
    required this.branchId,
    required this.academicSession,
    this.classId,
  });

  final String branchId;
  final String academicSession;
  final String? classId;

  @override
  List<Object?> get props => [branchId, academicSession, classId];
}

class SaveTimetableConfigurationEvent extends TimetableConfigurationEvent {
  const SaveTimetableConfigurationEvent(this.configuration);

  final TimetableConfigurationEntity configuration;

  @override
  List<Object> get props => [configuration];
}
