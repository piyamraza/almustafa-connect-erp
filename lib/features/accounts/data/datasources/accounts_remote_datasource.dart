import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/entities/salary_history_entity.dart';
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
  Future<void> deletePayrollProfile(String profileId);
  Future<List<PayrollRecordEntity>> getPayrollRecords();
  Future<void> savePayrollRecord(PayrollRecordEntity record);
  Future<void> updatePayrollStatus({
    required String payrollId,
    required PayrollPaymentStatus status,
    required String actorId,
    String paymentMethod,
    String referenceNumber,
  });
  Future<List<SalaryHistoryEntity>> getSalaryHistory();
  Future<void> applySalaryIncrements({
    required List<SalaryIncrementRequest> increments,
    required String actorId,
  });
  Future<void> initializeProfileBasedPayroll({required String actorId});

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
  Future<void> deletePayrollProfile(String profileId) {
    return _service
        .collection(FirestorePaths.payrollProfiles)
        .doc(profileId)
        .delete();
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
  Future<List<SalaryHistoryEntity>> getSalaryHistory() async {
    final snapshot = await _service
        .collection(FirestorePaths.salaryHistory)
        .get();
    final values = snapshot.docs.map((document) {
      final map = document.data();
      return SalaryHistoryEntity(
        id: document.id,
        employeeId: map['employeeId'] as String? ?? '',
        employeeCode: map['employeeCode'] as String? ?? '',
        employeeName: map['employeeName'] as String? ?? '',
        employeeType: PayrollEmployeeType.values.firstWhere(
          (item) => item.name == map['employeeType'],
          orElse: () => PayrollEmployeeType.other,
        ),
        previousSalary: (map['previousSalary'] as num?)?.toInt() ?? 0,
        incrementAmount: (map['incrementAmount'] as num?)?.toInt() ?? 0,
        newSalary: (map['newSalary'] as num?)?.toInt() ?? 0,
        effectiveAt:
            DateTime.tryParse(map['effectiveAt'] as String? ?? '') ??
            DateTime.now(),
        changedBy: map['changedBy'] as String? ?? '',
        changeType: map['changeType'] as String? ?? 'increment',
        createdAt:
            DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
    values.sort((a, b) => b.effectiveAt.compareTo(a.effectiveAt));
    return values;
  }

  @override
  Future<void> applySalaryIncrements({
    required List<SalaryIncrementRequest> increments,
    required String actorId,
  }) async {
    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }
    for (final increment in increments) {
      if (increment.incrementAmount <= 0) continue;
      final collection = increment.employeeType == PayrollEmployeeType.teacher
          ? FirestorePaths.teachers
          : FirestorePaths.employees;
      final employeeRef = _service
          .collection(collection)
          .doc(increment.employeeId);
      final historyRef = _service
          .collection(FirestorePaths.salaryHistory)
          .doc();
      await _service.instance.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(employeeRef);
        if (!snapshot.exists) {
          throw StateError(
            '${increment.employeeName} profile no longer exists.',
          );
        }
        final data = snapshot.data()!;
        final currentSalary = (data['monthlySalary'] as num?)?.round() ?? 0;
        if (currentSalary != increment.currentSalary) {
          throw StateError(
            '${increment.employeeName} salary changed. Refresh and try again.',
          );
        }
        final newSalary = currentSalary + increment.incrementAmount;
        final now = DateTime.now().toIso8601String();
        transaction.update(employeeRef, {
          'monthlySalary': newSalary,
          'updatedAt': now,
        });
        transaction.set(historyRef, {
          'id': historyRef.id,
          'employeeId': increment.employeeId,
          'employeeCode': increment.employeeCode,
          'employeeName': increment.employeeName,
          'employeeType': increment.employeeType.name,
          'previousSalary': currentSalary,
          'incrementAmount': increment.incrementAmount,
          'newSalary': newSalary,
          'effectiveAt': now,
          'changedBy': actorId,
          'changeType': 'increment',
          'createdAt': now,
        });
      });
    }
  }

  @override
  Future<void> initializeProfileBasedPayroll({required String actorId}) async {
    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }
    final markerRef = _service
        .collection(FirestorePaths.payrollMigrations)
        .doc('profile_based_payroll_v1');
    if ((await markerRef.get()).exists) return;

    final teachers = await _service.collection(FirestorePaths.teachers).get();
    final staff = await _service.collection(FirestorePaths.employees).get();
    final history = _service.collection(FirestorePaths.salaryHistory);
    final openingRecords =
        <
          ({
            String id,
            String employeeId,
            String employeeCode,
            String employeeName,
            PayrollEmployeeType employeeType,
            int salary,
            String effectiveAt,
          })
        >[];
    for (final document in teachers.docs) {
      final data = document.data();
      final salary = (data['monthlySalary'] as num?)?.round() ?? 0;
      if (salary <= 0) continue;
      openingRecords.add((
        id: 'opening_teacher_${document.id}',
        employeeId: document.id,
        employeeCode: data['employeeId'] as String? ?? '',
        employeeName: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
            .trim(),
        employeeType: PayrollEmployeeType.teacher,
        salary: salary,
        effectiveAt:
            data['joiningDate'] as String? ?? DateTime.now().toIso8601String(),
      ));
    }
    for (final document in staff.docs) {
      final data = document.data();
      final salary = (data['monthlySalary'] as num?)?.round() ?? 0;
      if (salary <= 0) continue;
      openingRecords.add((
        id: 'opening_staff_${document.id}',
        employeeId: document.id,
        employeeCode: data['staffId'] as String? ?? '',
        employeeName: '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
            .trim(),
        employeeType: PayrollEmployeeType.administrativeStaff,
        salary: salary,
        effectiveAt:
            data['joiningDate'] as String? ?? DateTime.now().toIso8601String(),
      ));
    }

    for (var start = 0; start < openingRecords.length; start += 400) {
      final end = start + 400 > openingRecords.length
          ? openingRecords.length
          : start + 400;
      final batch = _service.instance.batch();
      for (final item in openingRecords.sublist(start, end)) {
        batch.set(history.doc(item.id), {
          'id': item.id,
          'employeeId': item.employeeId,
          'employeeCode': item.employeeCode,
          'employeeName': item.employeeName,
          'employeeType': item.employeeType.name,
          'previousSalary': 0,
          'incrementAmount': item.salary,
          'newSalary': item.salary,
          'effectiveAt': item.effectiveAt,
          'changedBy': actorId,
          'changeType': 'opening',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    }
    await _deleteAll(FirestorePaths.payrollProfiles);
    await _deleteAll(FirestorePaths.payrollRecords);
    await markerRef.set({
      'id': markerRef.id,
      'completedAt': DateTime.now().toIso8601String(),
      'completedBy': actorId,
      'openingHistoryCount': openingRecords.length,
    });
  }

  Future<void> _deleteAll(String collectionPath) async {
    while (true) {
      final snapshot = await _service
          .collection(collectionPath)
          .limit(400)
          .get();
      if (snapshot.docs.isEmpty) return;
      final batch = _service.instance.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
    }
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
