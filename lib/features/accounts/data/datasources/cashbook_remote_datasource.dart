import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/cashbook_entry_entity.dart';
import '../models/cashbook_entry_model.dart';

class CashbookRemoteDataSource {
  const CashbookRemoteDataSource(this._service);

  final FirebaseFirestoreService _service;

  Future<List<CashbookEntryEntity>> getEntries() async {
    final snapshot = await _service
        .collection(FirestorePaths.cashbookEntries)
        .get();

    final values = snapshot.docs
        .map((doc) => CashbookEntryModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) {
      final dateComparison = a.entryDate.compareTo(b.entryDate);
      if (dateComparison != 0) return dateComparison;
      return a.createdAt.compareTo(b.createdAt);
    });

    return values;
  }

  Future<void> saveEntry(CashbookEntryEntity entry) {
    return _service
        .collection(FirestorePaths.cashbookEntries)
        .doc(entry.id)
        .set(CashbookEntryModel.fromEntity(entry).toMap());
  }
}
