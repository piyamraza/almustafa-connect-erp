import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../models/accounts_models.dart';
import '../models/accounts_payroll_models.dart';
import 'income_remote_datasource_extension.dart';
import 'profit_loss_remote_datasource.dart';
import 'cashbook_remote_datasource.dart';

abstract class AccountsRemoteDataSource {
  Future<List<ExpenseCategoryEntity>> getExpenseCategories();
  Future<void> saveExpenseCategory(ExpenseCategoryEntity category);
  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  });
  Future<List<ExpenseEntity>> getExpenses();
  Future<void> saveExpense(ExpenseEntity expense);
  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  });

  Future<List<PayrollProfileEntity>> getPayrollProfiles();
  Future<void> savePayrollProfile(PayrollProfileEntity profile);
  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  });
  Future<List<PayrollRecordEntity>> getPayrollRecords();
  Future<void> savePayrollRecord(PayrollRecordEntity record);
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod,
    String referenceNumber,
  });

  Future<List<IncomeEntryEntity>> getIncomeEntries();
  Future<void> saveIncomeEntry(IncomeEntryEntity entry);
  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  });
  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss();
  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot);
  Future<List<CashbookEntryEntity>> getCashbookEntries();
  Future<void> saveCashbookEntry(CashbookEntryEntity entry);
}

class AccountsRemoteDataSourceImpl implements AccountsRemoteDataSource {
  AccountsRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  IncomeRemoteDataSource get _incomeSource => IncomeRemoteDataSource(_service);

  ProfitLossRemoteDataSource get _profitLossSource =>
      ProfitLossRemoteDataSource(_service);

  CashbookRemoteDataSource get _cashbookSource =>
      CashbookRemoteDataSource(_service);

  @override
  Future<List<ExpenseCategoryEntity>> getExpenseCategories() async {
    final snapshot = await _service
        .collection(FirestorePaths.expenseCategories)
        .get();
    final values = snapshot.docs
        .map(
          (doc) => ExpenseCategoryModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
    values.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return values;
  }

  @override
  Future<void> saveExpenseCategory(ExpenseCategoryEntity category) {
    final model = ExpenseCategoryModel(
      id: category.id,
      name: category.name,
      description: category.description,
      isActive: category.isActive,
      displayOrder: category.displayOrder,
      createdAt: category.createdAt,
      updatedAt: category.updatedAt,
    );
    return _service
        .collection(FirestorePaths.expenseCategories)
        .doc(category.id)
        .set(model.toMap());
  }

  @override
  Future<void> setExpenseCategoryActive({
    required String categoryId,
    required bool isActive,
  }) {
    return _service
        .collection(FirestorePaths.expenseCategories)
        .doc(categoryId)
        .update({
          'isActive': isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  @override
  Future<List<ExpenseEntity>> getExpenses() async {
    final snapshot = await _service.collection(FirestorePaths.expenses).get();
    final values = snapshot.docs
        .map((doc) => ExpenseModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return values;
  }

  @override
  Future<void> saveExpense(ExpenseEntity expense) {
    final model = ExpenseModel(
      id: expense.id,
      categoryId: expense.categoryId,
      categoryName: expense.categoryName,
      amount: expense.amount,
      expenseDate: expense.expenseDate,
      description: expense.description,
      payeeName: expense.payeeName,
      paymentMethod: expense.paymentMethod,
      referenceNumber: expense.referenceNumber,
      receiptUrl: expense.receiptUrl,
      status: expense.status,
      enteredBy: expense.enteredBy,
      approvedBy: expense.approvedBy,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      sourceType: expense.sourceType,
      sourceId: expense.sourceId,
      approvedAt: expense.approvedAt,
    );
    return _service
        .collection(FirestorePaths.expenses)
        .doc(expense.id)
        .set(model.toMap());
  }

  @override
  Future<void> updateExpenseStatus({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  }) {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{'status': status.name, 'updatedAt': now};
    if (status == ExpenseStatus.approved || status == ExpenseStatus.paid) {
      updates['approvedBy'] = actorId;
      updates['approvedAt'] = now;
    }
    return _service
        .collection(FirestorePaths.expenses)
        .doc(expenseId)
        .update(updates);
  }

  @override
  Future<List<PayrollProfileEntity>> getPayrollProfiles() async {
    final snapshot = await _service
        .collection(FirestorePaths.payrollProfiles)
        .get();
    final values = snapshot.docs
        .map(
          (doc) => PayrollProfileModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
    values.sort((a, b) => a.employeeName.compareTo(b.employeeName));
    return values;
  }

  @override
  Future<void> savePayrollProfile(PayrollProfileEntity profile) {
    final model = PayrollProfileModel.fromEntity(profile);
    return _service
        .collection(FirestorePaths.payrollProfiles)
        .doc(profile.id)
        .set(model.toMap());
  }

  @override
  Future<void> setPayrollProfileActive({
    required String profileId,
    required bool isActive,
  }) {
    return _service
        .collection(FirestorePaths.payrollProfiles)
        .doc(profileId)
        .update({
          'isActive': isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  @override
  Future<List<PayrollRecordEntity>> getPayrollRecords() async {
    final snapshot = await _service
        .collection(FirestorePaths.payrollRecords)
        .get();
    final values = snapshot.docs
        .map((doc) => PayrollRecordModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort((a, b) => b.payrollMonth.compareTo(a.payrollMonth));
    return values;
  }

  @override
  Future<void> savePayrollRecord(PayrollRecordEntity record) {
    final model = PayrollRecordModel.fromEntity(record);
    return _service
        .collection(FirestorePaths.payrollRecords)
        .doc(record.id)
        .set(model.toMap());
  }

  @override
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod = '',
    String referenceNumber = '',
  }) {
    final now = DateTime.now().toIso8601String();
    final updates = <String, dynamic>{
      'paymentStatus': status.name,
      'updatedAt': now,
    };
    if (status == PayrollPaymentStatus.approved) {
      updates['approvedBy'] = actorId;
      updates['approvedAt'] = now;
    }
    if (status == PayrollPaymentStatus.paid) {
      updates['paidBy'] = actorId;
      updates['paymentDate'] = now;
      updates['paymentMethod'] = paymentMethod;
      updates['referenceNumber'] = referenceNumber;
    }
    return _service
        .collection(FirestorePaths.payrollRecords)
        .doc(payrollId)
        .update(updates);
  }

  @override
  Future<List<IncomeEntryEntity>> getIncomeEntries() =>
      _incomeSource.getIncomeEntries();

  @override
  Future<void> saveIncomeEntry(IncomeEntryEntity entry) =>
      _incomeSource.saveIncomeEntry(entry);

  @override
  Future<void> reverseIncomeEntry({
    required String incomeEntryId,
    required String reason,
  }) => _incomeSource.reverseIncomeEntry(
    incomeEntryId: incomeEntryId,
    reason: reason,
  );

  @override
  Future<List<MonthlyProfitLossEntity>> getMonthlyProfitLoss() =>
      _profitLossSource.getSnapshots();

  @override
  Future<void> saveMonthlyProfitLoss(MonthlyProfitLossEntity snapshot) =>
      _profitLossSource.saveSnapshot(snapshot);

  @override
  Future<List<CashbookEntryEntity>> getCashbookEntries() =>
      _cashbookSource.getEntries();

  @override
  Future<void> saveCashbookEntry(CashbookEntryEntity entry) =>
      _cashbookSource.saveEntry(entry);
}
