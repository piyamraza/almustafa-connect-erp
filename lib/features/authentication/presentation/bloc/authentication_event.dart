import 'package:equatable/equatable.dart';

sealed class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();

  @override
  List<Object?> get props => [];
}

final class LoginRequested extends AuthenticationEvent {
  const LoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [
        email,
        password,
      ];
}

final class LogoutRequested extends AuthenticationEvent {
  const LogoutRequested();
}

final class ForgotPasswordRequested extends AuthenticationEvent {
  const ForgotPasswordRequested({
    required this.email,
  });

  final String email;

  @override
  List<Object?> get props => [
        email,
      ];
}

final class CheckAuthenticationRequested extends AuthenticationEvent {
  const CheckAuthenticationRequested();
}

final class AuthenticationStatusChanged extends AuthenticationEvent {
  const AuthenticationStatusChanged();
}