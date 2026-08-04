import '../../features/parent_portal/parent_fee_di.dart';
import '../../features/parent_portal/parent_results_di.dart';
import '../../features/parent_portal/parent_homework_di.dart';
import '../../features/parent_portal/parent_attendance_di.dart';
import '../../features/timeline/timeline_di.dart';
import '../../features/parent_portal/data/services/parent_context_service_impl.dart';
import '../../features/parent_portal/domain/services/parent_context_service.dart';
import '../audit/data/datasources/audit_remote_datasource.dart';
import '../audit/data/repositories/audit_repository_impl.dart';
import '../audit/data/services/audit_service_impl.dart';
import '../audit/domain/repositories/audit_repository.dart';
import '../audit/domain/services/audit_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../features/communication/data/datasources/push_delivery_log_remote_datasource.dart';
import '../../features/communication/data/repositories/push_delivery_log_repository_impl.dart';
import '../../features/communication/domain/repositories/push_delivery_log_repository.dart';
import '../../features/communication/domain/usecases/get_push_history.dart';
import '../../features/communication/domain/usecases/retry_failed_push.dart';
import '../../features/communication/presentation/bloc/push_history_bloc.dart';
import '../../features/communication/data/datasources/whatsapp_broadcast_remote_datasource.dart';
import '../../features/communication/data/repositories/whatsapp_broadcast_repository_impl.dart';
import '../../features/communication/data/services/firebase_callable_whatsapp_broadcast_sender_service.dart';
import '../../features/communication/domain/repositories/whatsapp_broadcast_repository.dart';
import '../../features/communication/domain/services/whatsapp_broadcast_sender_service.dart';
import '../../features/communication/domain/usecases/manage_whatsapp_broadcasts.dart';
import '../../features/communication/presentation/bloc/whatsapp_broadcast_bloc.dart';
import '../../features/communication/data/datasources/whatsapp_remote_datasource.dart';
import '../../features/communication/data/repositories/whatsapp_repository_impl.dart';
import '../../features/communication/data/services/firebase_callable_whatsapp_sender_service.dart';
import '../../features/communication/domain/repositories/whatsapp_repository.dart';
import '../../features/communication/domain/services/whatsapp_sender_service.dart';
import '../../features/communication/domain/usecases/manage_whatsapp.dart';
import '../../features/communication/presentation/bloc/whatsapp_bloc.dart';
import '../../features/communication/data/datasources/push_notification_request_remote_datasource.dart';
import '../../features/communication/data/repositories/push_notification_request_repository_impl.dart';
import '../../features/communication/data/services/firebase_callable_push_sender_service.dart';
import '../../features/communication/data/services/firebase_push_topic_service.dart';
import '../../features/communication/domain/repositories/push_notification_request_repository.dart';
import '../../features/communication/domain/services/push_sender_service.dart';
import '../../features/communication/domain/services/push_topic_service.dart';
import '../../features/communication/domain/usecases/manage_push_topics.dart';
import '../../features/communication/domain/usecases/send_push_notification.dart';
import '../../features/communication/presentation/bloc/push_notification_bloc.dart';
import '../../features/communication/data/datasources/push_device_token_remote_datasource.dart';
import '../../features/communication/data/repositories/push_device_token_repository_impl.dart';
import '../../features/communication/data/services/firebase_push_notification_service.dart';
import '../../features/communication/domain/repositories/push_device_token_repository.dart';
import '../../features/communication/domain/services/push_notification_service.dart';
import '../../features/communication/domain/usecases/register_push_device.dart';
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../features/academic_structure/data/datasources/academic_structure_remote_datasource.dart';
import '../../features/academic_structure/data/repositories/academic_structure_repository_impl.dart';
import '../../features/academic_structure/data/repositories/subject_component_repository_impl.dart';
import '../../features/academic_structure/domain/repositories/subject_component_repository.dart';
import '../../features/academic_structure/domain/services/subject_component_exam_service.dart';
import '../../features/academic_structure/presentation/bloc/subject_component_bloc.dart';
import '../../features/academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../features/accounts/data/datasources/accounts_remote_datasource.dart';
import '../../features/accounts/data/repositories/accounts_repository_impl.dart';
import '../../features/accounts/domain/repositories/accounts_repository.dart';
import '../../features/accounts/domain/usecases/get_accounts_overview.dart';
import '../../features/accounts/presentation/bloc/accounts_bloc.dart';
import '../../features/accounts/domain/usecases/manage_expenses.dart';
import '../../features/accounts/presentation/bloc/expense_bloc.dart';
import '../../features/accounts/domain/usecases/manage_payroll.dart';
import '../../features/accounts/presentation/bloc/payroll_bloc.dart';
import '../../features/accounts/domain/usecases/manage_income.dart';
import '../../features/accounts/presentation/bloc/income_bloc.dart';
import '../../features/accounts/domain/usecases/manage_profit_loss.dart';
import '../../features/accounts/presentation/bloc/profit_loss_bloc.dart';
import '../../features/accounts/domain/usecases/manage_cashbook.dart';
import '../../features/accounts/presentation/bloc/cashbook_bloc.dart';
import '../../features/accounts/data/services/accounts_report_service_impl.dart';
import '../../features/accounts/domain/services/accounts_report_service.dart';
import '../../features/accounts/domain/usecases/get_accounts_report_data.dart';
import '../../features/accounts/presentation/bloc/accounts_reports_bloc.dart';
import '../../features/communication/data/datasources/chat_remote_datasource.dart';
import '../../features/communication/data/repositories/chat_repository_impl.dart';
import '../../features/communication/domain/repositories/chat_repository.dart';
import '../../features/communication/domain/usecases/manage_chat.dart';
import '../../features/communication/presentation/bloc/chat_bloc.dart';
import '../../features/communication/data/datasources/communication_audit_remote_datasource.dart';
import '../../features/communication/data/repositories/communication_audit_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_audit_repository.dart';
import '../../features/communication/domain/usecases/get_communication_analytics.dart';
import '../../features/communication/presentation/bloc/communication_analytics_bloc.dart';
import '../../features/communication/domain/usecases/get_communication_delivery_audit.dart';
import '../../features/communication/presentation/bloc/communication_audit_bloc.dart';
import '../../features/communication/data/datasources/communication_broadcast_remote_datasource.dart';
import '../../features/communication/data/repositories/communication_broadcast_repository_impl.dart';
import '../../features/communication/data/services/firebase_callable_communication_broadcast_sender_service.dart';
import '../../features/communication/domain/repositories/communication_broadcast_repository.dart';
import '../../features/communication/domain/services/communication_broadcast_sender_service.dart';
import '../../features/communication/domain/usecases/manage_communication_broadcasts.dart';
import '../../features/communication/presentation/bloc/communication_broadcast_bloc.dart';
import '../../features/communication/data/datasources/communication_remote_datasource.dart';
import '../../features/communication/data/repositories/communication_repository_impl.dart';
import '../../features/communication/domain/repositories/communication_repository.dart';
import '../../features/communication/domain/usecases/delete_communication_message.dart';
import '../../features/communication/domain/usecases/get_communication_messages.dart';
import '../../features/communication/domain/usecases/save_communication_message.dart';
import '../../features/communication/presentation/bloc/communication_bloc.dart';
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
import '../../features/school_store/data/datasources/store_payment_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_payment_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_payment_repository.dart';
import '../../features/school_store/domain/usecases/get_store_reports.dart';
import '../../features/school_store/presentation/bloc/store_reports_bloc.dart';
import '../../features/school_store/domain/usecases/manage_store_payments.dart';
import '../../features/school_store/presentation/bloc/store_payment_bloc.dart';
import '../../features/school_store/data/datasources/store_sale_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_sale_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_sale_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_sales.dart';
import '../../features/school_store/presentation/bloc/store_sale_bloc.dart';
import '../../features/school_store/data/datasources/store_purchase_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_purchase_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_purchase_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_purchases.dart';
import '../../features/school_store/presentation/bloc/store_purchase_bloc.dart';
import '../../features/school_store/data/datasources/school_store_remote_datasource.dart';
import '../../features/school_store/data/repositories/school_store_repository_impl.dart';
import '../../features/school_store/domain/repositories/school_store_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_items.dart';
import '../../features/school_store/presentation/bloc/school_store_bloc.dart';
import '../../features/settings/data/datasources/backup_remote_datasource.dart';
import '../../features/settings/data/repositories/backup_repository_impl.dart';
import '../../features/settings/domain/repositories/backup_repository.dart';
import '../../features/settings/domain/usecases/manage_backup_restore.dart';
import '../../features/settings/presentation/bloc/backup_bloc.dart';
import '../../features/settings/data/datasources/user_preferences_remote_datasource.dart';
import '../../features/settings/data/repositories/user_preferences_repository_impl.dart';
import '../../features/settings/domain/repositories/user_preferences_repository.dart';
import '../../features/settings/domain/usecases/manage_user_preferences.dart';
import '../../features/settings/presentation/bloc/user_preferences_bloc.dart';
import '../../features/settings/data/datasources/security_remote_datasource.dart';
import '../../features/settings/data/repositories/security_repository_impl.dart';
import '../../features/settings/domain/repositories/security_repository.dart';
import '../../features/settings/domain/usecases/manage_security.dart';
import '../../features/settings/presentation/bloc/security_bloc.dart';
import '../../features/settings/data/datasources/system_health_remote_datasource.dart';
import '../../features/settings/data/repositories/system_health_repository_impl.dart';
import '../../features/settings/domain/repositories/system_health_repository.dart';
import '../../features/settings/domain/usecases/manage_system_health.dart';
import '../../features/settings/presentation/bloc/system_health_bloc.dart';
import '../../features/settings/data/datasources/settings_remote_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/manage_settings.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
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
  registerParentFeeDependencies(sl);
  registerParentResultsDependencies(sl);
  registerParentHomeworkDependencies(sl);
  registerParentAttendanceDependencies(sl);
  registerTimelineDependencies(sl);
  sl.registerLazySingleton<AuditRemoteDataSource>(
    () => AuditRemoteDataSource(),
  );

  sl.registerLazySingleton<AuditRepository>(
    () => AuditRepositoryImpl(sl<AuditRemoteDataSource>()),
  );

  sl.registerLazySingleton<AuditService>(
    () => AuditServiceImpl(sl<AuditRepository>(), sl<AccessControlService>()),
  );

  // =========================================================
  // Services
  // =========================================================

  sl.registerLazySingleton<FirebaseAuthService>(FirebaseAuthService.new);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<FirebaseFunctions>(() => FirebaseFunctions.instance);

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

  sl.registerLazySingleton<GetStoreReports>(
    () => GetStoreReports(
      storeRepository: sl<SchoolStoreRepository>(),
      purchaseRepository: sl<StorePurchaseRepository>(),
      saleRepository: sl<StoreSaleRepository>(),
      paymentRepository: sl<StorePaymentRepository>(),
    ),
  );
  sl.registerFactory<StoreReportsBloc>(
    () => StoreReportsBloc(sl<GetStoreReports>()),
  );
  sl.registerLazySingleton<StorePaymentRemoteDataSource>(
    () => StorePaymentRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StorePaymentRepository>(
    () => StorePaymentRepositoryImpl(sl<StorePaymentRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetStorePaymentData>(
    () => GetStorePaymentData(sl<StorePaymentRepository>()),
  );
  sl.registerLazySingleton<ReceiveStoreStudentPayment>(
    () => ReceiveStoreStudentPayment(sl<StorePaymentRepository>()),
  );
  sl.registerLazySingleton<PayStoreSupplier>(
    () => PayStoreSupplier(sl<StorePaymentRepository>()),
  );
  sl.registerFactory<StorePaymentBloc>(
    () => StorePaymentBloc(
      getData: sl<GetStorePaymentData>(),
      receiveStudentPayment: sl<ReceiveStoreStudentPayment>(),
      paySupplier: sl<PayStoreSupplier>(),
    ),
  );
  sl.registerLazySingleton<StoreSaleRemoteDataSource>(
    () => StoreSaleRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StoreSaleRepository>(
    () => StoreSaleRepositoryImpl(sl<StoreSaleRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetStoreStudents>(
    () => GetStoreStudents(sl<StoreSaleRepository>()),
  );
  sl.registerLazySingleton<GetStoreSales>(
    () => GetStoreSales(sl<StoreSaleRepository>()),
  );
  sl.registerLazySingleton<SaveStoreSale>(
    () => SaveStoreSale(sl<StoreSaleRepository>()),
  );
  sl.registerFactory<StoreSaleBloc>(
    () => StoreSaleBloc(
      getStudents: sl<GetStoreStudents>(),
      getItems: sl<GetStoreItems>(),
      getSales: sl<GetStoreSales>(),
      saveSale: sl<SaveStoreSale>(),
    ),
  );
  sl.registerLazySingleton<StorePurchaseRemoteDataSource>(
    () => StorePurchaseRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StorePurchaseRepository>(
    () => StorePurchaseRepositoryImpl(sl<StorePurchaseRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetStoreSuppliers>(
    () => GetStoreSuppliers(sl<StorePurchaseRepository>()),
  );
  sl.registerLazySingleton<SaveStoreSupplier>(
    () => SaveStoreSupplier(sl<StorePurchaseRepository>()),
  );
  sl.registerLazySingleton<GetStorePurchases>(
    () => GetStorePurchases(sl<StorePurchaseRepository>()),
  );
  sl.registerLazySingleton<SaveStorePurchase>(
    () => SaveStorePurchase(sl<StorePurchaseRepository>()),
  );
  sl.registerFactory<StorePurchaseBloc>(
    () => StorePurchaseBloc(
      getSuppliers: sl<GetStoreSuppliers>(),
      saveSupplier: sl<SaveStoreSupplier>(),
      getPurchases: sl<GetStorePurchases>(),
      savePurchase: sl<SaveStorePurchase>(),
      getItems: sl<GetStoreItems>(),
    ),
  );
  sl.registerLazySingleton<SchoolStoreRemoteDataSource>(
    () => SchoolStoreRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<SchoolStoreRepository>(
    () => SchoolStoreRepositoryImpl(sl<SchoolStoreRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetStoreItems>(
    () => GetStoreItems(sl<SchoolStoreRepository>()),
  );
  sl.registerLazySingleton<SaveStoreItem>(
    () => SaveStoreItem(sl<SchoolStoreRepository>()),
  );
  sl.registerLazySingleton<DeleteStoreItem>(
    () => DeleteStoreItem(sl<SchoolStoreRepository>()),
  );
  sl.registerFactory<SchoolStoreBloc>(
    () => SchoolStoreBloc(
      getItems: sl<GetStoreItems>(),
      saveItem: sl<SaveStoreItem>(),
      deleteItem: sl<DeleteStoreItem>(),
    ),
  );
  sl.registerLazySingleton<BackupRemoteDataSource>(
    () => BackupRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseFunctions>(),
    ),
  );
  sl.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(sl<BackupRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetBackupRestoreData>(
    () => GetBackupRestoreData(sl<BackupRepository>()),
  );
  sl.registerLazySingleton<RequestBackup>(
    () => RequestBackup(sl<BackupRepository>()),
  );
  sl.registerLazySingleton<RequestRestore>(
    () => RequestRestore(sl<BackupRepository>()),
  );
  sl.registerFactory<BackupBloc>(
    () => BackupBloc(
      getData: sl<GetBackupRestoreData>(),
      requestBackup: sl<RequestBackup>(),
      requestRestore: sl<RequestRestore>(),
    ),
  );
  sl.registerLazySingleton<UserPreferencesRemoteDataSource>(
    () => UserPreferencesRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<UserPreferencesRepository>(
    () => UserPreferencesRepositoryImpl(sl<UserPreferencesRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetUserPreferences>(
    () => GetUserPreferences(sl<UserPreferencesRepository>()),
  );
  sl.registerLazySingleton<SaveUserPreferences>(
    () => SaveUserPreferences(sl<UserPreferencesRepository>()),
  );
  sl.registerFactory<UserPreferencesBloc>(
    () => UserPreferencesBloc(
      getPreferences: sl<GetUserPreferences>(),
      savePreferences: sl<SaveUserPreferences>(),
    ),
  );
  sl.registerLazySingleton<SecurityRemoteDataSource>(
    () => SecurityRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<SecurityRepository>(
    () => SecurityRepositoryImpl(sl<SecurityRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetSecurityData>(
    () => GetSecurityData(sl<SecurityRepository>()),
  );
  sl.registerLazySingleton<ChangeUserPassword>(
    () => ChangeUserPassword(sl<SecurityRepository>()),
  );
  sl.registerLazySingleton<RevokeUserSession>(
    () => RevokeUserSession(sl<SecurityRepository>()),
  );
  sl.registerFactory<SecurityBloc>(
    () => SecurityBloc(
      getData: sl<GetSecurityData>(),
      changePassword: sl<ChangeUserPassword>(),
      revokeSession: sl<RevokeUserSession>(),
    ),
  );
  sl.registerLazySingleton<SystemHealthRemoteDataSource>(
    () => SystemHealthRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
      sl<FirebaseAuth>(),
    ),
  );
  sl.registerLazySingleton<SystemHealthRepository>(
    () => SystemHealthRepositoryImpl(sl<SystemHealthRemoteDataSource>()),
  );
  sl.registerLazySingleton<CheckSystemHealth>(
    () => CheckSystemHealth(sl<SystemHealthRepository>()),
  );
  sl.registerFactory<SystemHealthBloc>(
    () => SystemHealthBloc(sl<CheckSystemHealth>()),
  );
  sl.registerLazySingleton<SettingsRemoteDataSource>(
    () => SettingsRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl<SettingsRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetSchoolSettings>(
    () => GetSchoolSettings(sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<SaveSchoolSettings>(
    () => SaveSchoolSettings(sl<SettingsRepository>()),
  );
  sl.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getSettings: sl<GetSchoolSettings>(),
      saveSettings: sl<SaveSchoolSettings>(),
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
    () => StudentRepositoryImpl(
      remoteDataSource: sl<StudentRemoteDataSource>(),
      auditService: sl<AuditService>(),
    ),
  );

  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      remoteDataSource: sl<AttendanceRemoteDataSource>(),
      auditService: sl<AuditService>(),
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

  sl.registerLazySingleton<SubjectComponentRepository>(
    () => SubjectComponentRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<SubjectComponentExamService>(
    () => SubjectComponentExamService(
      sl<AcademicStructureRepository>(),
      sl<SubjectComponentRepository>(),
    ),
  );
  sl.registerFactory<SubjectComponentBloc>(
    () => SubjectComponentBloc(
      sl<SubjectComponentRepository>(),
      sl<AcademicStructureRepository>(),
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
      sl<AcademicStructureRepository>(),
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
    () => ParentCommunicationServiceImpl(
      sl<FirebaseFirestore>(),
      sl<AcademicStructureRepository>(),
    ),
  );
  sl.registerLazySingleton<ParentAcademicService>(
    () => ParentAcademicServiceImpl(
      sl<FirebaseFirestore>(),
      sl<AcademicStructureRepository>(),
    ),
  );
  sl.registerLazySingleton<ParentPortalRepository>(
    () => ParentPortalRepositoryImpl(
      sl<FirebaseFirestoreService>(),
      sl<StudentRepository>(),
    ),
  );
  sl.registerLazySingleton<ParentContextService>(
    () => ParentContextServiceImpl(
      sl<FirebaseAuth>(),
      sl<ParentPortalRepository>(),
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

  sl.registerLazySingleton<AccountsRemoteDataSource>(
    () => AccountsRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<AccountsRepository>(
    () => AccountsRepositoryImpl(sl<AccountsRemoteDataSource>()),
  );

  sl.registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance);
  sl.registerLazySingleton<WhatsAppBroadcastRemoteDataSource>(
    () => WhatsAppBroadcastRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<WhatsAppBroadcastRepository>(
    () => WhatsAppBroadcastRepositoryImpl(
      sl<WhatsAppBroadcastRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<WhatsAppBroadcastSenderService>(
    () =>
        FirebaseCallableWhatsAppBroadcastSenderService(sl<FirebaseFunctions>()),
  );
  sl.registerLazySingleton<GetWhatsAppBroadcasts>(
    () => GetWhatsAppBroadcasts(sl<WhatsAppBroadcastRepository>()),
  );
  sl.registerLazySingleton<QueueWhatsAppBroadcast>(
    () => QueueWhatsAppBroadcast(
      sl<WhatsAppBroadcastRepository>(),
      sl<WhatsAppBroadcastSenderService>(),
    ),
  );
  sl.registerLazySingleton<RetryWhatsAppBroadcast>(
    () => RetryWhatsAppBroadcast(
      sl<WhatsAppBroadcastRepository>(),
      sl<WhatsAppBroadcastSenderService>(),
    ),
  );
  sl.registerFactory<WhatsAppBroadcastBloc>(
    () => WhatsAppBroadcastBloc(
      getBroadcasts: sl<GetWhatsAppBroadcasts>(),
      queueBroadcast: sl<QueueWhatsAppBroadcast>(),
      retryBroadcast: sl<RetryWhatsAppBroadcast>(),
    ),
  );
  sl.registerLazySingleton<WhatsAppRemoteDataSource>(
    () => WhatsAppRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<WhatsAppRepository>(
    () => WhatsAppRepositoryImpl(sl<WhatsAppRemoteDataSource>()),
  );
  sl.registerLazySingleton<WhatsAppSenderService>(
    () => FirebaseCallableWhatsAppSenderService(sl<FirebaseFunctions>()),
  );
  sl.registerLazySingleton<GetWhatsAppData>(
    () => GetWhatsAppData(sl<WhatsAppRepository>()),
  );
  sl.registerLazySingleton<SaveWhatsAppTemplate>(
    () => SaveWhatsAppTemplate(sl<WhatsAppRepository>()),
  );
  sl.registerLazySingleton<SendWhatsAppMessage>(
    () => SendWhatsAppMessage(
      sl<WhatsAppRepository>(),
      sl<WhatsAppSenderService>(),
    ),
  );
  sl.registerFactory<WhatsAppBloc>(
    () => WhatsAppBloc(
      getData: sl<GetWhatsAppData>(),
      saveTemplate: sl<SaveWhatsAppTemplate>(),
      sendMessage: sl<SendWhatsAppMessage>(),
    ),
  );
  sl.registerLazySingleton<PushTopicService>(
    () => FirebasePushTopicService(sl<PushNotificationService>()),
  );
  sl.registerLazySingleton<PushDeliveryLogRemoteDataSource>(
    () => PushDeliveryLogRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<PushDeliveryLogRepository>(
    () => PushDeliveryLogRepositoryImpl(sl<PushDeliveryLogRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetPushHistory>(
    () => GetPushHistory(
      sl<PushNotificationRequestRepository>(),
      sl<PushDeliveryLogRepository>(),
    ),
  );
  sl.registerLazySingleton<RetryFailedPush>(
    () => RetryFailedPush(
      sl<PushNotificationRequestRepository>(),
      sl<PushSenderService>(),
    ),
  );
  sl.registerFactory<PushHistoryBloc>(
    () => PushHistoryBloc(
      getHistory: sl<GetPushHistory>(),
      retryPush: sl<RetryFailedPush>(),
    ),
  );
  sl.registerLazySingleton<PushNotificationRequestRemoteDataSource>(
    () => PushNotificationRequestRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<PushNotificationRequestRepository>(
    () => PushNotificationRequestRepositoryImpl(
      sl<PushNotificationRequestRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<PushSenderService>(
    () => FirebaseCallablePushSenderService(sl<FirebaseFunctions>()),
  );
  sl.registerLazySingleton<SubscribeCommunicationTopic>(
    () => SubscribeCommunicationTopic(sl<PushTopicService>()),
  );
  sl.registerLazySingleton<UnsubscribeCommunicationTopic>(
    () => UnsubscribeCommunicationTopic(sl<PushTopicService>()),
  );
  sl.registerLazySingleton<SendPushNotification>(
    () => SendPushNotification(
      sl<PushNotificationRequestRepository>(),
      sl<PushSenderService>(),
    ),
  );
  sl.registerFactory<PushNotificationBloc>(
    () => PushNotificationBloc(
      sendNotification: sl<SendPushNotification>(),
      subscribeTopic: sl<SubscribeCommunicationTopic>(),
      unsubscribeTopic: sl<UnsubscribeCommunicationTopic>(),
    ),
  );
  sl.registerLazySingleton<PushNotificationService>(
    () => FirebasePushNotificationService(sl<FirebaseMessaging>()),
  );
  sl.registerLazySingleton<PushDeviceTokenRemoteDataSource>(
    () => PushDeviceTokenRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<PushDeviceTokenRepository>(
    () => PushDeviceTokenRepositoryImpl(sl<PushDeviceTokenRemoteDataSource>()),
  );
  sl.registerLazySingleton<RegisterPushDevice>(
    () => RegisterPushDevice(
      sl<PushNotificationService>(),
      sl<PushDeviceTokenRepository>(),
    ),
  );
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(sl<ChatRemoteDataSource>()),
  );
  sl.registerLazySingleton<GetChatThreads>(
    () => GetChatThreads(sl<ChatRepository>()),
  );
  sl.registerLazySingleton<GetChatMessages>(
    () => GetChatMessages(sl<ChatRepository>()),
  );
  sl.registerLazySingleton<CreateChatThread>(
    () => CreateChatThread(sl<ChatRepository>()),
  );
  sl.registerLazySingleton<SendChatMessage>(
    () => SendChatMessage(sl<ChatRepository>()),
  );
  sl.registerLazySingleton<MarkChatThreadRead>(
    () => MarkChatThreadRead(sl<ChatRepository>()),
  );
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(
      getThreads: sl<GetChatThreads>(),
      getMessages: sl<GetChatMessages>(),
      createThread: sl<CreateChatThread>(),
      sendMessage: sl<SendChatMessage>(),
      markRead: sl<MarkChatThreadRead>(),
    ),
  );
  sl.registerLazySingleton<CommunicationAuditRemoteDataSource>(
    () =>
        CommunicationAuditRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<CommunicationAuditRepository>(
    () => CommunicationAuditRepositoryImpl(
      sl<CommunicationAuditRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetCommunicationAnalytics>(
    () => GetCommunicationAnalytics(sl<GetCommunicationDeliveryAudit>()),
  );
  sl.registerFactory<CommunicationAnalyticsBloc>(
    () => CommunicationAnalyticsBloc(sl<GetCommunicationAnalytics>()),
  );
  sl.registerLazySingleton<GetCommunicationDeliveryAudit>(
    () => GetCommunicationDeliveryAudit(
      broadcastRepository: sl<CommunicationBroadcastRepository>(),
      pushLogRepository: sl<PushDeliveryLogRepository>(),
      whatsappRepository: sl<WhatsAppRepository>(),
      auditRepository: sl<CommunicationAuditRepository>(),
    ),
  );
  sl.registerFactory<CommunicationAuditBloc>(
    () => CommunicationAuditBloc(sl<GetCommunicationDeliveryAudit>()),
  );
  sl.registerLazySingleton<CommunicationBroadcastRemoteDataSource>(
    () => CommunicationBroadcastRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<CommunicationBroadcastRepository>(
    () => CommunicationBroadcastRepositoryImpl(
      sl<CommunicationBroadcastRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<CommunicationBroadcastSenderService>(
    () => FirebaseCallableCommunicationBroadcastSenderService(
      sl<FirebaseFunctions>(),
    ),
  );
  sl.registerLazySingleton<GetCommunicationBroadcasts>(
    () => GetCommunicationBroadcasts(sl<CommunicationBroadcastRepository>()),
  );
  sl.registerLazySingleton<QueueCommunicationBroadcast>(
    () => QueueCommunicationBroadcast(
      sl<CommunicationBroadcastRepository>(),
      sl<CommunicationBroadcastSenderService>(),
    ),
  );
  sl.registerLazySingleton<RetryCommunicationBroadcast>(
    () => RetryCommunicationBroadcast(
      sl<CommunicationBroadcastRepository>(),
      sl<CommunicationBroadcastSenderService>(),
    ),
  );
  sl.registerFactory<CommunicationBroadcastBloc>(
    () => CommunicationBroadcastBloc(
      getBroadcasts: sl<GetCommunicationBroadcasts>(),
      queueBroadcast: sl<QueueCommunicationBroadcast>(),
      retryBroadcast: sl<RetryCommunicationBroadcast>(),
    ),
  );
  sl.registerLazySingleton<CommunicationRemoteDataSource>(
    () => CommunicationRemoteDataSourceImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepositoryImpl(sl<CommunicationRemoteDataSource>()),
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

  sl.registerLazySingleton<AccountsReportService>(
    AccountsReportServiceImpl.new,
  );
  sl.registerLazySingleton<GetAccountsReportData>(
    () => GetAccountsReportData(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<GetCashbookEntries>(
    () => GetCashbookEntries(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SyncCashbook>(
    () => SyncCashbook(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<GetProfitLossSnapshots>(
    () => GetProfitLossSnapshots(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<GenerateMonthlyProfitLoss>(
    () => GenerateMonthlyProfitLoss(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<GetIncomeEntries>(
    () => GetIncomeEntries(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SaveIncomeEntry>(
    () => SaveIncomeEntry(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<ReverseIncomeEntry>(
    () => ReverseIncomeEntry(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SyncFeePaymentsToIncome>(
    () => SyncFeePaymentsToIncome(
      sl<AccountsRepository>(),
      sl<FeePaymentRepository>(),
    ),
  );

  sl.registerLazySingleton<GetPayrollManagementData>(
    () => GetPayrollManagementData(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SavePayrollProfile>(
    () => SavePayrollProfile(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SetPayrollProfileActive>(
    () => SetPayrollProfileActive(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<GenerateMonthlyPayroll>(
    () => GenerateMonthlyPayroll(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SavePayrollRecord>(
    () => SavePayrollRecord(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<UpdatePayrollStatus>(
    () => UpdatePayrollStatus(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<GetExpenseManagementData>(
    () => GetExpenseManagementData(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SaveExpenseCategory>(
    () => SaveExpenseCategory(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SetExpenseCategoryActive>(
    () => SetExpenseCategoryActive(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<SaveExpense>(
    () => SaveExpense(sl<AccountsRepository>()),
  );
  sl.registerLazySingleton<UpdateExpenseStatus>(
    () => UpdateExpenseStatus(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<GetAccountsOverview>(
    () => GetAccountsOverview(sl<AccountsRepository>()),
  );

  sl.registerLazySingleton<DeleteCommunicationMessage>(
    () => DeleteCommunicationMessage(sl<CommunicationRepository>()),
  );

  sl.registerLazySingleton<GetCommunicationMessages>(
    () => GetCommunicationMessages(sl<CommunicationRepository>()),
  );
  sl.registerLazySingleton<SaveCommunicationMessage>(
    () => SaveCommunicationMessage(sl<CommunicationRepository>()),
  );

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
      componentService: sl<SubjectComponentExamService>(),
      academicStructureRepository: sl<AcademicStructureRepository>(),
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
    () => GetTeacherWorkloads(
      sl<TimetableRepository>(),
      sl<TeacherRepository>(),
      sl<TeacherAssignmentRepository>(),
      sl<AcademicStructureRepository>(),
    ),
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

  sl.registerFactory<AccountsReportsBloc>(
    () => AccountsReportsBloc(
      getReportData: sl<GetAccountsReportData>(),
      reportService: sl<AccountsReportService>(),
    ),
  );

  sl.registerFactory<CashbookBloc>(
    () => CashbookBloc(
      getEntries: sl<GetCashbookEntries>(),
      syncCashbook: sl<SyncCashbook>(),
    ),
  );

  sl.registerFactory<ProfitLossBloc>(
    () => ProfitLossBloc(
      getSnapshots: sl<GetProfitLossSnapshots>(),
      generateMonthly: sl<GenerateMonthlyProfitLoss>(),
    ),
  );

  sl.registerFactory<IncomeBloc>(
    () => IncomeBloc(
      getIncomeEntries: sl<GetIncomeEntries>(),
      saveIncomeEntry: sl<SaveIncomeEntry>(),
      reverseIncomeEntry: sl<ReverseIncomeEntry>(),
      syncFeePayments: sl<SyncFeePaymentsToIncome>(),
    ),
  );

  sl.registerFactory<PayrollBloc>(
    () => PayrollBloc(
      getData: sl<GetPayrollManagementData>(),
      saveProfile: sl<SavePayrollProfile>(),
      generatePayroll: sl<GenerateMonthlyPayroll>(),
      saveRecord: sl<SavePayrollRecord>(),
      updateStatus: sl<UpdatePayrollStatus>(),
    ),
  );

  sl.registerFactory<ExpenseBloc>(
    () => ExpenseBloc(
      getData: sl<GetExpenseManagementData>(),
      saveCategory: sl<SaveExpenseCategory>(),
      setCategoryActive: sl<SetExpenseCategoryActive>(),
      saveExpense: sl<SaveExpense>(),
      updateStatus: sl<UpdateExpenseStatus>(),
    ),
  );

  sl.registerFactory<AccountsBloc>(
    () => AccountsBloc(sl<GetAccountsOverview>()),
  );

  sl.registerFactory<CommunicationBloc>(
    () => CommunicationBloc(
      getMessages: sl<GetCommunicationMessages>(),
      saveMessage: sl<SaveCommunicationMessage>(),
      deleteMessage: sl<DeleteCommunicationMessage>(),
    ),
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
    () => GenerateAttendanceReport(
      sl<AttendanceRepository>(),
      sl<AcademicStructureRepository>(),
    ),
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
      subjectSetupRepository: sl<ExamSubjectSetupRepository>(),
      markRepository: sl<ExamMarkRepository>(),
    ),
  );

  sl.registerFactory<ExamMarksBloc>(
    () => ExamMarksBloc(
      getExams: sl<GetExams>(),
      getSubjectSetupsForExam: sl<GetExamSubjectSetupsForExam>(),
      getStudentsByClassAndSection: sl<GetStudentsByClassAndSection>(),
      getExamMarks: sl<GetExamMarks>(),
      getExamResults: sl<GetExamResults>(),
      saveExamMarks: sl<SaveExamMarks>(),
      deleteExamMark: sl<DeleteExamMark>(),
      componentService: sl<SubjectComponentExamService>(),
      studentRepository: sl<StudentRepository>(),
      academicStructureRepository: sl<AcademicStructureRepository>(),
    ),
  );

  sl.registerFactory<ExamResultsBloc>(
    () => ExamResultsBloc(
      getExams: sl<GetExams>(),
      getSubjectSetupsForExam: sl<GetExamSubjectSetupsForExam>(),
      getExamResults: sl<GetExamResults>(),
      generateExamResults: sl<GenerateExamResults>(),
      updateResultStatus: sl<UpdateExamResultStatus>(),
      academicStructureRepository: sl<AcademicStructureRepository>(),
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
