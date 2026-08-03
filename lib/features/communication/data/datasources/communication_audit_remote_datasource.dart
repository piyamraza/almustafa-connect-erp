import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/communication_audit_entry_entity.dart';
import '../models/communication_audit_entry_model.dart';

abstract class CommunicationAuditRemoteDataSource {
  Future<List<CommunicationAuditEntryEntity>> getEntries();

  Future<void> saveEntry(CommunicationAuditEntryEntity entry);
}

class CommunicationAuditRemoteDataSourceImpl
    implements CommunicationAuditRemoteDataSource {
  const CommunicationAuditRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<CommunicationAuditEntryEntity>> getEntries() async {
    final snapshot = await _service
        .collection(FirestorePaths.communicationAuditLogs)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => CommunicationAuditEntryModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveEntry(CommunicationAuditEntryEntity entry) {
    return _service
        .collection(FirestorePaths.communicationAuditLogs)
        .doc(entry.id)
        .set(CommunicationAuditEntryModel.fromEntity(entry).toMap());
  }
}
