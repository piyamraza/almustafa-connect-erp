import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../domain/repositories/staff_leave_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class GenerateStaffMonthlySalaries {
  const GenerateStaffMonthlySalaries({
    required this._staffRepository,
    required this._attendanceRepository,
    required this._leaveRepository,
    required this._salaryRepository,
  });

  final StaffRepository _staffRepository;
  final StaffAttendanceRepository _attendanceRepository;
  final StaffLeaveRepository _leaveRepository;
  final StaffSalaryRepository _salaryRepository;

  Future<List<StaffSalaryEntity>> call(
    DateTime month,
  ) async {
    final monthStart = DateTime(
      month.year,
      month.month,
      1,
    );

    final monthEnd = DateTime(
      month.year,
      month.month + 1,
      0,
    );

    final staff = await _staffRepository.getStaff();

    final attendance =
        await _attendanceRepository.getAttendanceByDateRange(
      startDate: monthStart,
      endDate: monthEnd,
    );

    final leaves = await _leaveRepository.getLeavesByDateRange(
      startDate: monthStart,
      endDate: monthEnd,
    );

    final existingSalaries =
        await _salaryRepository.getSalariesByMonth(monthStart);

    final attendanceByStaffId =
        <String, List<StaffAttendanceEntity>>{};

    for (final record in attendance) {
      attendanceByStaffId
          .putIfAbsent(
            record.staffId,
            () => <StaffAttendanceEntity>[],
          )
          .add(record);
    }

    final unpaidLeavesByStaffId =
        <String, List<StaffLeaveEntity>>{};

    for (final leave in leaves) {
      final isApprovedUnpaidLeave =
          leave.status == StaffLeaveStatus.approved &&
          leave.leaveType == StaffLeaveType.unpaid;

      if (!isApprovedUnpaidLeave) {
        continue;
      }

      unpaidLeavesByStaffId
          .putIfAbsent(
            leave.staffId,
            () => <StaffLeaveEntity>[],
          )
          .add(leave);
    }

    final existingByStaffId = <String, StaffSalaryEntity>{
      for (final salary in existingSalaries)
        salary.staffId: salary,
    };

    final generatedSalaries = <StaffSalaryEntity>[];
    final now = DateTime.now();

    for (final staffMember in staff) {
      final existingSalary = existingByStaffId[staffMember.id];

      final joinedBeforeMonthEnded =
          !staffMember.joiningDate.isAfter(monthEnd);

      final shouldGenerate =
          joinedBeforeMonthEnded &&
          (staffMember.isActive || existingSalary != null);

      if (!shouldGenerate) {
        continue;
      }

      final attendanceRecords =
          attendanceByStaffId[staffMember.id] ??
          const <StaffAttendanceEntity>[];

      final attendanceSummary = _summarizeAttendance(
        attendanceRecords,
      );

      final unpaidLeaves =
          unpaidLeavesByStaffId[staffMember.id] ??
          const <StaffLeaveEntity>[];

      final unpaidLeaveDays = _calculateUnpaidLeaveDays(
        leaves: unpaidLeaves,
        monthStart: monthStart,
        monthEnd: monthEnd,
      );

      final basicSalary = staffMember.monthlySalary;
      final allowance = existingSalary?.allowance ?? 0;
      final deduction = existingSalary?.deduction ?? 0;

      final calculatedAttendanceDeduction =
          _calculateUnpaidLeaveDeduction(
        basicSalary: basicSalary,
        unpaidLeaveDays: unpaidLeaveDays,
        monthDays: monthEnd.day,
      );

      final attendanceDeduction =
          existingSalary?.paymentStatus ==
                  StaffSalaryPaymentStatus.paid
              ? existingSalary!.attendanceDeduction
              : calculatedAttendanceDeduction;

      final grossSalary = basicSalary + allowance;
      final calculatedNetSalary =
          grossSalary - deduction - attendanceDeduction;
      final netSalary =
          calculatedNetSalary < 0 ? 0.0 : calculatedNetSalary;

      generatedSalaries.add(
        StaffSalaryEntity(
          id: existingSalary?.id ??
              _buildSalaryId(
                staffMember,
                monthStart,
              ),
          staffId: staffMember.id,
          staffCode: staffMember.staffId,
          staffName: staffMember.fullName,
          designation: staffMember.designation,
          salaryMonth: monthStart,
          basicSalary: basicSalary,
          allowance: allowance,
          deduction: deduction,
          attendanceDeduction: attendanceDeduction,
          grossSalary: grossSalary,
          netSalary: netSalary,
          presentDays: attendanceSummary.presentDays,
          absentDays: attendanceSummary.absentDays,
          lateDays: attendanceSummary.lateDays,
          leaveDays: attendanceSummary.leaveDays,
          paymentStatus: existingSalary?.paymentStatus ??
              StaffSalaryPaymentStatus.unpaid,
          paymentDate: existingSalary?.paymentDate,
          paymentMethod: existingSalary?.paymentMethod,
          paymentReference:
              existingSalary?.paymentReference ?? '',
          remarks: existingSalary?.remarks ?? '',
          createdAt: existingSalary?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    generatedSalaries.sort(
      (first, second) => first.staffName.toLowerCase().compareTo(
            second.staffName.toLowerCase(),
          ),
    );

    await _salaryRepository.saveSalaries(
      generatedSalaries,
    );

    return generatedSalaries;
  }

  double _calculateUnpaidLeaveDays({
    required List<StaffLeaveEntity> leaves,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) {
    final leaveFractionByDate = <String, double>{};

    for (final leave in leaves) {
      final normalizedStart = _normalizeDate(
        leave.startDate.isBefore(monthStart)
            ? monthStart
            : leave.startDate,
      );

      final normalizedEnd = _normalizeDate(
        leave.endDate.isAfter(monthEnd)
            ? monthEnd
            : leave.endDate,
      );

      if (normalizedEnd.isBefore(normalizedStart)) {
        continue;
      }

      if (leave.duration == StaffLeaveDuration.halfDay) {
        final key = _dateKey(normalizedStart);
        final existingFraction = leaveFractionByDate[key] ?? 0;

        if (existingFraction < 0.5) {
          leaveFractionByDate[key] = 0.5;
        }

        continue;
      }

      var currentDate = normalizedStart;

      while (!currentDate.isAfter(normalizedEnd)) {
        leaveFractionByDate[_dateKey(currentDate)] = 1;
        currentDate = currentDate.add(
          const Duration(days: 1),
        );
      }
    }

    return leaveFractionByDate.values.fold<double>(
      0,
      (total, fraction) => total + fraction,
    );
  }

  double _calculateUnpaidLeaveDeduction({
    required double basicSalary,
    required double unpaidLeaveDays,
    required int monthDays,
  }) {
    if (basicSalary <= 0 ||
        unpaidLeaveDays <= 0 ||
        monthDays <= 0) {
      return 0;
    }

    final deduction =
        (basicSalary / monthDays) * unpaidLeaveDays;

    return (deduction * 100).roundToDouble() / 100;
  }

  String _buildSalaryId(
    StaffEntity staff,
    DateTime month,
  ) {
    final formattedMonth =
        '${month.year}${month.month.toString().padLeft(2, '0')}';

    return '${staff.id}_$formattedMonth';
  }

  _AttendanceSummary _summarizeAttendance(
    List<StaffAttendanceEntity> records,
  ) {
    var presentDays = 0;
    var absentDays = 0;
    var lateDays = 0;
    var leaveDays = 0;

    for (final record in records) {
      switch (record.status) {
        case StaffAttendanceStatus.present:
          presentDays++;
        case StaffAttendanceStatus.absent:
          absentDays++;
        case StaffAttendanceStatus.late:
          lateDays++;
        case StaffAttendanceStatus.leave:
          leaveDays++;
      }
    }

    return _AttendanceSummary(
      presentDays: presentDays,
      absentDays: absentDays,
      lateDays: lateDays,
      leaveDays: leaveDays,
    );
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

class _AttendanceSummary {
  const _AttendanceSummary({
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
  });

  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
}
