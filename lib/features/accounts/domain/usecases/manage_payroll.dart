import '../entities/payroll_profile_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../repositories/accounts_repository.dart';

class PayrollManagementData {
  const PayrollManagementData({required this.profiles, required this.records});

  final List<PayrollProfileEntity> profiles;
  final List<PayrollRecordEntity> records;
}

class GetPayrollManagementData {
  const GetPayrollManagementData(this._repository);

  final AccountsRepository _repository;

  Future<PayrollManagementData> call() async {
    final responses = await Future.wait<Object>([
      _repository.getPayrollProfiles(),
      _repository.getPayrollRecords(),
    ]);
    return PayrollManagementData(
      profiles: responses[0] as List<PayrollProfileEntity>,
      records: responses[1] as List<PayrollRecordEntity>,
    );
  }
}

class SavePayrollProfile {
  const SavePayrollProfile(this._repository);

  final AccountsRepository _repository;

  Future<void> call(PayrollProfileEntity profile) {
    if (profile.employeeId.trim().isEmpty) {
      throw ArgumentError('Employee ID is required.');
    }
    if (profile.employeeName.trim().isEmpty) {
      throw ArgumentError('Employee name is required.');
    }
    if (profile.basicSalary <= 0) {
      throw ArgumentError('Basic salary must be greater than zero.');
    }
    return _repository.savePayrollProfile(profile);
  }
}

class SetPayrollProfileActive {
  const SetPayrollProfileActive(this._repository);

  final AccountsRepository _repository;

  Future<void> call({required String profileId, required bool isActive}) =>
      _repository.setPayrollProfileActive(
        profileId: profileId,
        isActive: isActive,
      );
}

class GenerateMonthlyPayroll {
  const GenerateMonthlyPayroll(this._repository);

  final AccountsRepository _repository;

  Future<void> call({required DateTime month, required String actorId}) async {
    if (actorId.trim().isEmpty) {
      throw ArgumentError('Current user could not be identified.');
    }
    final profiles = await _repository.getPayrollProfiles();
    final records = await _repository.getPayrollRecords();
    final monthStart = DateTime(month.year, month.month);
    final monthKey =
        '${monthStart.year.toString().padLeft(4, '0')}-${monthStart.month.toString().padLeft(2, '0')}';

    for (final profile in profiles.where((item) => item.isActive)) {
      final id = '${profile.employeeId}_$monthKey';
      if (records.any((item) => item.id == id)) {
        continue;
      }
      final gross = profile.basicSalary + profile.fixedAllowances;
      final net = gross - profile.fixedDeductions;
      final now = DateTime.now();
      await _repository.savePayrollRecord(
        PayrollRecordEntity(
          id: id,
          employeeId: profile.employeeId,
          employeeName: profile.employeeName,
          payrollMonth: monthStart,
          basicSalary: profile.basicSalary,
          allowances: profile.fixedAllowances,
          deductions: profile.fixedDeductions,
          absenceDeduction: 0,
          advanceDeduction: 0,
          loanDeduction: 0,
          bonus: 0,
          grossSalary: gross,
          netSalary: net,
          paymentStatus: PayrollPaymentStatus.generated,
          paymentDate: null,
          paymentMethod: '',
          referenceNumber: '',
          remarks: '',
          generatedBy: actorId,
          approvedBy: '',
          approvedAt: null,
          paidBy: '',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

class SavePayrollRecord {
  const SavePayrollRecord(this._repository);

  final AccountsRepository _repository;

  Future<void> call(PayrollRecordEntity record) {
    if (record.netSalary < 0) {
      throw ArgumentError('Net salary cannot be negative.');
    }
    return _repository.savePayrollRecord(record);
  }
}

class UpdatePayrollStatus {
  const UpdatePayrollStatus(this._repository);

  final AccountsRepository _repository;

  Future<void> call({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod = '',
    String referenceNumber = '',
  }) {
    if (actorId.trim().isEmpty) {
      throw ArgumentError('Current user could not be identified.');
    }
    if (status == PayrollPaymentStatus.paid && paymentMethod.trim().isEmpty) {
      throw ArgumentError('Payment method is required.');
    }
    return _repository.updatePayrollStatus(
      payrollId: payrollId,
      status: status,
      actorId: actorId,
      paymentMethod: paymentMethod.trim(),
      referenceNumber: referenceNumber.trim(),
    );
  }
}
