import '../repositories/authentication_repository.dart';

class LogoutUseCase {
  LogoutUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call() {
    return _repository.signOut();
  }
}