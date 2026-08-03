import '../entities/login_history_entity.dart';
import '../entities/security_session_entity.dart';

abstract class SecurityRepository {
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
