import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../models/monthly_fee_due_model.dart';

class MonthlyFeeDueRepositoryImpl implements MonthlyFeeDueRepository {
  const MonthlyFeeDueRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<MonthlyFeeDueEntity>> getMonthlyDues({
    String? academicSession,
    int? month,
    int? year,
    String? studentId,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.monthlyFeeDues)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => MonthlyFeeDueModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  (academicSession == null ||
                      item.academicSession == academicSession) &&
                  (month == null || item.month == month) &&
                  (year == null || item.year == year) &&
                  (studentId == null || item.studentId == studentId),
            )
            .toList()
          ..sort((a, b) {
            final name = a.studentName.compareTo(b.studentName);
            if (name != 0) return name;
            final yearCompare = b.year.compareTo(a.year);
            if (yearCompare != 0) return yearCompare;
            return b.month.compareTo(a.month);
          });

    return List<MonthlyFeeDueEntity>.unmodifiable(values);
  }

  @override
  Future<void> saveMonthlyDues(List<MonthlyFeeDueEntity> dues) async {
    if (dues.isEmpty) return;

    final batch = _firestoreService.instance.batch();
    final collection = _firestoreService.collection(
      FirestorePaths.monthlyFeeDues,
    );

    for (final due in dues) {
      batch.set(
        collection.doc(due.id),
        MonthlyFeeDueModel.fromEntity(due).toMap(),
      );
    }

    await batch.commit();
  }

  @override
  Future<void> deleteMonthlyDue(String id) {
    return _firestoreService
        .collection(FirestorePaths.monthlyFeeDues)
        .doc(id)
        .delete();
  }

  @override
  String generateId() {
    return _firestoreService.collection(FirestorePaths.monthlyFeeDues).doc().id;
  }
}
