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

    if (profile.fixedAllowances < 0) {
      throw ArgumentError('Fixed allowances cannot be negative.');
    }

    if (profile.fixedDeductions < 0) {
      throw ArgumentError('Fixed deductions cannot be negative.');
    }

    return _repository.savePayrollProfile(profile);
  }
}

class SetPayrollProfileActive {
  const SetPayrollProfileActive(this._repository);

  final AccountsRepository _repository;

  Future<void> call({required String profileId, required bool isActive}) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError('Payroll profile ID is required.');
    }

    return _repository.setPayrollProfileActive(
      profileId: profileId,
      isActive: isActive,
    );
  }
}

class DeletePayrollProfile {
  const DeletePayrollProfile(this._repository);

  final AccountsRepository _repository;

  Future<void> call(String profileId) {
    if (profileId.trim().isEmpty) {
      throw ArgumentError('Payroll profile ID is required.');
    }

    return _repository.deletePayrollProfile(profileId.trim());
  }
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
        '${monthStart.year.toString().padLeft(4, '0')}-'
        '${monthStart.month.toString().padLeft(2, '0')}';

    final existingRecordIds = records.map((record) => record.id).toSet();

    for (final profile in profiles.where((item) => item.isActive)) {
      final payrollId = '${profile.employeeId}_$monthKey';

      if (existingRecordIds.contains(payrollId)) {
        continue;
      }

      final employeeFinance = await _repository.getPayrollAutoDeductions(
        employeeId: profile.employeeId,
        payrollMonth: monthStart,
      );

      final employeeFinanceValue = employeeFinance.otherDeductions;

      final employeeFinanceAdditions = employeeFinanceValue < 0
          ? employeeFinanceValue.abs()
          : 0;

      final employeeFinanceDeductions = employeeFinanceValue > 0
          ? employeeFinanceValue
          : 0;

      final automaticBonus = employeeFinanceAdditions;

      final totalFixedAndOtherDeductions =
          profile.fixedDeductions + employeeFinanceDeductions;

      final grossSalary =
          profile.basicSalary + profile.fixedAllowances + automaticBonus;

      final totalDeductions =
          totalFixedAndOtherDeductions +
          employeeFinance.advanceDeduction +
          employeeFinance.loanDeduction;

      final netSalary = grossSalary - totalDeductions;

      if (netSalary < 0) {
        throw StateError(
          'Net salary cannot be negative for '
          '${profile.employeeName}. '
          'Please review this employee’s deductions.',
        );
      }

      final now = DateTime.now();

      final payrollRecord = PayrollRecordEntity(
        id: payrollId,
        employeeId: profile.employeeId,
        employeeName: profile.employeeName,
        payrollMonth: monthStart,
        basicSalary: profile.basicSalary,
        allowances: profile.fixedAllowances,
        deductions: totalFixedAndOtherDeductions,
        absenceDeduction: 0,
        advanceDeduction: employeeFinance.advanceDeduction,
        loanDeduction: employeeFinance.loanDeduction,
        bonus: automaticBonus,
        grossSalary: grossSalary,
        netSalary: netSalary,
        paymentStatus: PayrollPaymentStatus.generated,
        paymentDate: null,
        paymentMethod: '',
        referenceNumber: '',
        remarks: _buildAutomaticRemarks(
          advanceDeduction: employeeFinance.advanceDeduction,
          loanDeduction: employeeFinance.loanDeduction,
          otherDeductions: employeeFinanceDeductions,
          otherAdditions: employeeFinanceAdditions,
        ),
        generatedBy: actorId,
        approvedBy: '',
        approvedAt: null,
        paidBy: '',
        createdAt: now,
        updatedAt: now,
      );

      await _repository.savePayrollRecord(payrollRecord);

      await _repository.markEmployeeFinancePosted(
        payrollId: payrollId,
        employeeId: profile.employeeId,
        payrollMonth: monthStart,
        actorId: actorId,
      );

      existingRecordIds.add(payrollId);
    }
  }

  String _buildAutomaticRemarks({
    required int advanceDeduction,
    required int loanDeduction,
    required int otherDeductions,
    required int otherAdditions,
  }) {
    final values = <String>[];

    if (advanceDeduction > 0) {
      values.add('Advance recovery: Rs. $advanceDeduction');
    }

    if (loanDeduction > 0) {
      values.add('Loan recovery: Rs. $loanDeduction');
    }

    if (otherDeductions > 0) {
      values.add(
        'Employee Finance deductions: '
        'Rs. $otherDeductions',
      );
    }

    if (otherAdditions > 0) {
      values.add(
        'Employee Finance additions: '
        'Rs. $otherAdditions',
      );
    }

    if (values.isEmpty) {
      return '';
    }

    return 'Automatically applied: ${values.join(', ')}';
  }
}

class SavePayrollRecord {
  const SavePayrollRecord(this._repository);

  final AccountsRepository _repository;

  Future<void> call(PayrollRecordEntity record) {
    if (record.id.trim().isEmpty) {
      throw ArgumentError('Payroll record ID is required.');
    }

    if (record.employeeId.trim().isEmpty) {
      throw ArgumentError('Employee ID is required.');
    }

    if (record.employeeName.trim().isEmpty) {
      throw ArgumentError('Employee name is required.');
    }

    if (record.basicSalary < 0) {
      throw ArgumentError('Basic salary cannot be negative.');
    }

    if (record.grossSalary < 0) {
      throw ArgumentError('Gross salary cannot be negative.');
    }

    if (record.netSalary < 0) {
      throw ArgumentError('Net salary cannot be negative.');
    }

    if (record.advanceDeduction < 0 ||
        record.loanDeduction < 0 ||
        record.absenceDeduction < 0 ||
        record.deductions < 0) {
      throw ArgumentError('Payroll deductions cannot be negative.');
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
    if (payrollId.trim().isEmpty) {
      throw ArgumentError('Payroll ID is required.');
    }

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
