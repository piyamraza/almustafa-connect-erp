import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/school_settings_entity.dart';
import '../models/school_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<SchoolSettingsEntity> getSettings();
  Future<void> saveSettings(SchoolSettingsEntity settings);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  const SettingsRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<SchoolSettingsEntity> getSettings() async {
    final document = await _service
        .collection(FirestorePaths.systemSettings)
        .doc('default')
        .get();

    if (!document.exists) {
      final now = DateTime.now();

      return SchoolSettingsEntity(
        id: 'default',
        schoolName: 'Almustafa Model School',
        schoolCode: 'AMS',
        currentSession: '2026-2027',
        sessionStartDate: DateTime(2026, 4, 1),
        sessionEndDate: DateTime(2027, 3, 31),
        currency: 'PKR',
        currencySymbol: 'Rs.',
        dateFormat: 'dd-MM-yyyy',
        timeFormat: '12 Hour',
        admissionPrefix: 'AMS',
        rollNumberPrefix: '',
        receiptPrefix: 'REC',
        updatedAt: now,
        city: 'Multan',
        country: 'Pakistan',
      );
    }

    return SchoolSettingsModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });
  }

  @override
  Future<void> saveSettings(SchoolSettingsEntity settings) {
    return _service
        .collection(FirestorePaths.systemSettings)
        .doc(settings.id)
        .set(SchoolSettingsModel.fromEntity(settings).toMap());
  }
}
