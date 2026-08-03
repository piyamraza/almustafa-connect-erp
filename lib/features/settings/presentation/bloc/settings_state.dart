import 'package:equatable/equatable.dart';

import '../../domain/entities/school_settings_entity.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => const [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({
    required this.settings,
    this.isSaving = false,
    this.message,
  });

  final SchoolSettingsEntity settings;
  final bool isSaving;
  final String? message;

  @override
  List<Object?> get props => [settings, isSaving, message];
}

class SettingsFailure extends SettingsState {
  const SettingsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
