import '../../../../core/audit/domain/entities/audit_log_entity.dart';
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/teacher_finance_account_entity.dart';
import '../../domain/entities/teacher_finance_transaction_entity.dart';
import '../../domain/repositories/teacher_finance_repository.dart';
import '../models/teacher_finance_models.dart';

class TeacherFinanceRepositoryImpl implements TeacherFinanceRepository {
  TeacherFinanceRepositoryImpl({
    required FirebaseFirestoreService firestoreService,
    required AuditService auditService,
  }) : _firestoreService = firestoreService,
       _auditService = auditService;

  static const _accountsCollection = 'teacher_finance_accounts';
  static const _transactionsCollection = 'teacher_finance_transactions';

  final FirebaseFirestoreService _firestoreService;
  final AuditService _auditService;

  @override
  String generateAccountId() {
    return _firestoreService.collection(_accountsCollection).doc().id;
  }

  @override
  String generateTransactionId() {
    return _firestoreService.collection(_transactionsCollection).doc().id;
  }

  @override
  Future<List<TeacherFinanceAccountEntity>> getAccounts({
    String? employeeId,
    TeacherFinanceStatus? status,
  }) async {
    final snapshot = await _firestoreService
        .collection(_accountsCollection)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => TeacherFinanceAccountModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (account) =>
                  (employeeId == null || account.employeeId == employeeId) &&
                  (status == null || account.status == status),
            )
            .toList()
          ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return List.unmodifiable(values);
  }

  @override
  Future<List<TeacherFinanceTransactionEntity>> getTransactions({
    String? accountId,
    String? employeeId,
  }) async {
    final snapshot = await _firestoreService
        .collection(_transactionsCollection)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => TeacherFinanceTransactionModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (transaction) =>
                  (accountId == null || transaction.accountId == accountId) &&
                  (employeeId == null || transaction.employeeId == employeeId),
            )
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return List.unmodifiable(values);
  }

  @override
  Future<void> createAccount(TeacherFinanceAccountEntity account) async {
    if (account.principalAmount <= 0) {
      throw StateError('Advance/loan amount must be greater than zero.');
    }
    if (account.monthlyRecoveryAmount <= 0) {
      throw StateError('Monthly recovery amount must be greater than zero.');
    }
    if (account.monthlyRecoveryAmount > account.principalAmount) {
      throw StateError('Monthly recovery cannot exceed the approved amount.');
    }

    final activeAccounts = await getAccounts(
      employeeId: account.employeeId,
      status: TeacherFinanceStatus.active,
    );

    if (activeAccounts.any((item) => item.financeType == account.financeType)) {
      throw StateError(
        'This employee already has an active '
        '${account.financeType.name}.',
      );
    }

    final model = TeacherFinanceAccountModel.fromEntity(account);
    final transaction = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: TeacherFinanceTransactionType.disbursement,
      amount: account.principalAmount,
      transactionDate: account.issueDate,
      payrollId: '',
      referenceNumber: '',
      notes: account.notes,
      createdBy: account.approvedBy,
      createdAt: account.createdAt,
    );

    final batch = _firestoreService.instance.batch();
    batch.set(
      _firestoreService.collection(_accountsCollection).doc(account.id),
      model.toMap(),
    );
    batch.set(
      _firestoreService.collection(_transactionsCollection).doc(transaction.id),
      TeacherFinanceTransactionModel.fromEntity(transaction).toMap(),
    );
    await batch.commit();

    await _auditService.logCreate(
      module: 'Payroll Advances',
      recordId: account.id,
      description:
          '${account.financeType.name} approved for ${account.employeeName}',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> saveTransaction(TeacherFinanceTransactionEntity transaction) {
    return _firestoreService
        .collection(_transactionsCollection)
        .doc(transaction.id)
        .set(TeacherFinanceTransactionModel.fromEntity(transaction).toMap());
  }

  @override
  Future<void> applyRecovery({
    required String accountId,
    required int amount,
    required TeacherFinanceTransactionType transactionType,
    required String actorId,
    String payrollId = '',
    String referenceNumber = '',
    String notes = '',
  }) async {
    if (amount <= 0) {
      throw StateError('Recovery amount must be greater than zero.');
    }

    final document = await _firestoreService
        .collection(_accountsCollection)
        .doc(accountId)
        .get();

    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Advance/loan account was not found.');
    }

    final account = TeacherFinanceAccountModel.fromMap({
      ...data,
      'id': document.id,
    });

    if (!account.isActive) {
      throw StateError('This advance/loan account is not active.');
    }

    final appliedAmount = amount > account.outstandingAmount
        ? account.outstandingAmount
        : amount;
    final recovered = account.recoveredAmount + appliedAmount;
    final outstanding = account.outstandingAmount - appliedAmount;
    final now = DateTime.now();
    final status = outstanding <= 0
        ? TeacherFinanceStatus.closed
        : TeacherFinanceStatus.active;

    final transaction = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: transactionType,
      amount: appliedAmount,
      transactionDate: now,
      payrollId: payrollId,
      referenceNumber: referenceNumber,
      notes: notes,
      createdBy: actorId,
      createdAt: now,
    );

    final batch = _firestoreService.instance.batch();
    batch.update(
      _firestoreService.collection(_accountsCollection).doc(account.id),
      {
        'recoveredAmount': recovered,
        'outstandingAmount': outstanding,
        'status': status.name,
        'closedAt': status == TeacherFinanceStatus.closed
            ? now.toIso8601String()
            : null,
        'updatedAt': now.toIso8601String(),
      },
    );
    batch.set(
      _firestoreService.collection(_transactionsCollection).doc(transaction.id),
      TeacherFinanceTransactionModel.fromEntity(transaction).toMap(),
    );
    await batch.commit();

    await _auditService.log(
      module: 'Payroll Advances',
      action: AuditAction.collectPayment,
      recordId: account.id,
      description: 'Rs. $appliedAmount recovered from ${account.employeeName}',
      oldValues: {
        'recoveredAmount': account.recoveredAmount,
        'outstandingAmount': account.outstandingAmount,
        'status': account.status.name,
      },
      newValues: {
        'recoveredAmount': recovered,
        'outstandingAmount': outstanding,
        'status': status.name,
        'payrollId': payrollId,
        'transactionType': transactionType.name,
      },
    );
  }

  @override
  Future<void> cancelAccount({
    required String accountId,
    required String actorId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }

    final document = await _firestoreService
        .collection(_accountsCollection)
        .doc(accountId)
        .get();

    final data = document.data();
    if (!document.exists || data == null) {
      throw StateError('Advance/loan account was not found.');
    }

    final account = TeacherFinanceAccountModel.fromMap({
      ...data,
      'id': document.id,
    });

    if (account.recoveredAmount > 0) {
      throw StateError(
        'An account with recorded recoveries cannot be cancelled.',
      );
    }

    final now = DateTime.now();
    final transaction = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: TeacherFinanceTransactionType.cancellation,
      amount: account.outstandingAmount,
      transactionDate: now,
      payrollId: '',
      referenceNumber: '',
      notes: reason.trim(),
      createdBy: actorId,
      createdAt: now,
    );

    final batch = _firestoreService.instance.batch();
    batch.update(
      _firestoreService.collection(_accountsCollection).doc(account.id),
      {
        'status': TeacherFinanceStatus.cancelled.name,
        'outstandingAmount': 0,
        'closedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    );
    batch.set(
      _firestoreService.collection(_transactionsCollection).doc(transaction.id),
      TeacherFinanceTransactionModel.fromEntity(transaction).toMap(),
    );
    await batch.commit();

    await _auditService.logDelete(
      module: 'Payroll Advances',
      recordId: account.id,
      description:
          '${account.financeType.name} cancelled for ${account.employeeName}',
      oldValues: TeacherFinanceAccountModel.fromEntity(account).toMap(),
    );
  }
}
