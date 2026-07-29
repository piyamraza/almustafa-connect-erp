import '../repositories/authentication_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repository);

  final AuthenticationRepository _repository;

  Future<void> call({
    required String email,
  }) {
    return _repository.sendPasswordResetEmail(
      email: email,
    );
  }
}