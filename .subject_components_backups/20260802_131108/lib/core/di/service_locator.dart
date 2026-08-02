import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/academic_structure/data/datasources/academic_structure_remote_datasource.dart';
import '../../features/academic_structure/data/repositories/academic_structure_repository_impl.dart';
import '../../features/academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/generate_attendance_report.dart';
import '../../features/attendance/domain/usecases/get_attendance_by_student.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../../features/attendance/presentation/bloc/attendance_report_bloc.dart';
import '../../features/authentication/data/datasources/authentication_remote_datasource.dart';
import '../../features/authentication/data/repositories/authentication_repository_impl.dart';
import '../../features/authentication/domain/repositories/authentication_repository.dart';
import '../../features/authentication/domain/usecases/forgot_password_usecase.dart';
import '../../features/authentication/domain/usecases/get_current_user_usecase.dart';
import '../../features/authentication/domain/usecases/login_usecase.dart';
import '../../features/authentication/domain/usecases/logout_usecase.dart';
import '../../features/authentication/presentation/bloc/authentication_bloc.dart';
import '../../features/exams/data/datasources/exam_mark_remote_datasource.dart';
import '../../features/exams/data/datasources/exam_remote_datasource.dart';
import '../../features/exams/data/datasources/exam_result_remote_datasource.dart';
import '../../features/exams/data/datasources/exam_subject_setup_remote_datasource.dart';
import '../../features/exams/data/datasources/grading_rule_remote_datasource.dart';
import '../../features/exams/data/repositories/exam_mark_repository_impl.dart';
import '../../features/exams/data/services/exam_date_sheet_report_service_impl.dart';
import '../../features/exams/data/repositories/exam_date_sheet_repository_impl.dart';
import '../../features/fees/data/services/fee_report_service_impl.dart';
import '../../features/fees/data/services/fee_document_service_impl.dart';
import '../../features/fees/data/repositories/fee_payment_repository_impl.dart';
import '../../features/fees/data/repositories/additional_charge_repository_impl.dart';
import '../../features/fees/data/repositories/student_additional_charge_due_repository_impl.dart';
import '../../features/fees/data/repositories/monthly_fee_due_repository_impl.dart';
import '../../features/fees/data/repositories/student_fee_assignment_repository_impl.dart';
import '../../features/fees/data/repositories/fee_structure_repository_impl.dart';
import '../../features/exams/data/repositories/exam_repository_impl.dart';
import '../../features/exams/data/repositories/exam_result_repository_impl.dart';
import '../../features/exams/data/repositories/exam_subject_setup_repository_impl.dart';
import '../../features/exams/data/repositories/grading_rule_repository_impl.dart';
import '../../features/exams/domain/repositories/exam_mark_repository.dart';
import '../../features/exams/domain/services/exam_date_sheet_report_service.dart';
import '../../features/exams/domain/repositories/exam_date_sheet_repository.dart';
import '../../features/exams/domain/usecases/generate_exam_date_sheet_options.dart';
import '../../features/exams/domain/usecases/validate_exam_date_sheet.dart';
import '../../features/fees/domain/services/fee_report_service.dart';
import '../../features/fees/domain/services/fee_document_service.dart';
import '../../features/fees/domain/repositories/fee_payment_repository.dart';
import '../../features/fees/domain/repositories/additional_charge_repository.dart';
import '../../features/fees/domain/repositories/student_additional_charge_due_repository.dart';
import '../../features/fees/domain/services/additional_charge_generation_service.dart';
import '../../features/fees/domain/repositories/monthly_fee_due_repository.dart';
import '../../features/fees/domain/usecases/generate_monthly_fees.dart';
import '../../features/fees/domain/repositories/student_fee_assignment_repository.dart';
import '../../features/fees/domain/repositories/fee_structure_repository.dart';
import '../../features/exams/domain/repositories/exam_repository.dart';
import '../../features/exams/domain/repositories/exam_result_repository.dart';
import '../../features/exams/domain/repositories/exam_subject_setup_repository.dart';
import '../../features/exams/domain/repositories/grading_rule_repository.dart';
import '../../features/exams/domain/usecases/create_exam.dart';
import '../../features/exams/domain/usecases/create_exam_subject_setups.dart';
import '../../features/exams/domain/usecases/delete_exam.dart';
import '../../features/exams/domain/usecases/delete_exam_mark.dart';
import '../../features/exams/domain/usecases/delete_exam_subject_setup.dart';
import '../../features/exams/domain/usecases/generate_exam_id.dart';
import '../../features/exams/domain/usecases/generate_exam_results.dart';
import '../../features/exams/domain/usecases/generate_exam_subject_setup_id.dart';
import '../../features/exams/domain/usecases/get_exam_by_id.dart';
import '../../features/exams/domain/usecases/get_exam_marks.dart';
import '../../features/exams/domain/usecases/get_exam_marks_for_exam.dart';
import '../../features/exams/domain/usecases/get_exam_results.dart';
import '../../features/exams/domain/usecases/get_exam_subject_setups.dart';
import '../../features/exams/domain/usecases/get_exam_subject_setups_for_exam.dart';
import '../../features/exams/domain/usecases/get_exams.dart';
import '../../features/exams/domain/usecases/save_exam_marks.dart';
import '../../features/exams/domain/usecases/set_exam_active_status.dart';
import '../../features/exams/domain/usecases/update_exam.dart';
import '../../features/exams/domain/usecases/update_exam_result_status.dart';
import '../../features/exams/domain/usecases/update_exam_subject_setup.dart';
import '../../features/exams/presentation/bloc/exam_date_sheet_workflow_bloc.dart';
import '../../features/exams/presentation/bloc/exam_date_sheet_report_bloc.dart';
import '../../features/exams/presentation/bloc/exam_date_sheet_generator_bloc.dart';
import '../../features/exams/presentation/bloc/exam_date_sheet_bloc.dart';
import '../../features/fees/presentation/bloc/fee_reports_bloc.dart';
import '../../features/fees/presentation/bloc/fee_document_bloc.dart';
import '../../features/fees/presentation/bloc/fee_collection_bloc.dart';
import '../../features/fees/presentation/bloc/additional_charges_bloc.dart';
import '../../features/fees/presentation/bloc/monthly_fee_generation_bloc.dart';
import '../../features/fees/presentation/bloc/student_fee_assignment_bloc.dart';
import '../../features/fees/presentation/bloc/fee_structure_bloc.dart';
import '../../features/exams/presentation/bloc/exam_bloc.dart';
import '../../features/exams/presentation/bloc/exam_marks_bloc.dart';
import '../../features/exams/presentation/bloc/exam_results_bloc.dart';
import '../../features/exams/presentation/bloc/exam_subject_setup_bloc.dart';
import '../../features/results/data/services/results_export_service_impl.dart';
import '../../features/results/domain/services/results_export_service.dart';
import '../../features/results/domain/usecases/get_published_results.dart';
import '../../features/results/domain/usecases/get_result_archive.dart';
import '../../features/results/domain/usecases/get_results_analytics_data.dart';
import '../../features/results/presentation/bloc/report_card_bloc.dart';
import '../../features/results/presentation/bloc/result_archive_bloc.dart';
import '../../features/results/presentation/bloc/result_details_bloc.dart';
import '../../features/results/presentation/bloc/results_analytics_bloc.dart';
import '../../features/results/presentation/bloc/results_bloc.dart';
import '../../features/results/presentation/bloc/results_export_bloc.dart';
import '../../features/results/presentation/bloc/teacher_results_bloc.dart';
import '../../features/staff/data/datasources/staff_attendance_remote_datasource.dart';
import '../../features/staff/data/datasources/staff_leave_remote_datasource.dart';
import '../../features/staff/data/datasources/staff_salary_remote_datasource.dart';
import '../../features/staff/data/datasources/staff_remote_datasource.dart';
import '../../features/staff/data/repositories/staff_attendance_repository_impl.dart';
import '../../features/staff/data/repositories/staff_leave_repository_impl.dart';
import '../../features/staff/data/repositories/staff_salary_repository_impl.dart';
import '../../features/staff/data/repositories/staff_repository_impl.dart';
import '../../features/staff/domain/repositories/staff_attendance_repository.dart';
import '../../features/staff/domain/repositories/staff_leave_repository.dart';
import '../../features/staff/domain/repositories/staff_salary_repository.dart';
import '../../features/staff/domain/repositories/staff_repository.dart';
import '../../features/staff/domain/usecases/add_staff.dart';
import '../../features/staff/domain/usecases/delete_staff.dart';
import '../../features/staff/domain/usecases/generate_staff_id.dart';
import '../../features/staff/domain/usecases/delete_staff_leave.dart';
import '../../features/staff/domain/usecases/get_pending_staff_leaves.dart';
import '../../features/staff/domain/usecases/get_staff_leaves_by_date_range.dart';
import '../../features/staff/domain/usecases/get_staff_leaves_by_staff.dart';
import '../../features/staff/domain/usecases/save_staff_leave.dart';
import '../../features/staff/domain/usecases/update_staff_leave_status.dart';
import '../../features/staff/domain/usecases/generate_staff_monthly_salaries.dart';
import '../../features/staff/domain/usecases/get_staff_salaries_by_month.dart';
import '../../features/staff/domain/usecases/get_staff_salary_by_staff.dart';
import '../../features/staff/domain/usecases/get_staff.dart';
import '../../features/staff/domain/usecases/get_staff_attendance_by_date.dart';
import '../../features/staff/domain/usecases/get_staff_attendance_by_date_range.dart';
import '../../features/staff/domain/usecases/get_staff_attendance_by_staff.dart';
import '../../features/staff/domain/usecases/save_staff_attendance.dart';
import '../../features/staff/domain/usecases/save_staff_salary.dart';
import '../../features/staff/domain/usecases/update_staff_salary_payment_status.dart';
import '../../features/staff/domain/usecases/toggle_staff_status.dart';
import '../../features/staff/domain/usecases/update_staff.dart';
import '../../features/staff/presentation/bloc/staff_attendance_bloc.dart';
import '../../features/staff/presentation/bloc/staff_leave_bloc.dart';
import '../../features/staff/presentation/bloc/staff_salary_bloc.dart';
import '../../features/staff/presentation/bloc/staff_bloc.dart';
import '../../features/students/data/datasources/student_remote_datasource.dart';
import '../../features/students/data/repositories/student_repository_impl.dart';
import '../../features/students/domain/repositories/student_repository.dart';
import '../../features/students/domain/usecases/get_student_by_id.dart';
import '../../features/students/domain/usecases/get_students_by_class_and_section.dart';
import '../../features/students/presentation/bloc/student_bloc.dart';
import '../../features/timetable/data/services/timetable_report_export_service_impl.dart';
import '../../features/timetable/data/repositories/teacher_availability_repository_impl.dart';
import '../../features/timetable/data/datasources/timetable_remote_datasource.dart';
import '../../features/timetable/data/repositories/timetable_repository_impl.dart';
import '../../features/timetable/domain/services/timetable_report_export_service.dart';
import '../../features/timetable/domain/repositories/teacher_availability_repository.dart';
import '../../features/timetable/domain/repositories/timetable_repository.dart';
import '../../features/timetable/domain/usecases/apply_manual_timetable_changes.dart';
import '../../features/timetable/domain/usecases/delete_class_timetable_entry.dart';
import '../../features/timetable/domain/usecases/get_class_timetable.dart';
import '../../features/timetable/domain/usecases/save_class_timetable_entry.dart';
import '../../features/timetable/domain/usecases/get_day_timetable.dart';
import '../../features/timetable/domain/usecases/generate_auto_timetable.dart';
import '../../features/timetable/domain/usecases/generate_timetable_report.dart';
import '../../features/timetable/domain/usecases/get_teacher_workloads.dart';
import '../../features/timetable/domain/usecases/get_teacher_timetable.dart';
import '../../features/timetable/domain/usecases/get_timetable_configuration.dart';
import '../../features/timetable/domain/usecases/manage_timetable_versions.dart';
import '../../features/timetable/domain/usecases/save_timetable_configuration.dart';
import '../../features/timetable/presentation/bloc/auto_timetable_bloc.dart';
import '../../features/timetable/presentation/bloc/class_timetable_bloc.dart';
import '../../features/timetable/presentation/bloc/day_timetable_bloc.dart';
import '../../features/timetable/presentation/bloc/teacher_availability_bloc.dart';
import '../../features/timetable/presentation/bloc/timetable_version_bloc.dart';
import '../../features/timetable/presentation/bloc/timetable_report_bloc.dart';
import '../../features/timetable/presentation/bloc/teacher_workload_bloc.dart';
import '../../features/timetable/presentation/bloc/manual_timetable_bloc.dart';
import '../../features/timetable/presentation/bloc/teacher_timetable_bloc.dart';
import '../../features/timetable/presentation/bloc/timetable_configuration_bloc.dart';
import '../../features/teachers/data/datasources/teacher_assignment_remote_datasource.dart';
import '../../features/teachers/data/datasources/teacher_attendance_remote_datasource.dart';
import '../../features/teachers/data/datasources/teacher_remote_datasource.dart';
import '../../features/teachers/data/repositories/teacher_assignment_repository_impl.dart';
import '../../features/teachers/data/repositories/teacher_attendance_repository_impl.dart';
import '../../features/teachers/data/repositories/teacher_repository_impl.dart';
import '../../features/teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../features/teachers/domain/repositories/teacher_attendance_repository.dart';
import '../../features/teachers/domain/repositories/teacher_repository.dart';
import '../../features/teachers/presentation/bloc/teacher_assignment_bloc.dart';
import '../../features/teachers/presentation/bloc/teacher_attendance_bloc.dart';
import '../../features/teachers/presentation/bloc/teacher_bloc.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_firestore_service.dart';

