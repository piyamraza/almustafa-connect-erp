import '../entities/school_settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetSchoolSettings {
  const GetSchoolSettings(this._repository);

  final SettingsRepository _repository;

  Future<SchoolSettingsEntity> call() {
    return _repository.getSettings();
  }
}

class SaveSchoolSettings {
  const SaveSchoolSettings(this._repository);

  final SettingsRepository _repository;

  Future<void> call(SchoolSettingsEntity settings) {
    if (settings.schoolName.trim().isEmpty) {
      throw ArgumentError('School name is required.');
    }
    if (settings.schoolCode.trim().isEmpty) {
      throw ArgumentError('School code is required.');
    }
    if (settings.currentSession.trim().isEmpty) {
      throw ArgumentError('Current session is required.');
    }
    if (!settings.sessionEndDate.isAfter(settings.sessionStartDate)) {
      throw ArgumentError('Session end date must be after start date.');
    }
    return _repository.saveSettings(settings);
  }
}
