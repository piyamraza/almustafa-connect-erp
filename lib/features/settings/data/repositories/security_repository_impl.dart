import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';
import '../../domain/repositories/security_repository.dart';
import '../datasources/security_remote_datasource.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  const SecurityRepositoryImpl(this._source);

  final SecurityRemoteDataSource _source;

  @override
  Future<List<SecuritySessionEntity>> getSessions(String userId) {
    return _source.getSessions(userId);
  }

  @override
  Future<List<LoginHistoryEntity>> getLoginHistory(String userId) {
    return _source.getLoginHistory(userId);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _source.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> revokeSession({
    required String sessionId,
    required String userId,
  }) {
    return _source.revokeSession(sessionId: sessionId, userId: userId);
  }
}
