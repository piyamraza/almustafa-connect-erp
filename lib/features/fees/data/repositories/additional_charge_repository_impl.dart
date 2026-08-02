import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/additional_charge_repository.dart';
import '../models/additional_charge_model.dart';
import '../models/student_additional_charge_due_model.dart';

class AdditionalChargeRepositoryImpl implements AdditionalChargeRepository {
  const AdditionalChargeRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;

  @override
  Future<List<AdditionalChargeEntity>> getCharges({
    required String academicSession,
    AdditionalChargeScope? scope,
    AdditionalChargeCategory? category,
    bool? isActive,
  }) async {
    final snapshot = await _service
        .collection(FirestorePaths.additionalCharges)
        .get();
    final result =
        snapshot.docs
            .map(
              (d) => AdditionalChargeModel.fromMap({...d.data(), 'id': d.id}),
            )
            .where(
              (e) =>
                  e.academicSession == academicSession &&
                  (scope == null || e.scope == scope) &&
                  (category == null || e.category == category) &&
                  (isActive == null || e.isActive == isActive),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  @override
  Future<AdditionalChargeEntity?> getChargeById(String id) async {
    final doc = await _service
        .collection(FirestorePaths.additionalCharges)
        .doc(id)
        .get();
    return doc.exists && doc.data() != null
        ? AdditionalChargeModel.fromMap({...doc.data()!, 'id': doc.id})
        : null;
  }

  @override
  Future<void> saveCharge(AdditionalChargeEntity charge) => _service
      .collection(FirestorePaths.additionalCharges)
      .doc(charge.id)
      .set(AdditionalChargeModel.fromEntity(charge).toMap());

  @override
  Future<void> markGenerated(String id, int studentCount) =>
      _service.collection(FirestorePaths.additionalCharges).doc(id).update({
        'generated': true,
        'generatedStudentCount': studentCount,
        'updatedAt': DateTime.now(),
      });

  @override
  Future<void> deleteCharge(String id) async {
    final dues = await _service
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .get();
    final linked = dues.docs
        .map(
          (d) => StudentAdditionalChargeDueModel.fromMap({
            ...d.data(),
            'id': d.id,
          }),
        )
        .where((d) => d.chargeId == id)
        .toList();
    if (linked.any(
      (d) =>
          d.paidAmount > 0 ||
          d.status == StudentAdditionalChargeDueStatus.paid ||
          d.status == StudentAdditionalChargeDueStatus.partiallyPaid,
    )) {
      throw StateError('This charge has paid dues and cannot be deleted.');
    }
    if (linked.isNotEmpty) {
      throw StateError(
        'Delete or cancel generated dues before deleting this charge.',
      );
    }
    await _service
        .collection(FirestorePaths.additionalCharges)
        .doc(id)
        .delete();
  }

  @override
  String generateId() =>
      _service.collection(FirestorePaths.additionalCharges).doc().id;
}
