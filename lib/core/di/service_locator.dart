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
import '../../features/students/domain/usecases/get_students_by_class_and_section.dart';
import '../../features/students/domain/usecases/get_student_by_id.dart';
import '../../features/students/presentation/bloc/student_bloc.dart';

import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance_by_student.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/domain/usecases/generate_attendance_report.dart';
import '../../features/attendance/presentation/bloc/attendance_report_bloc.dart';
import '../../features/teachers/data/datasources/teacher_remote_datasource.dart';
import '../../features/teachers/data/repositories/teacher_repository_impl.dart';
import '../../features/teachers/domain/repositories/teacher_repository.dart';
import '../../features/teachers/presentation/bloc/teacher_bloc.dart';
import '../../features/teachers/data/datasources/teacher_assignment_remote_datasource.dart';
import '../../features/teachers/data/repositories/teacher_assignment_repository_impl.dart';
import '../../features/teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../features/teachers/presentation/bloc/teacher_assignment_bloc.dart';
import '../../features/teachers/data/datasources/teacher_attendance_remote_datasource.dart';
import '../../features/teachers/data/repositories/teacher_attendance_repository_impl.dart';
import '../../features/teachers/domain/repositories/teacher_attendance_repository.dart';
import '../../features/teachers/presentation/bloc/teacher_attendance_bloc.dart';
import '../../features/exams/data/datasources/exam_remote_datasource.dart';
import '../../features/exams/data/repositories/exam_repository_impl.dart';
import '../../features/exams/data/datasources/exam_subject_setup_remote_datasource.dart';
import '../../features/exams/data/datasources/exam_mark_remote_datasource.dart';
import '../../features/exams/data/datasources/exam_result_remote_datasource.dart';
import '../../features/exams/data/datasources/grading_rule_remote_datasource.dart';
import '../../features/exams/data/repositories/exam_subject_setup_repository_impl.dart';
import '../../features/exams/data/repositories/exam_mark_repository_impl.dart';
import '../../features/exams/data/repositories/exam_result_repository_impl.dart';
import '../../features/exams/data/repositories/grading_rule_repository_impl.dart';
import '../../features/exams/domain/repositories/exam_repository.dart';
import '../../features/exams/domain/repositories/exam_subject_setup_repository.dart';
import '../../features/exams/domain/repositories/exam_mark_repository.dart';
import '../../features/exams/domain/repositories/exam_result_repository.dart';
import '../../features/exams/domain/repositories/grading_rule_repository.dart';
import '../../features/exams/domain/usecases/create_exam_subject_setups.dart';
import '../../features/exams/domain/usecases/delete_exam_subject_setup.dart';
import '../../features/exams/domain/usecases/generate_exam_subject_setup_id.dart';
import '../../features/exams/domain/usecases/get_exam_subject_setups.dart';
import '../../features/exams/domain/usecases/get_exam_subject_setups_for_exam.dart';
import '../../features/exams/domain/usecases/get_exam_marks.dart';
import '../../features/exams/domain/usecases/save_exam_marks.dart';
import '../../features/exams/domain/usecases/delete_exam_mark.dart';
import '../../features/exams/domain/usecases/generate_exam_results.dart';
import '../../features/exams/domain/usecases/get_exam_marks_for_exam.dart';
import '../../features/exams/domain/usecases/get_exam_results.dart';
import '../../features/exams/domain/usecases/update_exam_result_status.dart';
import '../../features/exams/domain/usecases/update_exam_subject_setup.dart';
import '../../features/exams/domain/usecases/create_exam.dart';
import '../../features/exams/domain/usecases/delete_exam.dart';
import '../../features/exams/domain/usecases/generate_exam_id.dart';
import '../../features/exams/domain/usecases/get_exam_by_id.dart';
import '../../features/exams/domain/usecases/get_exams.dart';
import '../../features/exams/domain/usecases/set_exam_active_status.dart';
import '../../features/exams/domain/usecases/update_exam.dart';
import '../../features/exams/presentation/bloc/exam_bloc.dart';
import '../../features/exams/presentation/bloc/exam_subject_setup_bloc.dart';
import '../../features/exams/presentation/bloc/exam_marks_bloc.dart';
import '../../features/exams/presentation/bloc/exam_results_bloc.dart';
import '../../features/results/domain/usecases/get_published_results.dart';
import '../../features/results/presentation/bloc/results_bloc.dart';
import '../../features/results/presentation/bloc/result_details_bloc.dart';
import '../../features/results/presentation/bloc/report_card_bloc.dart';
import '../../features/results/presentation/bloc/teacher_results_bloc.dart';
import '../../features/academic_structure/data/datasources/academic_structure_remote_datasource.dart';
import '../../features/academic_structure/data/repositories/academic_structure_repository_impl.dart';
import '../../features/academic_structure/domain/repositories/academic_structure_repository.dart';

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

  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );

  sl.registerLazySingleton<TeacherAssignmentRemoteDataSource>(
    () => TeacherAssignmentRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<TeacherAttendanceRemoteDataSource>(
    () => TeacherAttendanceRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<ExamRemoteDataSource>(
    () => ExamRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<ExamSubjectSetupRemoteDataSource>(
    () => ExamSubjectSetupRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<ExamMarkRemoteDataSource>(
    () => ExamMarkRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<ExamResultRemoteDataSource>(
    () => ExamResultRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<GradingRuleRemoteDataSource>(
    () => GradingRuleRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<AcademicStructureRemoteDataSource>(
    () => AcademicStructureRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
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

  sl.registerLazySingleton<TeacherRepository>(
    () => TeacherRepositoryImpl(
      remoteDataSource: sl<TeacherRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<TeacherAssignmentRepository>(
    () => TeacherAssignmentRepositoryImpl(
      remoteDataSource: sl<TeacherAssignmentRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<TeacherAttendanceRepository>(
    () => TeacherAttendanceRepositoryImpl(
      dataSource: sl<TeacherAttendanceRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ExamRepository>(
    () => ExamRepositoryImpl(source: sl<ExamRemoteDataSource>()),
  );
  sl.registerLazySingleton<ExamSubjectSetupRepository>(
    () => ExamSubjectSetupRepositoryImpl(
      source: sl<ExamSubjectSetupRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ExamMarkRepository>(
    () => ExamMarkRepositoryImpl(
      source: sl<ExamMarkRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<ExamResultRepository>(
    () => ExamResultRepositoryImpl(
      source: sl<ExamResultRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GradingRuleRepository>(
    () => GradingRuleRepositoryImpl(
      source: sl<GradingRuleRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<AcademicStructureRepository>(
    () => AcademicStructureRepositoryImpl(
      source: sl<AcademicStructureRemoteDataSource>(),
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

  sl.registerLazySingleton<CreateExam>(
    () => CreateExam(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<UpdateExam>(
    () => UpdateExam(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<DeleteExam>(
    () => DeleteExam(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<GetExams>(
    () => GetExams(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<GetExamById>(
    () => GetExamById(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<SetExamActiveStatus>(
    () => SetExamActiveStatus(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<GenerateExamId>(
    () => GenerateExamId(sl<ExamRepository>()),
  );
  sl.registerLazySingleton<CreateExamSubjectSetups>(
    () => CreateExamSubjectSetups(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<GetExamSubjectSetups>(
    () => GetExamSubjectSetups(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<UpdateExamSubjectSetup>(
    () => UpdateExamSubjectSetup(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<DeleteExamSubjectSetup>(
    () => DeleteExamSubjectSetup(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<GenerateExamSubjectSetupId>(
    () => GenerateExamSubjectSetupId(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<GetExamSubjectSetupsForExam>(
    () => GetExamSubjectSetupsForExam(sl<ExamSubjectSetupRepository>()),
  );
  sl.registerLazySingleton<GetExamMarks>(
    () => GetExamMarks(sl<ExamMarkRepository>()),
  );
  sl.registerLazySingleton<SaveExamMarks>(
    () => SaveExamMarks(sl<ExamMarkRepository>()),
  );
  sl.registerLazySingleton<DeleteExamMark>(
    () => DeleteExamMark(sl<ExamMarkRepository>()),
  );
  sl.registerLazySingleton<GetExamMarksForExam>(
    () => GetExamMarksForExam(sl<ExamMarkRepository>()),
  );
  sl.registerLazySingleton<GetExamResults>(
    () => GetExamResults(sl<ExamResultRepository>()),
  );
  sl.registerLazySingleton<GenerateExamResults>(
    () => GenerateExamResults(
      examRepository: sl<ExamRepository>(),
      subjectSetupRepository: sl<ExamSubjectSetupRepository>(),
      markRepository: sl<ExamMarkRepository>(),
      studentRepository: sl<StudentRepository>(),
      gradingRuleRepository: sl<GradingRuleRepository>(),
      resultRepository: sl<ExamResultRepository>(),
    ),
  );
  sl.registerLazySingleton<UpdateExamResultStatus>(
    () => UpdateExamResultStatus(sl<ExamResultRepository>()),
  );
  sl.registerLazySingleton<GetPublishedResults>(
    () => GetPublishedResults(sl<ExamResultRepository>()),
  );
  sl.registerLazySingleton<GetAttendanceByStudent>(
    () => GetAttendanceByStudent(sl<AttendanceRepository>()),
  );
  sl.registerLazySingleton<GetStudentsByClassAndSection>(
    () => GetStudentsByClassAndSection(sl<StudentRepository>()),
  );
  sl.registerLazySingleton<GetStudentById>(
    () => GetStudentById(sl<StudentRepository>()),
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

  sl.registerLazySingleton<GenerateAttendanceReport>(
    () => GenerateAttendanceReport(sl<AttendanceRepository>()),
  );

  sl.registerFactory<AttendanceReportBloc>(
    () => AttendanceReportBloc(sl<GenerateAttendanceReport>()),
  );

  sl.registerFactory<TeacherBloc>(
    () => TeacherBloc(sl<TeacherRepository>()),
  );
  sl.registerFactory<TeacherAssignmentBloc>(
    () => TeacherAssignmentBloc(sl<TeacherAssignmentRepository>()),
  );
  sl.registerFactory<TeacherAttendanceBloc>(
    () => TeacherAttendanceBloc(sl<TeacherAttendanceRepository>()),
  );
  sl.registerFactory<ExamBloc>(
    () => ExamBloc(
      getExams: sl<GetExams>(),
      createExam: sl<CreateExam>(),
      updateExam: sl<UpdateExam>(),
      deleteExam: sl<DeleteExam>(),
      setExamActiveStatus: sl<SetExamActiveStatus>(),
    ),
  );
  sl.registerFactory<ExamSubjectSetupBloc>(
    () => ExamSubjectSetupBloc(
      getSetups: sl<GetExamSubjectSetups>(),
      createSetups: sl<CreateExamSubjectSetups>(),
      updateSetup: sl<UpdateExamSubjectSetup>(),
      deleteSetup: sl<DeleteExamSubjectSetup>(),
      examRepository: sl<ExamRepository>(),
      academicStructureRepository: sl<AcademicStructureRepository>(),
    ),
  );
  sl.registerFactory<ExamMarksBloc>(
    () => ExamMarksBloc(
      getExams: sl<GetExams>(),
      getSubjectSetupsForExam: sl<GetExamSubjectSetupsForExam>(),
      getStudentsByClassAndSection: sl<GetStudentsByClassAndSection>(),
      getExamMarks: sl<GetExamMarks>(),
      saveExamMarks: sl<SaveExamMarks>(),
      deleteExamMark: sl<DeleteExamMark>(),
    ),
  );
  sl.registerFactory<ExamResultsBloc>(
    () => ExamResultsBloc(
      getExams: sl<GetExams>(),
      getSubjectSetupsForExam: sl<GetExamSubjectSetupsForExam>(),
      getExamResults: sl<GetExamResults>(),
      generateExamResults: sl<GenerateExamResults>(),
      updateResultStatus: sl<UpdateExamResultStatus>(),
    ),
  );
  sl.registerFactory<ResultsBloc>(
    () => ResultsBloc(getPublishedResults: sl<GetPublishedResults>()),
  );
  sl.registerFactory<ResultDetailsBloc>(
    () => ResultDetailsBloc(getStudentById: sl<GetStudentById>()),
  );
  sl.registerFactory<ReportCardBloc>(
    () => ReportCardBloc(
      getStudentById: sl<GetStudentById>(),
      getAttendanceByStudent: sl<GetAttendanceByStudent>(),
    ),
  );
  sl.registerFactory<TeacherResultsBloc>(
    () => TeacherResultsBloc(
      teacherRepository: sl<TeacherRepository>(),
      assignmentRepository: sl<TeacherAssignmentRepository>(),
      getPublishedResults: sl<GetPublishedResults>(),
    ),
  );
}
