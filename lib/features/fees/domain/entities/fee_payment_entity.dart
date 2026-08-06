import 'package:equatable/equatable.dart';

enum FeePaymentMethod { cash, bankTransfer, easypaisa, jazzCash }

enum FeePaymentStatus { completed, cancelled }

enum FeeDueType { monthly, additionalCharge }

class FeePaymentAllocationEntity extends Equatable {
  const FeePaymentAllocationEntity({
    required this.dueId,
    required this.month,
    required this.year,
    required this.amount,
    this.dueType = FeeDueType.monthly,
  });

  final String dueId;
  final int month;
  final int year;
  final double amount;
  final FeeDueType dueType;

  @override
  List<Object> get props => [dueId, month, year, amount, dueType];
}

class FeePaymentEntity extends Equatable {
  FeePaymentEntity({
    required this.id,
    required this.receiptNumber,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.academicSession,
    required this.paymentDate,
    required this.method,
    required this.referenceNumber,
    required this.totalPaid,
    required this.advanceAmount,
    this.advanceUsed = 0,
    required List<FeePaymentAllocationEntity> allocations,
    required this.status,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
  }) : allocations = List<FeePaymentAllocationEntity>.unmodifiable(allocations);

  final String id;
  final String receiptNumber;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String academicSession;
  final DateTime paymentDate;
  final FeePaymentMethod method;
  final String referenceNumber;

  /// New cash/bank/mobile-wallet amount received in this transaction.
  final double totalPaid;

  /// Excess amount from this transaction retained as student advance.
  final double advanceAmount;

  /// Existing student advance consumed by this transaction.
  final double advanceUsed;

  final List<FeePaymentAllocationEntity> allocations;
  final FeePaymentStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  double get allocatedAmount =>
      allocations.fold<double>(0, (sum, item) => sum + item.amount);

  double get totalApplied => totalPaid + advanceUsed;

  bool get isAdvanceOnlyAdjustment =>
      totalPaid <= 0 && advanceUsed > 0 && advanceAmount <= 0;

  @override
  List<Object?> get props => [
    id,
    receiptNumber,
    studentId,
    studentName,
    admissionNo,
    academicSession,
    paymentDate,
    method,
    referenceNumber,
    totalPaid,
    advanceAmount,
    advanceUsed,
    allocations,
    status,
    notes,
    createdAt,
    updatedAt,
    cancelledAt,
    cancellationReason,
  ];
}
