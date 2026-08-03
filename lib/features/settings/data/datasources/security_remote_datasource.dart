import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';
import '../models/security_models.dart';

abstract class SecurityRemoteDataSource {
  Future<List<SecuritySessionEntity>> getSessions(String userId);

  Future<List<LoginHistoryEntity>> getLoginHistory(String userId);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  });
}

class SecurityRemoteDataSourceImpl implements SecurityRemoteDataSource {
  const SecurityRemoteDataSourceImpl(this._firestore, this._auth);

  final FirebaseFirestoreService _firestore;
  final FirebaseAuth _auth;

  @override
  Future<List<SecuritySessionEntity>> getSessions(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.activeSessions)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => SecuritySessionModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .where((item) => item.userId == userId)
        .toList();

    values.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));

    return values;
  }

  @override
  Future<List<LoginHistoryEntity>> getLoginHistory(String userId) async {
    final snapshot = await _firestore
        .collection(FirestorePaths.loginHistory)
        .get();

    final values = snapshot.docs
        .map((doc) => LoginHistoryModel.fromMap({...doc.data(), 'id': doc.id}))
        .where((item) => item.userId == userId)
        .toList();

    values.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    return values;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;

    if (user == null || user.email == null) {
      throw StateError('No signed-in user found.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);

    final now = DateTime.now();

    await _firestore
        .collection(FirestorePaths.securityLogs)
        .doc('password_${now.microsecondsSinceEpoch}')
        .set(
          LoginHistoryModel(
            id: 'password_${now.microsecondsSinceEpoch}',
            userId: user.uid,
            activityType: LoginActivityType.passwordChanged,
            occurredAt: now,
            success: true,
            details: 'Password changed by user.',
          ).toMap(),
        );
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  }) async {
    final document = await _firestore
        .collection(FirestorePaths.activeSessions)
        .doc(sessionId)
        .get();

    if (!document.exists) {
      throw StateError('Session was not found.');
    }

    final session = SecuritySessionModel.fromMap({
      ...document.data()!,
      'id': document.id,
    });

    final updated = SecuritySessionModel(
      id: session.id,
      userId: session.userId,
      deviceName: session.deviceName,
      platform: session.platform,
      lastActiveAt: DateTime.now(),
      createdAt: session.createdAt,
      isCurrent: session.isCurrent,
      isRevoked: true,
      ipAddress: session.ipAddress,
      appVersion: session.appVersion,
    );

    await _firestore
        .collection(FirestorePaths.activeSessions)
        .doc(sessionId)
        .set(updated.toMap());

    final now = DateTime.now();

    await _firestore
        .collection(FirestorePaths.securityLogs)
        .doc('revoke_${now.microsecondsSinceEpoch}')
        .set(
          LoginHistoryModel(
            id: 'revoke_${now.microsecondsSinceEpoch}',
            userId: userId,
            activityType: LoginActivityType.sessionRevoked,
            occurredAt: now,
            success: true,
            details: 'Session $sessionId revoked.',
          ).toMap(),
        );
  }
}
