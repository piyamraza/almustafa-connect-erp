import '../entities/login_history_entity.dart';
import '../entities/security_session_entity.dart';
import '../repositories/security_repository.dart';

class SecurityData {
  const SecurityData({required this.sessions, required this.loginHistory});

  final List<SecuritySessionEntity> sessions;
  final List<LoginHistoryEntity> loginHistory;
}

class GetSecurityData {
  const GetSecurityData(this._repository);

  final SecurityRepository _repository;

  Future<SecurityData> call(String userId) async {
    final values = await Future.wait<Object>([
      _repository.getSessions(userId),
      _repository.getLoginHistory(userId),
    ]);

    return SecurityData(
      sessions: values[0] as List<SecuritySessionEntity>,
      loginHistory: values[1] as List<LoginHistoryEntity>,
    );
  }
}

class ChangeUserPassword {
  const ChangeUserPassword(this._repository);

  final SecurityRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    if (currentPassword.isEmpty) {
      throw ArgumentError('Current password is required.');
    }

    if (newPassword.length < 8) {
      throw ArgumentError('New password must contain at least 8 characters.');
    }

    if (newPassword != confirmPassword) {
      throw ArgumentError('New password and confirmation do not match.');
    }

    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

class RevokeUserSession {
  const RevokeUserSession(this._repository);

  final SecurityRepository _repository;

  Future<void> call({required String sessionId, required String userId}) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('Session ID is required.');
    }

    return _repository.revokeSession(sessionId: sessionId, userId: userId);
  }
}
