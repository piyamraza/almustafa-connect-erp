import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_security.dart';
import 'security_event.dart';
import 'security_state.dart';

class SecurityBloc extends Bloc<SecurityEvent, SecurityState> {
  SecurityBloc({
    required this._getData,
    required ChangeUserPassword changePassword,
    required this._revokeSession,
  }) : _changePassword = changePassword,
       super(const SecurityInitial()) {
    on<LoadSecurityData>(_load);
    on<ChangePasswordRequested>(_change);
    on<RevokeSessionRequested>(_revoke);
  }

  final GetSecurityData _getData;
  final ChangeUserPassword _changePassword;
  final RevokeUserSession _revokeSession;

  Future<void> _load(
    LoadSecurityData event,
    Emitter<SecurityState> emit,
  ) async {
    emit(const SecurityLoading());
    await _reload(emit, event.userId);
  }

  Future<void> _change(
    ChangePasswordRequested event,
    Emitter<SecurityState> emit,
  ) async {
    final current = state;

    if (current is! SecurityLoaded) {
      return;
    }

    try {
      await _changePassword(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
        confirmPassword: event.confirmPassword,
      );

      await _reload(
        emit,
        current.userId,
        message: 'Password changed successfully.',
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  Future<void> _revoke(
    RevokeSessionRequested event,
    Emitter<SecurityState> emit,
  ) async {
    try {
      await _revokeSession(sessionId: event.sessionId, userId: event.userId);

      await _reload(
        emit,
        event.userId,
        message: 'Session revoked successfully.',
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<SecurityState> emit,
    String userId, {
    String? message,
  }) async {
    try {
      final data = await _getData(userId);

      emit(
        SecurityLoaded(
          sessions: data.sessions,
          loginHistory: data.loginHistory,
          userId: userId,
          message: message,
        ),
      );
    } catch (error) {
      emit(SecurityFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
