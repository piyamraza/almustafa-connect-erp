import '../../../../core/audit/domain/entities/audit_log_entity.dart';
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/teacher_finance_account_entity.dart';
import '../../domain/entities/teacher_finance_transaction_entity.dart';
import '../../domain/repositories/teacher_finance_repository.dart';
import '../models/teacher_finance_models.dart';

class TeacherFinanceRepositoryImpl implements TeacherFinanceRepository {
  TeacherFinanceRepositoryImpl({
    required this._firestoreService,
    required this._auditService,
  });

  static const String _accountsCollection = 'teacher_finance_accounts';
  static const String _transactionsCollection = 'teacher_finance_transactions';

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

  // =========================================================
  // Employee Finance Accounts
  // =========================================================

  @override
  Future<List<TeacherFinanceAccountEntity>> getAccounts({
  String? employeeId,
  TeacherFinanceEmployeeType? employeeType,
  TeacherFinanceType? financeType,
  TeacherFinanceRecoveryMode? recoveryMode,
  TeacherFinanceStatus? status,
}) async {
    final snapshot = await _firestoreService
        .collection(_accountsCollection)
        .get();

    final accounts =
        snapshot.docs
            .map(
              (document) => TeacherFinanceAccountModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where((account) {
              if (employeeId != null &&
    account.employeeId.trim() != employeeId.trim()) {
  return false;
}

if (employeeType != null && account.employeeType != employeeType) {
  return false;
}

if (financeType != null && account.financeType != financeType) {
  return false;
}

              if (recoveryMode != null &&
                  account.recoveryMode != recoveryMode) {
                return false;
              }

              if (status != null && account.status != status) {
                return false;
              }

              return true;
            })
            .toList()
          ..sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return List.unmodifiable(accounts);
  }

  @override
  Future<TeacherFinanceAccountEntity?> getAccountById({
    required String accountId,
  }) async {
    final normalizedId = accountId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final document = await _firestoreService
        .collection(_accountsCollection)
        .doc(normalizedId)
        .get();

    final data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return TeacherFinanceAccountModel.fromMap({...data, 'id': document.id});
  }

  @override
  Future<void> createAccount(TeacherFinanceAccountEntity account) async {
    _validateAccount(account);

    final existingAccount = await getAccountById(accountId: account.id);

    if (existingAccount != null) {
      throw StateError('Employee Finance account already exists.');
    }

    if (_requiresUniqueActiveAccount(account.financeType)) {
      final activeAccounts = await getAccounts(
  employeeId: account.employeeId,
  employeeType: account.employeeType,
  financeType: account.financeType,
  status: TeacherFinanceStatus.active,
);

      if (activeAccounts.isNotEmpty) {
        throw StateError(
          'This employee already has an active '
          '${_financeTypeLabel(account.financeType)} account.',
        );
      }
    }

    final model = TeacherFinanceAccountModel.fromEntity(account);

    final disbursement = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: TeacherFinanceTransactionType.disbursement,
      amount: account.principalAmount,
      transactionDate: account.issueDate,
      payrollId: '',
      payrollMonth: null,
      referenceNumber: '',
      notes: account.notes,
      createdBy: account.approvedBy,
      createdAt: account.createdAt,
      isPostedToPayroll: false,
      isReversed: false,
      reversedAt: null,
      reversedBy: '',
      reversalReason: '',
    );

    final batch = _firestoreService.instance.batch();

    batch.set(
      _firestoreService.collection(_accountsCollection).doc(account.id),
      model.toMap(),
    );

    batch.set(
      _firestoreService
          .collection(_transactionsCollection)
          .doc(disbursement.id),
      TeacherFinanceTransactionModel.fromEntity(disbursement).toMap(),
    );

    await batch.commit();

    await _auditService.logCreate(
      module: 'Employee Finance',
      recordId: account.id,
      description:
          '${_financeTypeLabel(account.financeType)} approved for '
          '${account.employeeName}',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> updateAccount(TeacherFinanceAccountEntity account) async {
    _validateAccount(account);

    final previous = await getAccountById(accountId: account.id);

    if (previous == null) {
      throw StateError('Employee Finance account was not found.');
    }

    if (previous.status != TeacherFinanceStatus.active) {
      throw StateError('Only active Employee Finance accounts can be updated.');
    }

    final updated = account.copyWith(
      recoveredAmount: previous.recoveredAmount,
      outstandingAmount: previous.outstandingAmount,
      createdAt: previous.createdAt,
      updatedAt: DateTime.now(),
      closedAt: previous.closedAt,
    );

    final model = TeacherFinanceAccountModel.fromEntity(updated);

    await _firestoreService
        .collection(_accountsCollection)
        .doc(updated.id)
        .set(model.toMap());

    await _auditService.logUpdate(
      module: 'Employee Finance',
      recordId: updated.id,
      description:
          '${_financeTypeLabel(updated.financeType)} account updated for '
          '${updated.employeeName}',
      oldValues: TeacherFinanceAccountModel.fromEntity(previous).toMap(),
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> cancelAccount({
    required String accountId,
    required String actorId,
    required String reason,
  }) async {
    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }

    final account = await getAccountById(accountId: accountId);

    if (account == null) {
      throw StateError('Employee Finance account was not found.');
    }

    if (account.status != TeacherFinanceStatus.active) {
      throw StateError('This Employee Finance account is not active.');
    }

    if (account.recoveredAmount > 0) {
      throw StateError(
        'An account with recorded recoveries cannot be cancelled.',
      );
    }

    final now = DateTime.now();

    final cancellation = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: TeacherFinanceTransactionType.cancellation,
      amount: account.outstandingAmount,
      transactionDate: now,
      payrollId: '',
      payrollMonth: null,
      referenceNumber: '',
      notes: reason.trim(),
      createdBy: actorId,
      createdAt: now,
      isPostedToPayroll: false,
      isReversed: false,
      reversedAt: null,
      reversedBy: '',
      reversalReason: '',
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
      _firestoreService
          .collection(_transactionsCollection)
          .doc(cancellation.id),
      TeacherFinanceTransactionModel.fromEntity(cancellation).toMap(),
    );

    await batch.commit();

    await _auditService.logDelete(
      module: 'Employee Finance',
      recordId: account.id,
      description:
          '${_financeTypeLabel(account.financeType)} cancelled for '
          '${account.employeeName}',
      oldValues: TeacherFinanceAccountModel.fromEntity(account).toMap(),
    );
  }

  // =========================================================
  // Employee Finance Transactions
  // =========================================================

  @override
  Future<List<TeacherFinanceTransactionEntity>> getTransactions({
    String? accountId,
    String? employeeId,
    TeacherFinanceTransactionType? transactionType,
    DateTime? payrollMonth,
    bool? isPostedToPayroll,
    bool includeReversed = false,
  }) async {
    final snapshot = await _firestoreService
        .collection(_transactionsCollection)
        .get();

    final transactions =
        snapshot.docs
            .map(
              (document) => TeacherFinanceTransactionModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where((transaction) {
              if (accountId != null &&
                  transaction.accountId.trim() != accountId.trim()) {
                return false;
              }

              if (employeeId != null &&
                  transaction.employeeId.trim() != employeeId.trim()) {
                return false;
              }

              if (transactionType != null &&
                  transaction.transactionType != transactionType) {
                return false;
              }

              if (payrollMonth != null &&
                  !transaction.appliesToPayrollMonth(payrollMonth)) {
                return false;
              }

              if (isPostedToPayroll != null &&
                  transaction.isPostedToPayroll != isPostedToPayroll) {
                return false;
              }

              if (!includeReversed && transaction.isReversed) {
                return false;
              }

              return true;
            })
            .toList()
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return List.unmodifiable(transactions);
  }

  @override
  Future<TeacherFinanceTransactionEntity?> getTransactionById({
    required String transactionId,
  }) async {
    final normalizedId = transactionId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final document = await _firestoreService
        .collection(_transactionsCollection)
        .doc(normalizedId)
        .get();

    final data = document.data();

    if (!document.exists || data == null) {
      return null;
    }

    return TeacherFinanceTransactionModel.fromMap({...data, 'id': document.id});
  }

  @override
  Future<void> saveTransaction(
    TeacherFinanceTransactionEntity transaction,
  ) async {
    _validateTransaction(transaction);

    final model = TeacherFinanceTransactionModel.fromEntity(transaction);

    await _firestoreService
        .collection(_transactionsCollection)
        .doc(transaction.id)
        .set(model.toMap());
  }

  @override
  Future<void> createStandaloneTransaction(
    TeacherFinanceTransactionEntity transaction,
  ) async {
    _validateTransaction(transaction);

    if (!_isStandaloneTransaction(transaction.transactionType)) {
      throw StateError(
        'This transaction type requires an Employee Finance account.',
      );
    }

    if (transaction.accountId.trim().isNotEmpty) {
      throw StateError(
        'Standalone Employee Finance transactions must not have '
        'an account ID.',
      );
    }

    final existing = await getTransactionById(transactionId: transaction.id);

    if (existing != null) {
      throw StateError('Employee Finance transaction already exists.');
    }

    final model = TeacherFinanceTransactionModel.fromEntity(transaction);

    await _firestoreService
        .collection(_transactionsCollection)
        .doc(transaction.id)
        .set(model.toMap());

    await _auditService.logCreate(
      module: 'Employee Finance',
      recordId: transaction.id,
      description:
          '${_transactionTypeLabel(transaction.transactionType)} created '
          'for ${transaction.employeeName}',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> reverseTransaction({
    required String transactionId,
    required String actorId,
    required String reason,
  }) async {
    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    if (reason.trim().isEmpty) {
      throw StateError('Reversal reason is required.');
    }

    final transaction = await getTransactionById(transactionId: transactionId);

    if (transaction == null) {
      throw StateError('Employee Finance transaction was not found.');
    }

    if (transaction.isReversed) {
      throw StateError('This transaction is already reversed.');
    }

    if (transaction.transactionType ==
            TeacherFinanceTransactionType.payrollRecovery ||
        transaction.transactionType ==
            TeacherFinanceTransactionType.manualRecovery) {
      throw StateError(
        'Recovery transactions must be reversed through payroll '
        'or account reversal.',
      );
    }

    final now = DateTime.now();

    await _firestoreService
        .collection(_transactionsCollection)
        .doc(transaction.id)
        .update({
          'isReversed': true,
          'reversedAt': now.toIso8601String(),
          'reversedBy': actorId,
          'reversalReason': reason.trim(),
        });

    await _auditService.logUpdate(
      module: 'Employee Finance',
      recordId: transaction.id,
      description:
          '${_transactionTypeLabel(transaction.transactionType)} reversed '
          'for ${transaction.employeeName}',
      oldValues: TeacherFinanceTransactionModel.fromEntity(transaction).toMap(),
      newValues: {
        'isReversed': true,
        'reversedAt': now.toIso8601String(),
        'reversedBy': actorId,
        'reversalReason': reason.trim(),
      },
    );
  }

  // =========================================================
  // Advance / Loan Recovery
  // =========================================================

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

    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    if (transactionType != TeacherFinanceTransactionType.payrollRecovery &&
        transactionType != TeacherFinanceTransactionType.manualRecovery) {
      throw StateError('Invalid Employee Finance recovery transaction type.');
    }

    final account = await getAccountById(accountId: accountId);

    if (account == null) {
      throw StateError('Advance/Loan account was not found.');
    }

    if (!account.isRecoverable ||
        account.status != TeacherFinanceStatus.active) {
      throw StateError('This Advance/Loan account is not recoverable.');
    }

    if (transactionType == TeacherFinanceTransactionType.payrollRecovery &&
        payrollId.trim().isNotEmpty) {
      final existingRecoveries = await getTransactions(
        accountId: account.id,
        transactionType: TeacherFinanceTransactionType.payrollRecovery,
        includeReversed: false,
      );

      final alreadyPosted = existingRecoveries.any(
        (transaction) => transaction.payrollId.trim() == payrollId.trim(),
      );

      if (alreadyPosted) {
        return;
      }
    }

    final appliedAmount = amount > account.outstandingAmount
        ? account.outstandingAmount
        : amount;

    final recoveredAmount = account.recoveredAmount + appliedAmount;

    final outstandingAmount = account.outstandingAmount - appliedAmount;

    final now = DateTime.now();

    final updatedStatus = outstandingAmount <= 0
        ? TeacherFinanceStatus.closed
        : TeacherFinanceStatus.active;

    final recovery = TeacherFinanceTransactionEntity(
      id: generateTransactionId(),
      accountId: account.id,
      employeeId: account.employeeId,
      employeeName: account.employeeName,
      transactionType: transactionType,
      amount: appliedAmount,
      transactionDate: now,
      payrollId: payrollId.trim(),
      payrollMonth: null,
      referenceNumber: referenceNumber.trim(),
      notes: notes.trim(),
      createdBy: actorId,
      createdAt: now,
      isPostedToPayroll:
          transactionType == TeacherFinanceTransactionType.payrollRecovery,
      isReversed: false,
      reversedAt: null,
      reversedBy: '',
      reversalReason: '',
    );

    final batch = _firestoreService.instance.batch();

    batch.update(
      _firestoreService.collection(_accountsCollection).doc(account.id),
      {
        'recoveredAmount': recoveredAmount,
        'outstandingAmount': outstandingAmount,
        'status': updatedStatus.name,
        'closedAt': updatedStatus == TeacherFinanceStatus.closed
            ? now.toIso8601String()
            : null,
        'updatedAt': now.toIso8601String(),
      },
    );

    batch.set(
      _firestoreService.collection(_transactionsCollection).doc(recovery.id),
      TeacherFinanceTransactionModel.fromEntity(recovery).toMap(),
    );

    await batch.commit();

    await _auditService.log(
      module: 'Employee Finance',
      action: AuditAction.collectPayment,
      recordId: account.id,
      description:
          'Rs. $appliedAmount recovered from '
          '${account.employeeName}',
      oldValues: {
        'recoveredAmount': account.recoveredAmount,
        'outstandingAmount': account.outstandingAmount,
        'status': account.status.name,
      },
      newValues: {
        'recoveredAmount': recoveredAmount,
        'outstandingAmount': outstandingAmount,
        'status': updatedStatus.name,
        'payrollId': payrollId.trim(),
        'transactionType': transactionType.name,
      },
    );
  }

  @override
  Future<List<TeacherFinanceAccountEntity>> getRecoverableAccounts({
    required String employeeId,
    required DateTime payrollMonth,
  }) async {
    final accounts = await getAccounts(
      employeeId: employeeId,
      status: TeacherFinanceStatus.active,
    );

    final values =
        accounts
            .where(
              (account) =>
                  account.isRecoverable &&
                  account.appliesToPayrollMonth(payrollMonth) &&
                  (account.financeType == TeacherFinanceType.advance ||
                      account.financeType == TeacherFinanceType.loan),
            )
            .toList()
          ..sort((a, b) => a.issueDate.compareTo(b.issueDate));

    return List.unmodifiable(values);
  }

  // =========================================================
  // Payroll Integration
  // =========================================================

  @override
  Future<List<TeacherFinanceTransactionEntity>> getPendingPayrollTransactions({
    required String employeeId,
    required DateTime payrollMonth,
  }) async {
    final transactions = await getTransactions(
      employeeId: employeeId,
      isPostedToPayroll: false,
      includeReversed: false,
    );

    final values =
        transactions
            .where(
              (transaction) =>
                  transaction.canBePostedToPayroll &&
                  transaction.appliesToPayrollMonth(payrollMonth),
            )
            .toList()
          ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

    return List.unmodifiable(values);
  }

  @override
  Future<void> markTransactionsPostedToPayroll({
    required List<String> transactionIds,
    required String payrollId,
    required DateTime payrollMonth,
    required String actorId,
  }) async {
    if (transactionIds.isEmpty) {
      return;
    }

    if (payrollId.trim().isEmpty) {
      throw StateError('Payroll ID is required.');
    }

    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    final uniqueIds = transactionIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueIds.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final batch = _firestoreService.instance.batch();

    for (final transactionId in uniqueIds) {
      batch.update(
        _firestoreService
            .collection(_transactionsCollection)
            .doc(transactionId),
        {
          'isPostedToPayroll': true,
          'payrollId': payrollId.trim(),
          'payrollMonth': DateTime(
            payrollMonth.year,
            payrollMonth.month,
          ).toIso8601String(),
        },
      );
    }

    await batch.commit();

    await _auditService.logUpdate(
      module: 'Employee Finance',
      recordId: payrollId.trim(),
      description:
          '${uniqueIds.length} Employee Finance transaction(s) '
          'posted to payroll',
      oldValues: const {},
      newValues: {
        'transactionIds': uniqueIds,
        'payrollId': payrollId.trim(),
        'payrollMonth': DateTime(
          payrollMonth.year,
          payrollMonth.month,
        ).toIso8601String(),
        'actorId': actorId,
        'updatedAt': now.toIso8601String(),
      },
    );
  }

  @override
  Future<void> postPayrollRecoveries({
    required String payrollId,
    required String employeeId,
    required int advanceAmount,
    required int loanAmount,
    required String actorId,
    String referenceNumber = '',
  }) async {
    if (payrollId.trim().isEmpty) {
      throw StateError('Payroll ID is required.');
    }

    if (employeeId.trim().isEmpty) {
      throw StateError('Employee ID is required.');
    }

    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    if (advanceAmount < 0 || loanAmount < 0) {
      throw StateError('Recovery amounts cannot be negative.');
    }

    if (advanceAmount > 0) {
      await _postRecoveryByFinanceType(
        payrollId: payrollId,
        employeeId: employeeId,
        financeType: TeacherFinanceType.advance,
        totalAmount: advanceAmount,
        actorId: actorId,
        referenceNumber: referenceNumber,
      );
    }

    if (loanAmount > 0) {
      await _postRecoveryByFinanceType(
        payrollId: payrollId,
        employeeId: employeeId,
        financeType: TeacherFinanceType.loan,
        totalAmount: loanAmount,
        actorId: actorId,
        referenceNumber: referenceNumber,
      );
    }
  }

  @override
  Future<void> reversePayrollPosting({
    required String payrollId,
    required String actorId,
    required String reason,
  }) async {
    if (payrollId.trim().isEmpty) {
      throw StateError('Payroll ID is required.');
    }

    if (actorId.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }

    if (reason.trim().isEmpty) {
      throw StateError('Reversal reason is required.');
    }

    final transactions = await getTransactions(includeReversed: true);

    final payrollTransactions = transactions
        .where(
          (transaction) =>
              transaction.payrollId.trim() == payrollId.trim() &&
              !transaction.isReversed,
        )
        .toList();

    if (payrollTransactions.isEmpty) {
      return;
    }

    final now = DateTime.now();

    for (final transaction in payrollTransactions) {
      if (transaction.transactionType ==
          TeacherFinanceTransactionType.payrollRecovery) {
        final account = await getAccountById(accountId: transaction.accountId);

        if (account != null) {
          final restoredRecoveredAmount =
              account.recoveredAmount - transaction.amount;

          final safeRecoveredAmount = restoredRecoveredAmount < 0
              ? 0
              : restoredRecoveredAmount;

          final restoredOutstandingAmount =
              account.outstandingAmount + transaction.amount;

          await _firestoreService
              .collection(_accountsCollection)
              .doc(account.id)
              .update({
                'recoveredAmount': safeRecoveredAmount,
                'outstandingAmount': restoredOutstandingAmount,
                'status': TeacherFinanceStatus.active.name,
                'closedAt': null,
                'updatedAt': now.toIso8601String(),
              });
        }
      }

      await _firestoreService
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .update({
            'isReversed': true,
            'reversedAt': now.toIso8601String(),
            'reversedBy': actorId,
            'reversalReason': reason.trim(),
            'isPostedToPayroll': false,
          });
    }

    await _auditService.logUpdate(
      module: 'Employee Finance',
      recordId: payrollId.trim(),
      description: 'Employee Finance payroll posting reversed',
      oldValues: {
        'transactionIds': payrollTransactions.map((item) => item.id).toList(),
      },
      newValues: {
        'isReversed': true,
        'reversedAt': now.toIso8601String(),
        'reversedBy': actorId,
        'reversalReason': reason.trim(),
      },
    );
  }

  // =========================================================
  // Private Helpers
  // =========================================================

  Future<void> _postRecoveryByFinanceType({
    required String payrollId,
    required String employeeId,
    required TeacherFinanceType financeType,
    required int totalAmount,
    required String actorId,
    required String referenceNumber,
  }) async {
    var remainingAmount = totalAmount;

    final accounts = await getAccounts(
      employeeId: employeeId,
      financeType: financeType,
      status: TeacherFinanceStatus.active,
    );

    final recoverableAccounts =
        accounts.where((account) => account.isRecoverable).toList()
          ..sort((a, b) => a.issueDate.compareTo(b.issueDate));

    for (final account in recoverableAccounts) {
      if (remainingAmount <= 0) {
        break;
      }

      final amount = remainingAmount > account.outstandingAmount
          ? account.outstandingAmount
          : remainingAmount;

      await applyRecovery(
        accountId: account.id,
        amount: amount,
        transactionType: TeacherFinanceTransactionType.payrollRecovery,
        actorId: actorId,
        payrollId: payrollId,
        referenceNumber: referenceNumber,
        notes:
            '${_financeTypeLabel(financeType)} recovery '
            'through payroll $payrollId',
      );

      remainingAmount -= amount;
    }

    if (remainingAmount > 0) {
      throw StateError(
        '${_financeTypeLabel(financeType)} recovery amount exceeds '
        'the available outstanding balance.',
      );
    }
  }

  void _validateAccount(TeacherFinanceAccountEntity account) {
    if (account.id.trim().isEmpty) {
      throw StateError('Account ID is required.');
    }

    if (account.employeeId.trim().isEmpty) {
      throw StateError('Employee ID is required.');
    }

    if (account.employeeName.trim().isEmpty) {
      throw StateError('Employee name is required.');
    }

    if (account.principalAmount <= 0) {
      throw StateError('Employee Finance amount must be greater than zero.');
    }

    if (account.recoveryMode == TeacherFinanceRecoveryMode.monthly &&
        account.monthlyRecoveryAmount <= 0) {
      throw StateError('Monthly recovery amount must be greater than zero.');
    }

    if (account.monthlyRecoveryAmount > account.principalAmount) {
      throw StateError('Monthly recovery cannot exceed the approved amount.');
    }

    if (_isRecoverableFinanceType(account.financeType) &&
        account.recoveryMode == TeacherFinanceRecoveryMode.none) {
      throw StateError(
        '${_financeTypeLabel(account.financeType)} requires '
        'a recovery mode.',
      );
    }
  }

  void _validateTransaction(TeacherFinanceTransactionEntity transaction) {
    if (transaction.id.trim().isEmpty) {
      throw StateError('Transaction ID is required.');
    }

    if (transaction.employeeId.trim().isEmpty) {
      throw StateError('Employee ID is required.');
    }

    if (transaction.employeeName.trim().isEmpty) {
      throw StateError('Employee name is required.');
    }

    if (transaction.amount <= 0) {
      throw StateError(
        'Employee Finance transaction amount must be greater '
        'than zero.',
      );
    }

    if (transaction.createdBy.trim().isEmpty) {
      throw StateError('Current user could not be identified.');
    }
  }

  bool _requiresUniqueActiveAccount(TeacherFinanceType financeType) {
    return financeType == TeacherFinanceType.advance ||
        financeType == TeacherFinanceType.loan;
  }

  bool _isRecoverableFinanceType(TeacherFinanceType financeType) {
    return financeType == TeacherFinanceType.advance ||
        financeType == TeacherFinanceType.loan;
  }

  bool _isStandaloneTransaction(TeacherFinanceTransactionType transactionType) {
    return switch (transactionType) {
      TeacherFinanceTransactionType.bonus ||
      TeacherFinanceTransactionType.allowance ||
      TeacherFinanceTransactionType.penalty ||
      TeacherFinanceTransactionType.otherDeduction ||
      TeacherFinanceTransactionType.otherPayment ||
      TeacherFinanceTransactionType.salaryAdjustment => true,

      TeacherFinanceTransactionType.disbursement ||
      TeacherFinanceTransactionType.payrollRecovery ||
      TeacherFinanceTransactionType.manualRecovery ||
      TeacherFinanceTransactionType.adjustment ||
      TeacherFinanceTransactionType.cancellation => false,
    };
  }

  String _financeTypeLabel(TeacherFinanceType type) {
    return switch (type) {
      TeacherFinanceType.advance => 'Advance',
      TeacherFinanceType.loan => 'Loan',
      TeacherFinanceType.salaryAdjustment => 'Salary Adjustment',
      TeacherFinanceType.bonus => 'Bonus',
      TeacherFinanceType.penalty => 'Penalty',
      TeacherFinanceType.allowance => 'Allowance',
      TeacherFinanceType.otherDeduction => 'Other Deduction',
      TeacherFinanceType.otherPayment => 'Other Payment',
    };
  }

  String _transactionTypeLabel(TeacherFinanceTransactionType type) {
    return switch (type) {
      TeacherFinanceTransactionType.disbursement => 'Disbursement',
      TeacherFinanceTransactionType.payrollRecovery => 'Payroll Recovery',
      TeacherFinanceTransactionType.manualRecovery => 'Manual Recovery',
      TeacherFinanceTransactionType.adjustment => 'Adjustment',
      TeacherFinanceTransactionType.cancellation => 'Cancellation',
      TeacherFinanceTransactionType.bonus => 'Bonus',
      TeacherFinanceTransactionType.allowance => 'Allowance',
      TeacherFinanceTransactionType.penalty => 'Penalty',
      TeacherFinanceTransactionType.otherDeduction => 'Other Deduction',
      TeacherFinanceTransactionType.otherPayment => 'Other Payment',
      TeacherFinanceTransactionType.salaryAdjustment => 'Salary Adjustment',
    };
  }
}
