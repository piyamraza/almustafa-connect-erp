import 'package:equatable/equatable.dart';

sealed class SecurityEvent extends Equatable {
  const SecurityEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSecurityData extends SecurityEvent {
  const LoadSecurityData(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ChangePasswordRequested extends SecurityEvent {
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

class RevokeSessionRequested extends SecurityEvent {
  const RevokeSessionRequested({required this.sessionId, required this.userId});

  final String sessionId;
  final String userId;

  @override
  List<Object?> get props => [sessionId, userId];
}
