import 'package:equatable/equatable.dart';

import '../../domain/entities/login_history_entity.dart';
import '../../domain/entities/security_session_entity.dart';

sealed class SecurityState extends Equatable {
  const SecurityState();

  @override
  List<Object?> get props => const [];
}

class SecurityInitial extends SecurityState {
  const SecurityInitial();
}

class SecurityLoading extends SecurityState {
  const SecurityLoading();
}

class SecurityLoaded extends SecurityState {
  const SecurityLoaded({
    required this.sessions,
    required this.loginHistory,
    required this.userId,
    this.processing = false,
    this.message,
  });

  final List<SecuritySessionEntity> sessions;
  final List<LoginHistoryEntity> loginHistory;
  final String userId;
  final bool processing;
  final String? message;

  @override
  List<Object?> get props => [
    sessions,
    loginHistory,
    userId,
    processing,
    message,
  ];
}

class SecurityFailure extends SecurityState {
  const SecurityFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
