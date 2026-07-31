import '../entities/staff_attendance_entity.dart';
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_attendance_repository.dart';
import '../repositories/staff_leave_repository.dart';

class UpdateStaffLeaveStatus {
  const UpdateStaffLeaveStatus(
    this._leaveRepository,
    this._attendanceRepository,
  );

  final StaffLeaveRepository _leaveRepository;
  final StaffAttendanceRepository _attendanceRepository;

  Future<void> call({
    required StaffLeaveEntity leave,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
  }) async {
    final now = DateTime.now();
    final isDecision =
        status == StaffLeaveStatus.approved ||
        status == StaffLeaveStatus.rejected;

    if (status == StaffLeaveStatus.approved) {
      await _markApprovedLeaveAttendance(
        leave: leave,
        updatedAt: now,
      );
    }

    await _leaveRepository.updateLeaveStatus(
      leaveId: leave.id,
      status: status,
      approvalRemarks: approvalRemarks.trim(),
      approvedBy: isDecision ? approvedBy.trim() : '',
      approvedAt: isDecision ? now : null,
      updatedAt: now,
    );
  }

  Future<void> _markApprovedLeaveAttendance({
    required StaffLeaveEntity leave,
    required DateTime updatedAt,
  }) async {
    final startDate = _normalizeDate(leave.startDate);
    final endDate = _normalizeDate(leave.endDate);

    final existingAttendance =
        await _attendanceRepository.getAttendanceByStaff(
      staffId: leave.staffId,
      startDate: startDate,
      endDate: endDate,
    );

    final existingByDate = <String, StaffAttendanceEntity>{
      for (final attendance in existingAttendance)
        _dateKey(attendance.attendanceDate): attendance,
    };

    var currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      final key = _dateKey(currentDate);
      final existing = existingByDate[key];

      await _attendanceRepository.saveAttendance(
        StaffAttendanceEntity(
          id: existing?.id ??
              _attendanceId(
                staffId: leave.staffId,
                date: currentDate,
              ),
          staffId: leave.staffId,
          staffCode: leave.staffCode,
          staffName: leave.staffName,
          designation: leave.designation,
          attendanceDate: currentDate,
          status: StaffAttendanceStatus.leave,
          remarks: _attendanceRemarks(leave),
          createdAt: existing?.createdAt ?? updatedAt,
          updatedAt: updatedAt,
        ),
      );

      currentDate = currentDate.add(
        const Duration(days: 1),
      );
    }
  }

  String _attendanceRemarks(
    StaffLeaveEntity leave,
  ) {
    final leaveType = switch (leave.leaveType) {
      StaffLeaveType.casual => 'Casual Leave',
      StaffLeaveType.sick => 'Sick Leave',
      StaffLeaveType.annual => 'Annual Leave',
      StaffLeaveType.unpaid => 'Unpaid Leave',
      StaffLeaveType.other => 'Other Leave',
    };

    final duration = switch (leave.duration) {
      StaffLeaveDuration.fullDay => 'Full Day',
      StaffLeaveDuration.halfDay => 'Half Day',
    };

    return 'Approved $leaveType ($duration)';
  }

  String _attendanceId({
    required String staffId,
    required DateTime date,
  }) {
    return '${staffId}_${_dateKey(date)}';
  }

  String _dateKey(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final month =
        normalizedDate.month.toString().padLeft(2, '0');
    final day =
        normalizedDate.day.toString().padLeft(2, '0');

    return '${normalizedDate.year}$month$day';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}