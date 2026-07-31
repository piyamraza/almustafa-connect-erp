import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'authentication_event.dart';
import 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc({
    required this._loginUseCase,
    required this._logoutUseCase,
    required this._forgotPasswordUseCase,
    required this._getCurrentUserUseCase,
  }) : super(const AuthenticationInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<CheckAuthenticationRequested>(_onCheckAuthenticationRequested);
    on<AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
  }

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationLoading());

    try {
      final credential = await _loginUseCase(
        email: event.email,
        password: event.password,
      );
      final user = credential.user;

      if (user != null) {
        emit(Authenticated(user: user));
      } else {
        emit(
          const AuthenticationFailure(message: 'Unable to authenticate user.'),
        );
      }
    } catch (e) {
      emit(AuthenticationFailure(message: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationLoading());

    try {
      await _logoutUseCase();

      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthenticationFailure(message: e.toString()));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationLoading());

    try {
      await _forgotPasswordUseCase(email: event.email);

      emit(const PasswordResetEmailSent());
    } catch (e) {
      emit(AuthenticationFailure(message: e.toString()));
    }
  }

  Future<void> _onCheckAuthenticationRequested(
    CheckAuthenticationRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    final user = _getCurrentUserUseCase();

    if (user != null) {
      emit(Authenticated(user: user));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onAuthenticationStatusChanged(
    AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    add(const CheckAuthenticationRequested());
  }
}
