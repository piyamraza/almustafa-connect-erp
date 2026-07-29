import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/repositories/authentication_repository.dart';
import '../datasources/authentication_remote_datasource.dart';

class AuthenticationRepositoryImpl implements AuthenticationRepository {
  AuthenticationRepositoryImpl({
    required AuthenticationRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AuthenticationRemoteDataSource _remoteDataSource;

  @override
Future<UserCredential> signIn({
  required String email,
  required String password,
}) async {
  print("REPOSITORY: signIn called");

  return await _remoteDataSource.signIn(
    email: email,
    password: password,
  );
}

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) {
    return _remoteDataSource.sendPasswordResetEmail(
      email: email,
    );
  }

  @override
  User? getCurrentUser() {
    return _remoteDataSource.getCurrentUser();
  }

  @override
  Stream<User?> authStateChanges() {
    return _remoteDataSource.authStateChanges();
  }
}