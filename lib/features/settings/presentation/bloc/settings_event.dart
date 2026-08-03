import 'package:equatable/equatable.dart';

import '../../domain/entities/school_settings_entity.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class SaveSettingsRequested extends SettingsEvent {
  const SaveSettingsRequested(this.settings);

  final SchoolSettingsEntity settings;

  @override
  List<Object?> get props => [settings];
}
