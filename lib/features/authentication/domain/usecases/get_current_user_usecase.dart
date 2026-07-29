import 'package:firebase_auth/firebase_auth.dart';

import '../repositories/authentication_repository.dart';

class GetCurrentUserUseCase {
  GetCurrentUserUseCase(this._repository);

  final AuthenticationRepository _repository;

  User? call() {
    return _repository.getCurrentUser();
  }
}