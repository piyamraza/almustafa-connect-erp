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
  final double totalPaid;
  final double advanceAmount;
  final List<FeePaymentAllocationEntity> allocations;
  final FeePaymentStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  double get allocatedAmount =>
      allocations.fold<double>(0, (sum, item) => sum + item.amount);

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
    allocations,
    status,
    notes,
    createdAt,
    updatedAt,
    cancelledAt,
    cancellationReason,
  ];
}
