import '../entities/user_preferences_entity.dart';
import '../repositories/user_preferences_repository.dart';

class GetUserPreferences {
  const GetUserPreferences(this._repository);

  final UserPreferencesRepository _repository;

  Future<UserPreferencesEntity> call(String userId) {
    return _repository.getPreferences(userId);
  }
}

class SaveUserPreferences {
  const SaveUserPreferences(this._repository);

  final UserPreferencesRepository _repository;

  Future<void> call(UserPreferencesEntity preferences) {
    if (preferences.id.trim().isEmpty) {
      throw ArgumentError('Preference ID is required.');
    }

    return _repository.savePreferences(preferences);
  }
}
