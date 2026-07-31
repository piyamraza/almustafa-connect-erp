import '../entities/fee_payment_entity.dart';

abstract class FeePaymentRepository {
  Future<List<FeePaymentEntity>> getPayments({
    String? academicSession,
    String? studentId,
  });

  Future<FeePaymentEntity> collectPayment({
    required String academicSession,
    required String studentId,
    required String studentName,
    required String admissionNo,
    required DateTime paymentDate,
    required FeePaymentMethod method,
    required String referenceNumber,
    required double amount,
    required List<String> dueIds,
    required String notes,
  });

  Future<void> cancelPayment({
    required String paymentId,
    required String reason,
  });

  String generateId();
}