import '../../features/academic_calendar/data/services/academic_calendar_policy_service_impl.dart';
import '../../features/academic_calendar/data/repositories/academic_year_config_repository_impl.dart';
import '../../features/academic_calendar/data/repositories/academic_calendar_repository_impl.dart';
import '../../features/academic_calendar/domain/services/academic_calendar_policy_service.dart';
import '../../features/academic_calendar/domain/repositories/academic_year_config_repository.dart';
import '../../features/academic_calendar/domain/usecases/validate_academic_calendar.dart';
import '../../features/academic_calendar/domain/usecases/save_academic_year_wizard.dart';
import '../../features/academic_calendar/domain/repositories/academic_calendar_repository.dart';
import '../../features/academic_calendar/presentation/bloc/academic_calendar_validation_bloc.dart';
import '../../features/academic_calendar/presentation/bloc/academic_year_wizard_bloc.dart';
import '../../features/academic_calendar/presentation/bloc/academic_calendar_bloc.dart';

import '../../features/homework/data/repositories/homework_repository_impl.dart';
import '../../features/homework/domain/repositories/homework_repository.dart';
import '../../features/homework/presentation/bloc/homework_bloc.dart';

import 'package:firebase_storage/firebase_storage.dart';
import '../../features/homework/data/services/homework_attachment_service_impl.dart';
import '../../features/homework/domain/services/homework_attachment_service.dart';

