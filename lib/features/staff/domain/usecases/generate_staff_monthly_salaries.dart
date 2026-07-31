import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class GenerateStaffMonthlySalaries {
  const GenerateStaffMonthlySalaries({
    required this._staffRepository,
    required StaffAttendanceRepository attendanceRepository,
    required this._salaryRepository,
  })  : _attendanceRepository = attendanceRepository;

  final StaffRepository _staffRepository;
  final StaffAttendanceRepository _attendanceRepository;
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

      final basicSalary = staffMember.monthlySalary;
      final allowance = existingSalary?.allowance ?? 0;
      final deduction = existingSalary?.deduction ?? 0;
      final attendanceDeduction =
          existingSalary?.attendanceDeduction ?? 0;

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