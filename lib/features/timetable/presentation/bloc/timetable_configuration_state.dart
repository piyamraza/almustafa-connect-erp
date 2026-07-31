import 'package:equatable/equatable.dart';

import '../../domain/entities/timetable_configuration_entity.dart';

sealed class TimetableConfigurationState extends Equatable {
  const TimetableConfigurationState();

  @override
  List<Object?> get props => [];
}

class TimetableConfigurationInitial extends TimetableConfigurationState {
  const TimetableConfigurationInitial();
}

class TimetableConfigurationLoading extends TimetableConfigurationState {
  const TimetableConfigurationLoading();
}

class TimetableConfigurationEmpty extends TimetableConfigurationState {
  const TimetableConfigurationEmpty({
    required this.branchId,
    required this.academicSession,
  });

  final String branchId;
  final String academicSession;

  @override
  List<Object> get props => [branchId, academicSession];
}

class TimetableConfigurationLoaded extends TimetableConfigurationState {
  const TimetableConfigurationLoaded({
    required this.configuration,
    this.successMessage,
  });

  final TimetableConfigurationEntity configuration;
  final String? successMessage;

  @override
  List<Object?> get props => [configuration, successMessage];
}

class TimetableConfigurationError extends TimetableConfigurationState {
  const TimetableConfigurationError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
