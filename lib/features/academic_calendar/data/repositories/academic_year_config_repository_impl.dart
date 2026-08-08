import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/academic_year_config_entity.dart';
import '../../domain/repositories/academic_year_config_repository.dart';
import '../models/academic_year_config_model.dart';

class AcademicYearConfigRepositoryImpl implements AcademicYearConfigRepository {
  const AcademicYearConfigRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<AcademicYearConfigEntity>> getAll() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.academicYearConfigs)
        .get();
    final values = snapshot.docs
        .map(
          (document) => AcademicYearConfigModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList();
    values.sort((a, b) => a.startDate.compareTo(b.startDate));
    return values;
  }

  @override
  Future<AcademicYearConfigEntity?> getBySession(String academicSession) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.academicYearConfigs)
        .get();

    for (final document in snapshot.docs) {
      final model = AcademicYearConfigModel.fromMap({
        ...document.data(),
        'id': document.id,
      });
      if (model.academicSession == academicSession) {
        return model;
      }
    }
    return null;
  }

  @override
  Future<void> save(AcademicYearConfigEntity config) async {
    if (config.academicSession.trim().isEmpty) {
      throw StateError('Academic session is required.');
    }
    if (config.endDate.isBefore(config.startDate)) {
      throw StateError('Session end date cannot be before start date.');
    }
    if (config.workingWeekdays.isEmpty) {
      throw StateError('Select at least one working weekday.');
    }
    if (config.feeGenerationDay < 1 ||
        config.feeGenerationDay > 28 ||
        config.feeDueDay < 1 ||
        config.feeDueDay > 28) {
      throw StateError('Fee generation and due day must be 1 to 28.');
    }

    await _firestoreService
        .collection(FirestorePaths.academicYearConfigs)
        .doc(config.id)
        .set(AcademicYearConfigModel.fromEntity(config).toMap());
  }

  @override
  String generateId() {
    return _firestoreService
        .collection(FirestorePaths.academicYearConfigs)
        .doc()
        .id;
  }
}
