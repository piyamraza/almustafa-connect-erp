import '../../../fees/domain/entities/fee_payment_entity.dart';
import '../../../fees/domain/repositories/fee_payment_repository.dart';
import '../entities/income_entry_entity.dart';
import '../repositories/accounts_repository.dart';

class GetIncomeEntries {
  const GetIncomeEntries(this._repository);

  final AccountsRepository _repository;

  Future<List<IncomeEntryEntity>> call() => _repository.getIncomeEntries();
}

class SaveIncomeEntry {
  const SaveIncomeEntry(this._repository);

  final AccountsRepository _repository;

  Future<void> call(IncomeEntryEntity entry) {
    if (entry.id.trim().isEmpty) {
      throw ArgumentError('Income entry ID is required.');
    }
    if (entry.amount <= 0) {
      throw ArgumentError('Income amount must be greater than zero.');
    }
    if (entry.description.trim().isEmpty) {
      throw ArgumentError('Income description is required.');
    }
    return _repository.saveIncomeEntry(entry);
  }
}

class ReverseIncomeEntry {
  const ReverseIncomeEntry(this._repository);

  final AccountsRepository _repository;

  Future<void> call({required String incomeEntryId, required String reason}) {
    if (incomeEntryId.trim().isEmpty) {
      throw ArgumentError('Income entry ID is required.');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('Reversal reason is required.');
    }
    return _repository.reverseIncomeEntry(
      incomeEntryId: incomeEntryId,
      reason: reason.trim(),
    );
  }
}

class SyncFeePaymentsToIncome {
  const SyncFeePaymentsToIncome(
    this._accountsRepository,
    this._feePaymentRepository,
  );

  final AccountsRepository _accountsRepository;
  final FeePaymentRepository _feePaymentRepository;

  Future<FeeIncomeSyncResult> call({
    required String actorId,
    String? academicSession,
  }) async {
    if (actorId.trim().isEmpty) {
      throw ArgumentError(
        'Current authenticated user could not be identified.',
      );
    }

    final payments = await _feePaymentRepository.getPayments(
      academicSession: academicSession,
    );
    final existingEntries = await _accountsRepository.getIncomeEntries();
    final byPaymentId = <String, IncomeEntryEntity>{
      for (final entry in existingEntries)
        if (entry.feePaymentId.trim().isNotEmpty) entry.feePaymentId: entry,
    };

    var created = 0;
    var reversed = 0;
    var unchanged = 0;

    for (final payment in payments) {
      final existing = byPaymentId[payment.id];

      if (payment.status == FeePaymentStatus.cancelled) {
        if (existing != null && existing.isActive) {
          await _accountsRepository.reverseIncomeEntry(
            incomeEntryId: existing.id,
            reason: payment.cancellationReason?.trim().isNotEmpty == true
                ? payment.cancellationReason!.trim()
                : 'Source fee payment was cancelled.',
          );
          reversed++;
        } else {
          unchanged++;
        }
        continue;
      }

      if (existing != null) {
        unchanged++;
        continue;
      }

      final now = DateTime.now();
      final amount = payment.totalPaid.round();
      if (amount <= 0) {
        unchanged++;
        continue;
      }

      await _accountsRepository.saveIncomeEntry(
        IncomeEntryEntity(
          id: 'fee_income_${payment.id}',
          incomeType: IncomeType.tuitionFee,
          amount: amount,
          incomeDate: payment.paymentDate,
          description: 'Fee receipt ${payment.receiptNumber}',
          paymentMethod: payment.method.name,
          referenceNumber: payment.referenceNumber,
          studentId: payment.studentId,
          studentName: payment.studentName,
          feePaymentId: payment.id,
          enteredBy: actorId,
          createdAt: now,
          updatedAt: now,
          sourceType: IncomeSourceType.feePayment,
          sourceId: payment.id,
          status: IncomeEntryStatus.active,
        ),
      );
      created++;
    }

    return FeeIncomeSyncResult(
      created: created,
      reversed: reversed,
      unchanged: unchanged,
    );
  }
}

class FeeIncomeSyncResult {
  const FeeIncomeSyncResult({
    required this.created,
    required this.reversed,
    required this.unchanged,
  });

  final int created;
  final int reversed;
  final int unchanged;

  String get message =>
      'Fee income sync complete: $created created, '
      '$reversed reversed, $unchanged unchanged.';
}
