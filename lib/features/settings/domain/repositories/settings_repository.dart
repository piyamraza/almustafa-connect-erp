import '../entities/school_settings_entity.dart';

abstract class SettingsRepository {
  Future<SchoolSettingsEntity> getSettings();
  Future<void> saveSettings(SchoolSettingsEntity settings);
}
