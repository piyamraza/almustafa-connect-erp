import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/user_preferences_entity.dart';
import '../models/user_preferences_model.dart';

abstract class UserPreferencesRemoteDataSource {
  Future<UserPreferencesEntity> getPreferences(String userId);

  Future<void> savePreferences(UserPreferencesEntity preferences);
}

class UserPreferencesRemoteDataSourceImpl
    implements UserPreferencesRemoteDataSource {
  const UserPreferencesRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<UserPreferencesEntity> getPreferences(String userId) async {
    final id = userId.trim().isEmpty ? 'default' : userId;

    final document = await _service
        .collection(FirestorePaths.userPreferences)
        .doc(id)
        .get();

    if (!document.exists) {
      return UserPreferencesEntity(
        id: id,
        userId: userId,
        theme: AppThemePreference.system,
        defaultLandingPage: 'dashboard',
        rememberLastScreen: true,
        pushNotifications: true,
        homeworkNotifications: true,
        attendanceNotifications: true,
        feeNotifications: true,
        examNotifications: true,
        paperSize: 'A4',
        receiptFormat: 'Standard',
        resultCardFormat: 'Standard',
        language: 'English',
        updatedAt: DateTime.now(),
      );
    }

    return UserPreferencesModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });
  }

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) {
    return _service
        .collection(FirestorePaths.userPreferences)
        .doc(preferences.id)
        .set(UserPreferencesModel.fromEntity(preferences).toMap());
  }
}
