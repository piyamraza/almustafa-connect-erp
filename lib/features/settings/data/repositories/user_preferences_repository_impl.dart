import '../../domain/entities/user_preferences_entity.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../datasources/user_preferences_remote_datasource.dart';

class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  const UserPreferencesRepositoryImpl(this._source);

  final UserPreferencesRemoteDataSource _source;

  @override
  Future<UserPreferencesEntity> getPreferences(String userId) {
    return _source.getPreferences(userId);
  }

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) {
    return _source.savePreferences(preferences);
  }
}
