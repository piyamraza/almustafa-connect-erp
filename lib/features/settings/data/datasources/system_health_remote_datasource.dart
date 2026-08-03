import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/system_health_entity.dart';

abstract class SystemHealthRemoteDataSource {
  Future<SystemHealthEntity> checkHealth();
  Future<void> writeHealthLog(SystemHealthEntity health);
}

class SystemHealthRemoteDataSourceImpl implements SystemHealthRemoteDataSource {
  const SystemHealthRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestoreService _firestore;
  final FirebaseAuth _auth;

  @override
  Future<SystemHealthEntity> checkHealth() async {
    final now = DateTime.now();
    final collections = <SystemCollectionHealthEntity>[];

    final collectionNames = <String>[
      FirestorePaths.students,
      FirestorePaths.attendance,
      FirestorePaths.homework,
      FirestorePaths.feePayments,
      FirestorePaths.exams,
      FirestorePaths.examResults,
      FirestorePaths.storeItems,
      FirestorePaths.storeSales,
      FirestorePaths.communicationMessages,
      FirestorePaths.systemSettings,
    ];

    var firestoreReachable = true;
    var firestoreError = '';

    for (final name in collectionNames) {
      try {
        final snapshot = await _firestore.collection(name).get();

        collections.add(
          SystemCollectionHealthEntity(
            name: name,
            recordCount: snapshot.docs.length,
            isReachable: true,
          ),
        );
      } catch (error) {
        firestoreReachable = false;
        firestoreError = '$error';

        collections.add(
          SystemCollectionHealthEntity(
            name: name,
            recordCount: 0,
            isReachable: false,
            errorMessage: '$error',
          ),
        );
      }
    }

    final user = _auth.currentUser;
    final app = Firebase.apps.isEmpty ? null : Firebase.app();

    return SystemHealthEntity(
      checkedAt: now,
      firestoreReachable: firestoreReachable,
      authenticated: user != null,
      currentUserId: user?.uid ?? '',
      collections: collections,
      appVersion: '1.0.0',
      buildNumber: '1',
      firebaseProjectId: app?.options.projectId ?? 'Unknown',
      firestoreError: firestoreError,
    );
  }

  @override
  Future<void> writeHealthLog(SystemHealthEntity health) {
    final id = 'health_${health.checkedAt.microsecondsSinceEpoch}';

    return _firestore.collection(FirestorePaths.systemHealthLogs).doc(id).set({
      'id': id,
      'checkedAt': health.checkedAt.toIso8601String(),
      'firestoreReachable': health.firestoreReachable,
      'authenticated': health.authenticated,
      'currentUserId': health.currentUserId,
      'appVersion': health.appVersion,
      'buildNumber': health.buildNumber,
      'firebaseProjectId': health.firebaseProjectId,
      'totalRecords': health.totalRecords,
      'healthyCollections': health.healthyCollections,
      'firestoreError': health.firestoreError,
      'collections': health.collections
          .map(
            (item) => {
              'name': item.name,
              'recordCount': item.recordCount,
              'isReachable': item.isReachable,
              'errorMessage': item.errorMessage,
            },
          )
          .toList(),
      'schemaVersion': 1,
    });
  }
}
