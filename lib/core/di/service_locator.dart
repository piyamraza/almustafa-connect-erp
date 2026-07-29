import 'package:get_it/get_it.dart';

import '../../features/authentication/data/datasources/authentication_remote_datasource.dart';
import '../../features/authentication/data/repositories/authentication_repository_impl.dart';
import '../../features/authentication/domain/repositories/authentication_repository.dart';
import '../../features/authentication/domain/usecases/forgot_password_usecase.dart';
import '../../features/authentication/domain/usecases/get_current_user_usecase.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/logout_usecase.dart';
import '../../features/authentication/presentation/bloc/authentication_bloc.dart';

import '../../features/students/data/datasources/student_remote_datasource.dart';
import '../../features/students/data/repositories/student_repository_impl.dart';
import '../../features/students/domain/repositories/student_repository.dart';
import '../../features/students/presentation/bloc/student_bloc.dart';

import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';

import '../services/firebase_auth_service.dart';
import '../services/firebase_firestore_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // =========================================================
  // Services
  // =========================================================

  sl.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService(),
  );

  sl.registerLazySingleton<FirebaseFirestoreService>(
    () => FirebaseFirestoreService(),
  );

  // =========================================================
  // Data Sources
  // =========================================================

  sl.registerLazySingleton<AuthenticationRemoteDataSource>(
    () => AuthenticationRemoteDataSourceImpl(
      authService: sl<FirebaseAuthService>(),
    ),
  );

  sl.registerLazySingleton<StudentRemoteDataSource>(
    () => StudentRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );

sl.registerLazySingleton<AttendanceRemoteDataSource>(
  () => AttendanceRemoteDataSourceImpl(),
);

  // =========================================================
  // Repositories
  // =========================================================

  sl.registerLazySingleton<AuthenticationRepository>(
    () => AuthenticationRepositoryImpl(
      remoteDataSource: sl<AuthenticationRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(
      remoteDataSource: sl<StudentRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl<AttendanceRemoteDataSource>(),
    ),
  );

  // =========================================================
  // Use Cases
  // =========================================================

  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(
      sl<AuthenticationRepository>(),
    ),
  );

  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(
      sl<AuthenticationRepository>(),
    ),
  );

  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(
      sl<AuthenticationRepository>(),
    ),
  );

  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(
      sl<AuthenticationRepository>(),
    ),
  );

  // =========================================================
  // BLoCs
  // =========================================================

  sl.registerFactory<AuthenticationBloc>(
    () => AuthenticationBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerFactory<StudentBloc>(
    () => StudentBloc(
      sl<StudentRepository>(),
    ),
  );

  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(
      sl<AttendanceRepository>(),
    ),
  );
}