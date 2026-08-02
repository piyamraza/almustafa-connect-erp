import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/student_additional_charge_due_repository.dart';
import '../models/student_additional_charge_due_model.dart';

class StudentAdditionalChargeDueRepositoryImpl
    implements StudentAdditionalChargeDueRepository {
  const StudentAdditionalChargeDueRepositoryImpl(this._service);
  final FirebaseFirestoreService _service;

  Future<List<StudentAdditionalChargeDueEntity>> _all() async {
    final snapshot = await _service
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .get();
    return snapshot.docs
        .map(
          (d) => StudentAdditionalChargeDueModel.fromMap({
            ...d.data(),
            'id': d.id,
          }),
        )
        .toList();
  }

  @override
  Future<List<StudentAdditionalChargeDueEntity>> getDues({
    String? academicSession,
    String? chargeId,
    String? classId,
    String? sectionId,
    StudentAdditionalChargeDueStatus? status,
  }) async {
    final result =
        (await _all())
            .where(
              (e) =>
                  (academicSession == null ||
                      e.academicSession == academicSession) &&
                  (chargeId == null || e.chargeId == chargeId) &&
                  (classId == null || e.classId == classId) &&
                  (sectionId == null || e.sectionId == sectionId) &&
                  (status == null || e.status == status),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return List.unmodifiable(result);
  }

  @override
  Future<List<StudentAdditionalChargeDueEntity>> getStudentDues(
    String studentId, {
    String? academicSession,
  }) async => (await _all())
      .where(
        (e) =>
            e.studentId == studentId &&
            (academicSession == null || e.academicSession == academicSession),
      )
      .toList();

  @override
  Future<void> saveDue(StudentAdditionalChargeDueEntity due) => _service
      .collection(FirestorePaths.studentAdditionalChargeDues)
      .doc(due.id)
      .set(StudentAdditionalChargeDueModel.fromEntity(due).toMap());
  @override
  Future<void> updateDue(StudentAdditionalChargeDueEntity due) => saveDue(due);

  @override
  Future<void> saveDuesBatch(
    List<StudentAdditionalChargeDueEntity> dues,
  ) async {
    for (var start = 0; start < dues.length; start += 450) {
      final batch = _service.instance.batch();
      final end = (start + 450).clamp(0, dues.length);
      for (final due in dues.sublist(start, end)) {
        batch.set(
          _service
              .collection(FirestorePaths.studentAdditionalChargeDues)
              .doc(due.id),
          StudentAdditionalChargeDueModel.fromEntity(due).toMap(),
        );
      }
      await batch.commit();
    }
  }

  @override
  Future<bool> chargeAlreadyGeneratedForStudent(
    String chargeId,
    String studentId,
  ) async => (await _all()).any(
    (e) =>
        e.chargeId == chargeId &&
        e.studentId == studentId &&
        e.status != StudentAdditionalChargeDueStatus.cancelled,
  );

  @override
  Future<void> deleteDue(String id) async {
    final doc = await _service
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) return;
    final due = StudentAdditionalChargeDueModel.fromMap({
      ...doc.data()!,
      'id': doc.id,
    });
    if (due.paidAmount > 0) {
      throw StateError('A paid additional charge due cannot be deleted.');
    }
    await doc.reference.delete();
  }

  @override
  String generateId() =>
      _service.collection(FirestorePaths.studentAdditionalChargeDues).doc().id;
}
