import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthenticationState extends Equatable {
  const AuthenticationState();

  @override
  List<Object?> get props => [];
}

final class AuthenticationInitial extends AuthenticationState {
  const AuthenticationInitial();
}

final class AuthenticationLoading extends AuthenticationState {
  const AuthenticationLoading();
}

final class Authenticated extends AuthenticationState {
  const Authenticated({
    required this.user,
  });

  final User user;

  @override
  List<Object?> get props => [
        user,
      ];
}

final class Unauthenticated extends AuthenticationState {
  const Unauthenticated();
}

final class PasswordResetEmailSent extends AuthenticationState {
  const PasswordResetEmailSent();
}

final class AuthenticationFailure extends AuthenticationState {
  const AuthenticationFailure({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [
        message,
      ];
}