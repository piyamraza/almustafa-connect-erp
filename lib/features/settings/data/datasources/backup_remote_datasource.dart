import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';
import '../models/backup_models.dart';

abstract class BackupRemoteDataSource {
  Future<List<BackupRecordEntity>> getBackups();
  Future<List<RestoreRequestEntity>> getRestoreRequests();
  Future<void> requestBackup(String requestedBy, String notes);
  Future<void> requestRestore(RestoreRequestEntity request);
}

class BackupRemoteDataSourceImpl implements BackupRemoteDataSource {
  const BackupRemoteDataSourceImpl(this._firestore, this._functions);

  final FirebaseFirestoreService _firestore;
  final FirebaseFunctions _functions;

  @override
  Future<List<BackupRecordEntity>> getBackups() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.backupHistory)
        .get();

    final values = snapshot.docs
        .map((doc) => BackupRecordModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return values;
  }

  @override
  Future<List<RestoreRequestEntity>> getRestoreRequests() async {
    final snapshot = await _firestore
        .collection(FirestorePaths.restoreRequests)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => RestoreRequestModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return values;
  }

  @override
  Future<void> requestBackup(String requestedBy, String notes) async {
    final now = DateTime.now();
    final id = 'backup_${now.microsecondsSinceEpoch}';

    final record = BackupRecordEntity(
      id: id,
      requestedBy: requestedBy,
      requestedAt: now,
      status: BackupStatus.requested,
      notes: notes,
    );

    await _firestore
        .collection(FirestorePaths.backupHistory)
        .doc(id)
        .set(BackupRecordModel.fromEntity(record).toMap());

    final callable = _functions.httpsCallable('createSchoolDataBackup');

    try {
      await callable.call<void>({
        'backupId': id,
        'requestedBy': requestedBy,
        'notes': notes,
      });
    } catch (error) {
      final failed = BackupRecordEntity(
        id: id,
        requestedBy: requestedBy,
        requestedAt: now,
        status: BackupStatus.failed,
        notes: notes,
        errorMessage: '$error',
      );

      await _firestore
          .collection(FirestorePaths.backupHistory)
          .doc(id)
          .set(BackupRecordModel.fromEntity(failed).toMap());

      rethrow;
    }
  }

  @override
  Future<void> requestRestore(RestoreRequestEntity request) {
    return _firestore
        .collection(FirestorePaths.restoreRequests)
        .doc(request.id)
        .set(RestoreRequestModel.fromEntity(request).toMap());
  }
}
