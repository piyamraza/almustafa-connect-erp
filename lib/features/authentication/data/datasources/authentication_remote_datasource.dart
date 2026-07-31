import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/firebase_auth_service.dart';

abstract class AuthenticationRemoteDataSource {
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  User? getCurrentUser();

  Stream<User?> authStateChanges();
}

class AuthenticationRemoteDataSourceImpl
    implements AuthenticationRemoteDataSource {
  AuthenticationRemoteDataSourceImpl({required this._authService});

  final FirebaseAuthService _authService;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _authService.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result;
  }

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _authService.instance.sendPasswordResetEmail(email: email);
  }

  @override
  User? getCurrentUser() {
    return _authService.currentUser;
  }

  @override
  Stream<User?> authStateChanges() {
    return _authService.authStateChanges();
  }
}
