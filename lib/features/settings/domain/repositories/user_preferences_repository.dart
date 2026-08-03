import '../entities/user_preferences_entity.dart';

abstract class UserPreferencesRepository {
  Future<UserPreferencesEntity> getPreferences(String userId);

  Future<void> savePreferences(UserPreferencesEntity preferences);
}
