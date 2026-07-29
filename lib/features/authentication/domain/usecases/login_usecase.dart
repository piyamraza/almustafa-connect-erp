import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/authentication_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<UserCredential> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(
      email: email,
      password: password,
    );
  }
}