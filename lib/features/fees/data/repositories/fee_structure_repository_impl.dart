import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/fee_structure_entity.dart';
import '../../domain/repositories/fee_structure_repository.dart';
import '../models/fee_structure_model.dart';

class FeeStructureRepositoryImpl implements FeeStructureRepository {
  const FeeStructureRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<FeeStructureEntity>> getFeeStructures({
    String? academicSession,
    String? classId,
    String? sectionId,
    bool? isActive,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.feeStructures)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => FeeStructureModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  (academicSession == null ||
                      item.academicSession == academicSession) &&
                  (classId == null || item.classId == classId) &&
                  (sectionId == null || item.sectionId == sectionId) &&
                  (isActive == null || item.isActive == isActive),
            )
            .toList()
          ..sort((a, b) {
            final classCompare = a.className.compareTo(b.className);
            if (classCompare != 0) return classCompare;
            return a.sectionName.compareTo(b.sectionName);
          });

    return List<FeeStructureEntity>.unmodifiable(values);
  }

  @override
  Future<void> saveFeeStructure(FeeStructureEntity structure) async {
    final existing = await getFeeStructures(
      academicSession: structure.academicSession,
      classId: structure.classId,
      sectionId: structure.sectionId,
    );

    final duplicate = existing.any((item) => item.id != structure.id);
    if (duplicate) {
      throw StateError(
        'A fee structure already exists for '
        '${structure.className} - ${structure.sectionName} '
        'in ${structure.academicSession}.',
      );
    }

    await _firestoreService
        .collection(FirestorePaths.feeStructures)
        .doc(structure.id)
        .set(FeeStructureModel.fromEntity(structure).toMap());
  }

  @override
  Future<void> deleteFeeStructure(String id) {
    return _firestoreService
        .collection(FirestorePaths.feeStructures)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService.collection(FirestorePaths.feeStructures).doc().id;
  }
}
