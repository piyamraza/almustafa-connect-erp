import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../constants/firestore_paths.dart';
import '../models/audit_log_model.dart';

class AuditRemoteDataSource {
  AuditRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.auditLogs);

  String generateId() => _collection.doc().id;

  Future<void> save(AuditLogModel log) {
    return _collection.doc(log.id).set(log.toMap());
  }

  Future<List<AuditLogModel>> getLogs({
    String? module,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 200,
  }) async {
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    final values = snapshot.docs
        .map((doc) => AuditLogModel.fromMap(doc.id, doc.data()))
        .where((item) {
          if (module != null && item.module != module) return false;
          if (userId != null && item.userId != userId) return false;
          if (fromDate != null && item.createdAt.isBefore(fromDate)) {
            return false;
          }
          if (toDate != null && item.createdAt.isAfter(toDate)) {
            return false;
          }
          return true;
        })
        .toList();

    return List.unmodifiable(values);
  }
}
