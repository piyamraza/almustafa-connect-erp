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
  });

  final String branchId;
  final String academicSession;

  @override
  List<Object> get props => [branchId, academicSession];
}

class SaveTimetableConfigurationEvent extends TimetableConfigurationEvent {
  const SaveTimetableConfigurationEvent(this.configuration);

  final TimetableConfigurationEntity configuration;

  @override
  List<Object> get props => [configuration];
}
