import '../../domain/entities/staff_leave_entity.dart';

bool isTeacherDesignation(String designation) {
  return designation.trim().toLowerCase().contains('teacher');
}

/// Persists a stable teacher marker while retaining the teacher's designation.
/// This keeps teacher leave entries separate from staff leave entries even when
/// a teacher has a designation such as Coordinator or Principal.
String teacherLeaveDesignation(String designation) {
  final value = designation.trim();
  return value.isEmpty ? 'Teacher' : 'Teacher - $value';
}

bool isTeacherLeave(StaffLeaveEntity leave) {
  return isTeacherDesignation(leave.designation) &&
      (leave.leaveType == StaffLeaveType.other ||
          leave.leaveType == StaffLeaveType.unpaid);
}

String teacherLeaveTypeLabel(StaffLeaveType type) {
  return type == StaffLeaveType.unpaid ? 'Unpaid Leave' : 'Leave';
}

String teacherLeaveDurationLabel(StaffLeaveDuration duration) {
  return duration == StaffLeaveDuration.halfDay ? 'Half Day' : 'Full Day';
}

String teacherLeaveStatusLabel(StaffLeaveStatus status) {
  switch (status) {
    case StaffLeaveStatus.pending:
      return 'Pending';
    case StaffLeaveStatus.approved:
      return 'Approved';
    case StaffLeaveStatus.rejected:
      return 'Rejected';
    case StaffLeaveStatus.cancelled:
      return 'Cancelled';
  }
}

String teacherLeaveDateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

String teacherLeaveMonthLabel(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${months[date.month - 1]} ${date.year}';
}

String teacherLeaveDaysLabel(double value) {
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
}
