import '../../../../core/audit/domain/entities/audit_log_entity.dart';
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/repositories/accounts_repository.dart';
import '../datasources/accounts_remote_datasource.dart';

class AccountsRepositoryImpl implements AccountsRepository {
  AccountsRepositoryImpl({
    required this._source,
    required AuditService auditService,
  }) : _auditService = auditService;

  final AccountsRemoteDataSource _source;
  final AuditService _auditService;

  @override
  Future<List<ExpenseCategoryEntity>> getExpenseCategories() =>
      _source.getExpenseCategories();

  @override
  Future<void> saveExpenseCategory(ExpenseCategoryEntity category) =>
      _source.saveExpenseCategory(category);

  @override
  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  }) => _source.setExpenseCategoryActive(
    categoryId: categoryId,
    isActive: isActive,
  );

  @override
  Future<List<ExpenseEntity>> getExpenses() => _source.getExpenses();

  @override
  Future<void> saveExpense(ExpenseEntity expense) =>
      _source.saveExpense(expense);

  @override
  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  }) => _source.updateExpenseStatus(
    expenseId: expenseId,
    status: status,
    actorId: actorId,
  );

  @override
  Future<List<PayrollProfileEntity>> getPayrollProfiles() =>
      _source.getPayrollProfiles();

  @override
  Future<void> savePayrollProfile(PayrollProfileEntity profile) async {
    final profiles = await _source.getPayrollProfiles();
    final previous = _findProfile(profiles, profile.id);

    await _source.savePayrollProfile(profile);

    if (previous == null) {
      await _auditService.logCreate(
        module: 'Payroll',
        recordId: profile.id,
        description: 'Salary profile created for ${profile.employeeName}',
        newValues: _profileValues(profile),
      );
      return;
    }

    await _auditService.logUpdate(
      module: 'Payroll',
      recordId: profile.id,
      description: 'Salary profile updated for ${profile.employeeName}',
      oldValues: _profileValues(previous),
      newValues: _profileValues(profile),
    );
  }

  @override
  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  }) async {
    final profiles = await _source.getPayrollProfiles();
    final previous = _findProfile(profiles, profileId);

    await _source.setPayrollProfileActive(
      profileId: profileId,
      isActive: isActive,
    );

    await _auditService.logUpdate(
      module: 'Payroll',
      recordId: profileId,
      description: isActive
          ? 'Salary profile activated'
          : 'Salary profile deactivated',
      oldValues: {if (previous != null) ..._profileValues(previous)},
      newValues: {'isActive': isActive},
    );
  }

  @override
  Future<List<PayrollRecordEntity>> getPayrollRecords() =>
      _source.getPayrollRecords();

  @override
  Future<void> savePayrollRecord(PayrollRecordEntity record) async {
    final records = await _source.getPayrollRecords();
    final previous = _findRecord(records, record.id);

    await _source.savePayrollRecord(record);

    if (previous == null) {
      await _auditService.logCreate(
        module: 'Payroll',
        recordId: record.id,
        description:
            'Monthly payroll generated for ${record.employeeName} (${_monthKey(record.payrollMonth)})',
        newValues: _recordValues(record),
      );
      return;
    }

    await _auditService.logUpdate(
      module: 'Payroll',
      recordId: record.id,
      description:
          'Payroll record updated for ${record.employeeName} (${_monthKey(record.payrollMonth)})',
      oldValues: _recordValues(previous),
      newValues: _recordValues(record),
    );
  }

  @override
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod = '',
    String referenceNumber = '',
  }) async {
    final records = await _source.getPayrollRecords();
    final previous = _findRecord(records, payrollId);

    await _source.updatePayrollStatus(
      payrollId: payrollId,
      status: status,
      actorId: actorId,
      paymentMethod: paymentMethod,
      referenceNumber: referenceNumber,
    );

    final action = switch (status) {
      PayrollPaymentStatus.approved => AuditAction.approve,
      PayrollPaymentStatus.paid => AuditAction.collectPayment,
      PayrollPaymentStatus.cancelled => AuditAction.delete,
      _ => AuditAction.update,
    };

    await _auditService.log(
      module: 'Payroll',
      action: action,
      recordId: payrollId,
      description: _statusDescription(status, previous),
      oldValues: previous == null ? const {} : _recordValues(previous),
      newValues: {
        'paymentStatus': status.name,
        'actorId': actorId,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
  // =====================================================
  // Payroll Automatic Deductions
  // =====================================================

  @override
  Future<int> getAdvanceDeductionForPayroll({
    required String employeeId,
  }) async {
    // Phase 3:
    // This will read active Advance accounts and return
    // the monthly recovery amount.
    return 0;
  }

  @override
  Future<int> getLoanDeductionForPayroll({required String employeeId}) async {
    // Phase 3:
    // This will read active Loan accounts and return
    // the monthly recovery amount.
    return 0;
  }

  @override
  Future<int> getOtherPayrollDeductions({required String employeeId}) async {
    // Reserved for future deductions
    // (Income Tax, EOBI, PF, Insurance etc.)
    return 0;
  }

  @override
  Future<List<IncomeEntryEntity>> getIncomeEntries() =>
      _source.getIncomeEntries();

  @override
  Future<void> saveIncomeEntry(IncomeEntryEntity entry) =>
      _source.saveIncomeEntry(entry);

  @override
  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  }) =>
      _source.reverseIncomeEntry(incomeEntryId: incomeEntryId, reason: reason);

  @override
  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss() =>
      _source.getMonthlyProfitLoss();

  @override
  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot) =>
      _source.saveMonthlyProfitLoss(snapshot);

  @override
  Future<List<CashbookEntryEntity>> getCashbookEntries() =>
      _source.getCashbookEntries();

  @override
  Future<void> saveCashbookEntry(CashbookEntryEntity entry) =>
      _source.saveCashbookEntry(entry);

  PayrollProfileEntity? _findProfile(
    List<PayrollProfileEntity> profiles,
    String id,
  ) {
    for (final item in profiles) {
      if (item.id == id) return item;
    }
    return null;
  }

  PayrollRecordEntity? _findRecord(
    List<PayrollRecordEntity> records,
    String id,
  ) {
    for (final item in records) {
      if (item.id == id) return item;
    }
    return null;
  }

  Map<String, dynamic> _profileValues(PayrollProfileEntity profile) => {
    'employeeId': profile.employeeId,
    'employeeName': profile.employeeName,
    'basicSalary': profile.basicSalary,
    'fixedAllowances': profile.fixedAllowances,
    'fixedDeductions': profile.fixedDeductions,
    'isActive': profile.isActive,
    'createdAt': profile.createdAt.toIso8601String(),
    'updatedAt': profile.updatedAt.toIso8601String(),
  };

  Map<String, dynamic> _recordValues(PayrollRecordEntity record) => {
    'employeeId': record.employeeId,
    'employeeName': record.employeeName,
    'payrollMonth': record.payrollMonth.toIso8601String(),
    'basicSalary': record.basicSalary,
    'allowances': record.allowances,
    'deductions': record.deductions,
    'absenceDeduction': record.absenceDeduction,
    'advanceDeduction': record.advanceDeduction,
    'loanDeduction': record.loanDeduction,
    'bonus': record.bonus,
    'grossSalary': record.grossSalary,
    'netSalary': record.netSalary,
    'paymentStatus': record.paymentStatus.name,
    'paymentDate': record.paymentDate?.toIso8601String(),
    'paymentMethod': record.paymentMethod,
    'referenceNumber': record.referenceNumber,
    'remarks': record.remarks,
    'generatedBy': record.generatedBy,
    'approvedBy': record.approvedBy,
    'approvedAt': record.approvedAt?.toIso8601String(),
    'paidBy': record.paidBy,
    'createdAt': record.createdAt.toIso8601String(),
    'updatedAt': record.updatedAt.toIso8601String(),
  };

  String _statusDescription(
    PayrollPaymentStatus status,
    PayrollRecordEntity? record,
  ) {
    final employee = record?.employeeName.trim() ?? '';
    final suffix = employee.isEmpty ? '' : ' for $employee';

    return switch (status) {
      PayrollPaymentStatus.draft => 'Payroll moved to draft$suffix',
      PayrollPaymentStatus.generated => 'Payroll generated$suffix',
      PayrollPaymentStatus.approved => 'Payroll approved$suffix',
      PayrollPaymentStatus.paid => 'Salary paid$suffix',
      PayrollPaymentStatus.cancelled => 'Payroll cancelled$suffix',
    };
  }

  String _monthKey(DateTime month) {
    final monthValue = month.month.toString().padLeft(2, '0');
    return '${month.year}-$monthValue';
  }
}