import '../../features/homework/data/repositories/homework_submission_repository_impl.dart';
import '../../features/homework/domain/repositories/homework_submission_repository.dart';
import '../../features/homework/presentation/bloc/homework_submission_bloc.dart';

import '../../features/notices/data/repositories/notice_repository_impl.dart';
import '../../features/notices/domain/repositories/notice_repository.dart';
import '../../features/notices/presentation/bloc/notice_bloc.dart';

import '../../features/notices/data/repositories/notice_receipt_repository_impl.dart';
import '../../features/notices/domain/repositories/notice_receipt_repository.dart';
import '../../features/notices/data/services/notice_attachment_service_impl.dart';
import '../../features/notices/domain/services/notice_attachment_service.dart';
import '../../features/notices/data/services/notice_delivery_service_impl.dart';
import '../../features/notices/domain/services/notice_delivery_service.dart';
import '../../features/notices/presentation/bloc/notice_receipt_bloc.dart';

import '../../features/parent_portal/data/repositories/parent_portal_repository_impl.dart';
import '../../features/parent_portal/domain/repositories/parent_portal_repository.dart';
import '../../features/parent_portal/presentation/bloc/parent_portal_bloc.dart';

import '../../features/parent_portal/data/services/parent_academic_service_impl.dart';
import '../../features/parent_portal/domain/services/parent_academic_service.dart';
import '../../features/parent_portal/presentation/bloc/parent_academic_bloc.dart';

