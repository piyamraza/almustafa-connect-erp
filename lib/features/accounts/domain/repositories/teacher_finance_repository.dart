import '../entities/teacher_finance_account_entity.dart';
import '../entities/teacher_finance_transaction_entity.dart';

abstract class TeacherFinanceRepository {
  String generateAccountId();

  String generateTransactionId();

  Future<List<TeacherFinanceAccountEntity>> getAccounts({
    String? employeeId,
    TeacherFinanceStatus? status,
  });

  Future<List<TeacherFinanceTransactionEntity>> getTransactions({
    String? accountId,
    String? employeeId,
  });

  Future<void> createAccount(TeacherFinanceAccountEntity account);

  Future<void> saveTransaction(TeacherFinanceTransactionEntity transaction);

  Future<void> applyRecovery({
    required String accountId,
    required int amount,
    required TeacherFinanceTransactionType transactionType,
    required String actorId,
    String payrollId,
    String referenceNumber,
    String notes,
  });

  Future<void> cancelAccount({
    required String accountId,
    required String actorId,
    required String reason,
  });
}
