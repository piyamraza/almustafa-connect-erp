import '../entities/cashbook_entry_entity.dart';
import '../entities/expense_entity.dart';
import '../entities/income_entry_entity.dart';
import '../entities/payroll_record_entity.dart';
import '../repositories/accounts_repository.dart';

class GetCashbookEntries {
  const GetCashbookEntries(this._repository);

  final AccountsRepository _repository;

  Future<List<CashbookEntryEntity>> call() {
    return _repository.getCashbookEntries();
  }
}

class SyncCashbook {
  const SyncCashbook(this._repository);

  final AccountsRepository _repository;

  Future<CashbookSyncResult> call({required String actorId}) async {
    if (actorId.trim().isEmpty) {
      throw ArgumentError(
        'Current authenticated user could not be identified.',
      );
    }

    final responses = await Future.wait<Object>([
      _repository.getIncomeEntries(),
      _repository.getExpenses(),
      _repository.getPayrollRecords(),
      _repository.getCashbookEntries(),
    ]);

    final incomes = responses[0] as List<IncomeEntryEntity>;
    final expenses = responses[1] as List<ExpenseEntity>;
    final payroll = responses[2] as List<PayrollRecordEntity>;
    final existing = responses[3] as List<CashbookEntryEntity>;

    final existingIds = existing.map((entry) => entry.id).toSet();
    var created = 0;
    var skipped = 0;

    for (final income in incomes.where((entry) => entry.isActive)) {
      final id = 'income_${income.id}';
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      await _repository.saveCashbookEntry(
        CashbookEntryEntity(
          id: id,
          entryDate: income.incomeDate,
          entryType: CashbookEntryType.income,
          amount: income.amount,
          description: income.description,
          paymentMethod: income.paymentMethod,
          referenceNumber: income.referenceNumber,
          sourceType: 'incomeEntry',
          sourceId: income.id,
          createdAt: DateTime.now(),
          createdBy: actorId,
        ),
      );
      existingIds.add(id);
      created++;
    }

    for (final expense in expenses.where(
      (entry) => entry.status == ExpenseStatus.paid,
    )) {
      final id = 'expense_${expense.id}';
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      await _repository.saveCashbookEntry(
        CashbookEntryEntity(
          id: id,
          entryDate: expense.expenseDate,
          entryType: CashbookEntryType.expense,
          amount: expense.amount,
          description: expense.description,
          paymentMethod: expense.paymentMethod,
          referenceNumber: expense.referenceNumber,
          sourceType: 'expense',
          sourceId: expense.id,
          createdAt: DateTime.now(),
          createdBy: actorId,
        ),
      );
      existingIds.add(id);
      created++;
    }

    for (final salary in payroll.where(
      (entry) => entry.paymentStatus == PayrollPaymentStatus.paid,
    )) {
      final id = 'payroll_${salary.id}';
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }

      await _repository.saveCashbookEntry(
        CashbookEntryEntity(
          id: id,
          entryDate: salary.paymentDate ?? salary.payrollMonth,
          entryType: CashbookEntryType.expense,
          amount: salary.netSalary,
          description: 'Salary - ${salary.employeeName}',
          paymentMethod: salary.paymentMethod,
          referenceNumber: salary.referenceNumber,
          sourceType: 'payroll',
          sourceId: salary.id,
          createdAt: DateTime.now(),
          createdBy: actorId,
        ),
      );
      existingIds.add(id);
      created++;
    }

    return CashbookSyncResult(created: created, skipped: skipped);
  }
}

class CashbookSyncResult {
  const CashbookSyncResult({required this.created, required this.skipped});

  final int created;
  final int skipped;

  String get message =>
      'Cashbook sync complete: $created created, $skipped unchanged.';
}
