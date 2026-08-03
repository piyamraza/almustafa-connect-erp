import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/authentication_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    final loginEmail = _normaliseLogin(email);
    return _repository.signIn(
      email: loginEmail,
      password: password,
    );
  }

  String _normaliseLogin(String value) {
    final login = value.trim().toLowerCase();
    if (login.contains('@')) return login;

    // Firebase password authentication requires an email internally. Usernames
    // and mobile numbers are stored as safe, synthetic school email addresses.
    final safeLogin = login.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (safeLogin.isEmpty) {
      throw const FormatException(
        'Enter a valid username, mobile number or email address.',
      );
    }
    return '$safeLogin@almustafa.school';
  }
}
