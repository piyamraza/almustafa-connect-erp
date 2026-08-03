import '../../domain/entities/school_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._source);

  final SettingsRemoteDataSource _source;

  @override
  Future<SchoolSettingsEntity> getSettings() {
    return _source.getSettings();
  }

  @override
  Future<void> saveSettings(SchoolSettingsEntity settings) {
    return _source.saveSettings(settings);
  }
}
