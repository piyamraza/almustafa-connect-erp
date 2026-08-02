import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../models/income_entry_model.dart';

class IncomeRemoteDataSource {
  const IncomeRemoteDataSource(this._service);

  final FirebaseFirestoreService _service;

  Future<List<IncomeEntryEntity>> getIncomeEntries() async {
    final snapshot = await _service
        .collection(FirestorePaths.incomeEntries)
        .get();
    final values = snapshot.docs
        .map((doc) => IncomeEntryModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
    return values;
  }

  Future<void> saveIncomeEntry(IncomeEntryEntity entry) {
    return _service
        .collection(FirestorePaths.incomeEntries)
        .doc(entry.id)
        .set(IncomeEntryModel.fromEntity(entry).toMap());
  }

  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  }) {
    final now = DateTime.now().toIso8601String();
    return _service
        .collection(FirestorePaths.incomeEntries)
        .doc(incomeEntryId)
        .update({
          'status': IncomeEntryStatus.reversed.name,
          'reversedAt': now,
          'reversalReason': reason,
          'updatedAt': now,
        });
  }
}