import '../../features/parent_portal/data/services/parent_communication_service_impl.dart';
import '../../features/parent_portal/domain/services/parent_communication_service.dart';
import '../../features/parent_portal/presentation/bloc/parent_communication_bloc.dart';

import '../../features/parent_portal/data/repositories/parent_notification_repository_impl.dart';
import '../../features/parent_portal/domain/repositories/parent_notification_repository.dart';
import '../../features/parent_portal/data/services/parent_timeline_service_impl.dart';
import '../../features/parent_portal/domain/services/parent_timeline_service.dart';
import '../../features/parent_portal/presentation/bloc/parent_notification_bloc.dart';

import '../../features/access_control/data/repositories/app_role_repository_impl.dart';
import '../../features/access_control/domain/repositories/app_role_repository.dart';
import '../../features/access_control/presentation/bloc/app_role_bloc.dart';

import '../../features/access_control/data/repositories/user_role_assignment_repository_impl.dart';
import '../../features/access_control/domain/repositories/user_role_assignment_repository.dart';
import '../../features/access_control/presentation/bloc/user_role_assignment_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../features/access_control/data/services/access_control_service_impl.dart';
import '../../features/access_control/domain/services/access_control_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // =========================================================
  // Services
  // =========================================================

  sl.registerLazySingleton<FirebaseAuthService>(FirebaseAuthService.new);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);

  sl.registerLazySingleton<FirebaseFirestoreService>(
    FirebaseFirestoreService.new,
  );
  sl.registerLazySingleton<FirebaseFirestore>(
    () => sl<FirebaseFirestoreService>().instance,
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
    AttendanceRemoteDataSourceImpl.new,
  );

  sl.registerLazySingleton<TeacherRemoteDataSource>(
    () => TeacherRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );

  sl.registerLazySingleton<StaffRemoteDataSource>(
    () => StaffRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );

  sl.registerLazySingleton<StaffAttendanceRemoteDataSource>(
    () => StaffAttendanceRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<StaffLeaveRemoteDataSource>(
    () => StaffLeaveRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StaffSalaryRemoteDataSource>(
    () => StaffSalaryRemoteDataSourceImpl(
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
  sl.registerLazySingleton<TimetableRemoteDataSource>(
    () => TimetableRemoteDataSourceImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
    ),
  );
  // Repositories
  // =========================================================

  sl.registerLazySingleton<AuthenticationRepository>(
    () => AuthenticationRepositoryImpl(
      remoteDataSource: sl<AuthenticationRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<StudentRepository>(
    () =>
        StudentRepositoryImpl(remoteDataSource: sl<StudentRemoteDataSource>()),
  );

  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl<AttendanceRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<TeacherRepository>(
    () =>
        TeacherRepositoryImpl(remoteDataSource: sl<TeacherRemoteDataSource>()),
  );

  sl.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(remoteDataSource: sl<StaffRemoteDataSource>()),
  );

  sl.registerLazySingleton<StaffAttendanceRepository>(
    () => StaffAttendanceRepositoryImpl(
      remoteDataSource: sl<StaffAttendanceRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<StaffLeaveRepository>(
    () => StaffLeaveRepositoryImpl(sl<StaffLeaveRemoteDataSource>()),
  );
  sl.registerLazySingleton<StaffSalaryRepository>(
    () => StaffSalaryRepositoryImpl(
      remoteDataSource: sl<StaffSalaryRemoteDataSource>(),
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

  sl.registerLazySingleton<ValidateExamDateSheet>(ValidateExamDateSheet.new);

  sl.registerLazySingleton<GenerateExamDateSheetOptions>(
    () => GenerateExamDateSheetOptions(
      sl<AcademicStructureRepository>(),
      sl<TeacherAssignmentRepository>(),
      sl<ExamDateSheetRepository>(),
      sl<ValidateExamDateSheet>(),
    ),
  );
  sl.registerLazySingleton<ExamDateSheetReportService>(
    ExamDateSheetReportServiceImpl.new,
  );
  sl.registerLazySingleton<ExamDateSheetRepository>(
    () => ExamDateSheetRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<FeeReportService>(FeeReportServiceImpl.new);
  sl.registerLazySingleton<FeeDocumentService>(FeeDocumentServiceImpl.new);
  sl.registerLazySingleton<FeePaymentRepository>(
    () => FeePaymentRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<MonthlyFeeDueRepository>(
    () => MonthlyFeeDueRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<AdditionalChargeRepository>(
    () => AdditionalChargeRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StudentAdditionalChargeDueRepository>(
    () => StudentAdditionalChargeDueRepositoryImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<AdditionalChargeGenerationService>(
    () => AdditionalChargeGenerationService(
      sl<StudentRepository>(),
      sl<AdditionalChargeRepository>(),
      sl<StudentAdditionalChargeDueRepository>(),
    ),
  );

  sl.registerLazySingleton<GenerateMonthlyFees>(
    () => GenerateMonthlyFees(
      sl<StudentFeeAssignmentRepository>(),
      sl<MonthlyFeeDueRepository>(),
    ),
  );
  sl.registerLazySingleton<StudentFeeAssignmentRepository>(
    () => StudentFeeAssignmentRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<FeeStructureRepository>(
    () => FeeStructureRepositoryImpl(sl<FirebaseFirestoreService>()),
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
    () => ExamMarkRepositoryImpl(source: sl<ExamMarkRemoteDataSource>()),
  );

  sl.registerLazySingleton<ExamResultRepository>(
    () => ExamResultRepositoryImpl(source: sl<ExamResultRemoteDataSource>()),
  );

  sl.registerLazySingleton<GradingRuleRepository>(
    () => GradingRuleRepositoryImpl(source: sl<GradingRuleRemoteDataSource>()),
  );
  sl.registerLazySingleton<HomeworkAttachmentService>(
    () => HomeworkAttachmentServiceImpl(sl<FirebaseStorage>()),
  );
  sl.registerLazySingleton<AccessControlService>(
    () => AccessControlServiceImpl(
      sl<FirebaseAuth>(),
      sl<UserRoleAssignmentRepository>(),
      sl<AppRoleRepository>(),
    ),
  );
  sl.registerLazySingleton<UserRoleAssignmentRepository>(
    () => UserRoleAssignmentRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<AppRoleRepository>(
    () => AppRoleRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<ParentNotificationRepository>(
    () => ParentNotificationRepositoryImpl(sl<FirebaseFirestoreService>()),
  );

  sl.registerLazySingleton<ParentTimelineService>(
    () => ParentTimelineServiceImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ParentCommunicationService>(
    () => ParentCommunicationServiceImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ParentAcademicService>(
    () => ParentAcademicServiceImpl(sl<FirebaseFirestore>()),
  );
  sl.registerLazySingleton<ParentPortalRepository>(
    () => ParentPortalRepositoryImpl(
      sl<FirebaseFirestoreService>(),
      sl<StudentRepository>(),
    ),
  );
  sl.registerLazySingleton<NoticeReceiptRepository>(
    () => NoticeReceiptRepositoryImpl(sl<FirebaseFirestoreService>()),
  );

  sl.registerLazySingleton<NoticeAttachmentService>(
    () => NoticeAttachmentServiceImpl(sl<FirebaseStorage>()),
  );

  sl.registerLazySingleton<NoticeDeliveryService>(
    () => NoticeDeliveryServiceImpl(sl<NoticeRepository>()),
  );
  sl.registerLazySingleton<NoticeRepository>(
    () => NoticeRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<HomeworkSubmissionRepository>(
    () => HomeworkSubmissionRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<HomeworkRepository>(
    () => HomeworkRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<AcademicCalendarPolicyService>(
    () => AcademicCalendarPolicyServiceImpl(
      sl<AcademicYearConfigRepository>(),
      sl<AcademicCalendarRepository>(),
    ),
  );
  sl.registerLazySingleton<AcademicYearConfigRepository>(
    () => AcademicYearConfigRepositoryImpl(sl<FirebaseFirestoreService>()),
  );

  sl.registerLazySingleton<ValidateAcademicCalendar>(
    () => ValidateAcademicCalendar(
      sl<AcademicCalendarRepository>(),
      sl<AcademicYearConfigRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveAcademicYearWizard>(
    () => SaveAcademicYearWizard(
      sl<AcademicYearConfigRepository>(),
      sl<AcademicCalendarRepository>(),
    ),
  );
  sl.registerLazySingleton<AcademicCalendarRepository>(
    () => AcademicCalendarRepositoryImpl(sl<FirebaseFirestoreService>()),
  );

  sl.registerLazySingleton<AcademicStructureRepository>(
    () => AcademicStructureRepositoryImpl(
      source: sl<AcademicStructureRemoteDataSource>(),
    ),
  );

  sl.registerLazySingleton<TeacherAvailabilityRepository>(
    () => TeacherAvailabilityRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<TimetableRepository>(
    () => TimetableRepositoryImpl(sl<TimetableRemoteDataSource>()),
  );
  sl.registerLazySingleton<TimetableReportExportService>(
    TimetableReportExportServiceImpl.new,
  );
  sl.registerLazySingleton<ResultsExportService>(ResultsExportServiceImpl.new);

  // =========================================================
  // Use Cases
  // =========================================================

  sl.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(sl<AuthenticationRepository>()),
  );

  sl.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(sl<AuthenticationRepository>()),
  );

  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(sl<AuthenticationRepository>()),
  );

  sl.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl<AuthenticationRepository>()),
  );

  sl.registerLazySingleton<GetResultArchive>(
    () => GetResultArchive(sl<GetPublishedResults>()),
  );

  sl.registerLazySingleton<CreateExam>(() => CreateExam(sl<ExamRepository>()));

  sl.registerLazySingleton<UpdateExam>(() => UpdateExam(sl<ExamRepository>()));

  sl.registerLazySingleton<DeleteExam>(() => DeleteExam(sl<ExamRepository>()));

  sl.registerLazySingleton<GetExams>(() => GetExams(sl<ExamRepository>()));

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

  sl.registerLazySingleton<GetResultsAnalyticsData>(
    () => GetResultsAnalyticsData(
      getPublishedResults: sl<GetPublishedResults>(),
      getSubjectSetups: sl<GetExamSubjectSetups>(),
    ),
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

  sl.registerLazySingleton<GetStaff>(() => GetStaff(sl<StaffRepository>()));

  sl.registerLazySingleton<AddStaff>(() => AddStaff(sl<StaffRepository>()));

  sl.registerLazySingleton<UpdateStaff>(
    () => UpdateStaff(sl<StaffRepository>()),
  );

  sl.registerLazySingleton<DeleteStaff>(
    () => DeleteStaff(sl<StaffRepository>()),
  );

  sl.registerLazySingleton<ToggleStaffStatus>(
    () => ToggleStaffStatus(sl<StaffRepository>()),
  );

  sl.registerLazySingleton<GenerateStaffId>(
    () => GenerateStaffId(sl<StaffRepository>()),
  );

  sl.registerLazySingleton<GetStaffAttendanceByDate>(
    () => GetStaffAttendanceByDate(sl<StaffAttendanceRepository>()),
  );

  sl.registerLazySingleton<GetStaffAttendanceByStaff>(
    () => GetStaffAttendanceByStaff(sl<StaffAttendanceRepository>()),
  );

  sl.registerLazySingleton<GetStaffAttendanceByDateRange>(
    () => GetStaffAttendanceByDateRange(sl<StaffAttendanceRepository>()),
  );

  sl.registerLazySingleton<SaveStaffAttendance>(
    () => SaveStaffAttendance(sl<StaffAttendanceRepository>()),
  );

  // =========================================================
  sl.registerLazySingleton<GetStaffLeavesByDateRange>(
    () => GetStaffLeavesByDateRange(sl<StaffLeaveRepository>()),
  );

  sl.registerLazySingleton<GetStaffLeavesByStaff>(
    () => GetStaffLeavesByStaff(sl<StaffLeaveRepository>()),
  );

  sl.registerLazySingleton<GetPendingStaffLeaves>(
    () => GetPendingStaffLeaves(sl<StaffLeaveRepository>()),
  );

  sl.registerLazySingleton<SaveStaffLeave>(
    () => SaveStaffLeave(sl<StaffLeaveRepository>()),
  );

  sl.registerLazySingleton<DeleteStaffLeave>(
    () => DeleteStaffLeave(sl<StaffLeaveRepository>()),
  );

  sl.registerLazySingleton<UpdateStaffLeaveStatus>(
    () => UpdateStaffLeaveStatus(
      sl<StaffLeaveRepository>(),
      sl<StaffAttendanceRepository>(),
    ),
  );
  sl.registerLazySingleton<GetStaffSalariesByMonth>(
    () => GetStaffSalariesByMonth(sl<StaffSalaryRepository>()),
  );

  sl.registerLazySingleton<GetStaffSalaryByStaff>(
    () => GetStaffSalaryByStaff(sl<StaffSalaryRepository>()),
  );

  sl.registerLazySingleton<SaveStaffSalary>(
    () => SaveStaffSalary(sl<StaffSalaryRepository>()),
  );

  sl.registerLazySingleton<UpdateStaffSalaryPaymentStatus>(
    () => UpdateStaffSalaryPaymentStatus(sl<StaffSalaryRepository>()),
  );

  sl.registerLazySingleton<GenerateStaffMonthlySalaries>(
    () => GenerateStaffMonthlySalaries(
      staffRepository: sl<StaffRepository>(),
      attendanceRepository: sl<StaffAttendanceRepository>(),
      leaveRepository: sl<StaffLeaveRepository>(),
      salaryRepository: sl<StaffSalaryRepository>(),
    ),
  );
  sl.registerLazySingleton<GetClassTimetable>(
    () => GetClassTimetable(sl<TimetableRepository>()),
  );

  sl.registerLazySingleton<SaveClassTimetableEntry>(
    () => SaveClassTimetableEntry(sl<TimetableRepository>()),
  );

  sl.registerLazySingleton<ApplyManualTimetableChanges>(
    () => ApplyManualTimetableChanges(sl<TimetableRepository>()),
  );
  sl.registerLazySingleton<DeleteClassTimetableEntry>(
    () => DeleteClassTimetableEntry(sl<TimetableRepository>()),
  );
  sl.registerLazySingleton<GetDayTimetable>(
    () => GetDayTimetable(sl<TimetableRepository>()),
  );
  sl.registerLazySingleton<GenerateAutoTimetable>(
    () => GenerateAutoTimetable(
      sl<TimetableRepository>(),
      sl<AcademicStructureRepository>(),
      sl<TeacherAssignmentRepository>(),
    ),
  );
  sl.registerLazySingleton<GenerateTimetableReport>(
    () => GenerateTimetableReport(
      sl<TimetableRepository>(),
      sl<GetTeacherWorkloads>(),
    ),
  );
  sl.registerLazySingleton<GetTeacherWorkloads>(
    () =>
        GetTeacherWorkloads(sl<TimetableRepository>(), sl<TeacherRepository>()),
  );
  sl.registerLazySingleton<GetTeacherTimetable>(
    () => GetTeacherTimetable(sl<TimetableRepository>()),
  );
  sl.registerLazySingleton<GetTimetableConfiguration>(
    () => GetTimetableConfiguration(sl<TimetableRepository>()),
  );

  sl.registerLazySingleton<ManageTimetableVersions>(
    () => ManageTimetableVersions(sl<TimetableRepository>()),
  );
  sl.registerLazySingleton<SaveTimetableConfiguration>(
    () => SaveTimetableConfiguration(sl<TimetableRepository>()),
  );
  // BLoCs
  // =========================================================
  sl.registerFactory<UserRoleAssignmentBloc>(
    () => UserRoleAssignmentBloc(sl<UserRoleAssignmentRepository>()),
  );
  sl.registerFactory<AppRoleBloc>(() => AppRoleBloc(sl<AppRoleRepository>()));
  sl.registerFactory<ParentNotificationBloc>(
    () => ParentNotificationBloc(sl<ParentNotificationRepository>()),
  );
  sl.registerFactory<ParentCommunicationBloc>(
    () => ParentCommunicationBloc(sl<ParentCommunicationService>()),
  );
  sl.registerFactory<ParentAcademicBloc>(
    () => ParentAcademicBloc(sl<ParentAcademicService>()),
  );
  sl.registerFactory<ParentPortalBloc>(
    () => ParentPortalBloc(sl<ParentPortalRepository>()),
  );
  sl.registerFactory<NoticeReceiptBloc>(
    () => NoticeReceiptBloc(sl<NoticeReceiptRepository>()),
  );
  sl.registerFactory<NoticeBloc>(() => NoticeBloc(sl<NoticeRepository>()));
  sl.registerFactory<HomeworkSubmissionBloc>(
    () => HomeworkSubmissionBloc(sl<HomeworkSubmissionRepository>()),
  );
  sl.registerFactory<HomeworkBloc>(
    () => HomeworkBloc(sl<HomeworkRepository>()),
  );
  sl.registerFactory<AcademicCalendarValidationBloc>(
    () => AcademicCalendarValidationBloc(sl<ValidateAcademicCalendar>()),
  );
  sl.registerFactory<AcademicYearWizardBloc>(
    () => AcademicYearWizardBloc(
      sl<AcademicYearConfigRepository>(),
      sl<SaveAcademicYearWizard>(),
    ),
  );
  sl.registerFactory<AcademicCalendarBloc>(
    () => AcademicCalendarBloc(sl<AcademicCalendarRepository>()),
  );

  sl.registerFactory<AuthenticationBloc>(
    () => AuthenticationBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerFactory<StudentBloc>(() => StudentBloc(sl<StudentRepository>()));

  sl.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(sl<AttendanceRepository>()),
  );

  sl.registerLazySingleton<GenerateAttendanceReport>(
    () => GenerateAttendanceReport(sl<AttendanceRepository>()),
  );

  sl.registerFactory<AttendanceReportBloc>(
    () => AttendanceReportBloc(sl<GenerateAttendanceReport>()),
  );

  sl.registerFactory<TeacherBloc>(() => TeacherBloc(sl<TeacherRepository>()));

  sl.registerFactory<TeacherAssignmentBloc>(
    () => TeacherAssignmentBloc(sl<TeacherAssignmentRepository>()),
  );

  sl.registerFactory<StaffBloc>(
    () => StaffBloc(
      getStaff: sl<GetStaff>(),
      addStaff: sl<AddStaff>(),
      updateStaff: sl<UpdateStaff>(),
      deleteStaff: sl<DeleteStaff>(),
      toggleStaffStatus: sl<ToggleStaffStatus>(),
    ),
  );

  sl.registerFactory<StaffAttendanceBloc>(
    () => StaffAttendanceBloc(
      getStaffAttendanceByDate: sl<GetStaffAttendanceByDate>(),
      getStaffAttendanceByStaff: sl<GetStaffAttendanceByStaff>(),
      getStaffAttendanceByDateRange: sl<GetStaffAttendanceByDateRange>(),
      saveStaffAttendance: sl<SaveStaffAttendance>(),
    ),
  );
  sl.registerFactory<StaffLeaveBloc>(
    () => StaffLeaveBloc(
      sl<GetStaffLeavesByDateRange>(),
      sl<GetStaffLeavesByStaff>(),
      sl<GetPendingStaffLeaves>(),
      sl<SaveStaffLeave>(),
      sl<DeleteStaffLeave>(),
      sl<UpdateStaffLeaveStatus>(),
    ),
  );
  sl.registerFactory<StaffSalaryBloc>(
    () => StaffSalaryBloc(
      generateStaffMonthlySalaries: sl<GenerateStaffMonthlySalaries>(),
      getStaffSalariesByMonth: sl<GetStaffSalariesByMonth>(),
      getStaffSalaryByStaff: sl<GetStaffSalaryByStaff>(),
      saveStaffSalary: sl<SaveStaffSalary>(),
      updateStaffSalaryPaymentStatus: sl<UpdateStaffSalaryPaymentStatus>(),
    ),
  );

  sl.registerFactory<TeacherAttendanceBloc>(
    () => TeacherAttendanceBloc(sl<TeacherAttendanceRepository>()),
  );

  sl.registerFactory<ExamDateSheetWorkflowBloc>(
    () => ExamDateSheetWorkflowBloc(sl<ExamDateSheetRepository>()),
  );
  sl.registerFactory<ExamDateSheetReportBloc>(
    () => ExamDateSheetReportBloc(sl<ExamDateSheetReportService>()),
  );
  sl.registerFactory<ExamDateSheetGeneratorBloc>(
    () => ExamDateSheetGeneratorBloc(
      sl<GenerateExamDateSheetOptions>(),
      sl<ExamDateSheetRepository>(),
    ),
  );
  sl.registerFactory<ExamDateSheetBloc>(
    () => ExamDateSheetBloc(sl<ExamDateSheetRepository>()),
  );
  sl.registerFactory<FeeReportsBloc>(
    () => FeeReportsBloc(
      sl<MonthlyFeeDueRepository>(),
      sl<FeePaymentRepository>(),
      sl<FeeReportService>(),
    ),
  );
  sl.registerFactory<FeeDocumentBloc>(
    () => FeeDocumentBloc(sl<FeeDocumentService>()),
  );
  sl.registerFactory<FeeCollectionBloc>(
    () => FeeCollectionBloc(
      sl<MonthlyFeeDueRepository>(),
      sl<StudentAdditionalChargeDueRepository>(),
      sl<FeePaymentRepository>(),
    ),
  );
  sl.registerFactory<AdditionalChargesBloc>(
    () => AdditionalChargesBloc(
      sl<AdditionalChargeRepository>(),
      sl<StudentAdditionalChargeDueRepository>(),
      sl<AdditionalChargeGenerationService>(),
    ),
  );
  sl.registerFactory<MonthlyFeeGenerationBloc>(
    () => MonthlyFeeGenerationBloc(
      sl<GenerateMonthlyFees>(),
      sl<MonthlyFeeDueRepository>(),
    ),
  );
  sl.registerFactory<StudentFeeAssignmentBloc>(
    () => StudentFeeAssignmentBloc(sl<StudentFeeAssignmentRepository>()),
  );
  sl.registerFactory<FeeStructureBloc>(
    () => FeeStructureBloc(sl<FeeStructureRepository>()),
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

  sl.registerFactory<ResultsAnalyticsBloc>(
    () => ResultsAnalyticsBloc(getAnalyticsData: sl<GetResultsAnalyticsData>()),
  );

  sl.registerFactory<ResultsExportBloc>(
    () => ResultsExportBloc(exportService: sl<ResultsExportService>()),
  );

  sl.registerFactory<ResultArchiveBloc>(
    () => ResultArchiveBloc(getResultArchive: sl<GetResultArchive>()),
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

  sl.registerFactory<AutoTimetableBloc>(
    () => AutoTimetableBloc(sl<GenerateAutoTimetable>()),
  );
  sl.registerFactory<ClassTimetableBloc>(
    () => ClassTimetableBloc(
      sl<GetClassTimetable>(),
      sl<SaveClassTimetableEntry>(),
      sl<DeleteClassTimetableEntry>(),
    ),
  );
  sl.registerFactory<DayTimetableBloc>(
    () => DayTimetableBloc(sl<GetDayTimetable>()),
  );
  sl.registerFactory<TeacherAvailabilityBloc>(
    () => TeacherAvailabilityBloc(sl<TeacherAvailabilityRepository>()),
  );
  sl.registerFactory<TimetableVersionBloc>(
    () => TimetableVersionBloc(sl<ManageTimetableVersions>()),
  );
  sl.registerFactory<TimetableReportBloc>(
    () => TimetableReportBloc(
      sl<GenerateTimetableReport>(),
      sl<TimetableReportExportService>(),
    ),
  );
  sl.registerFactory<TeacherWorkloadBloc>(
    () => TeacherWorkloadBloc(sl<GetTeacherWorkloads>()),
  );
  sl.registerFactory<ManualTimetableBloc>(
    () => ManualTimetableBloc(
      sl<GetClassTimetable>(),
      sl<ApplyManualTimetableChanges>(),
    ),
  );
  sl.registerFactory<TeacherTimetableBloc>(
    () => TeacherTimetableBloc(sl<GetTeacherTimetable>()),
  );
  sl.registerFactory<TimetableConfigurationBloc>(
    () => TimetableConfigurationBloc(
      sl<GetTimetableConfiguration>(),
      sl<SaveTimetableConfiguration>(),
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
