import 'package:equatable/equatable.dart';

class StoreStudentPaymentEntity extends Equatable {
  const StoreStudentPaymentEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    this.receiptNumber = '',
    this.notes = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String receiptNumber;
  final String notes;

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentName,
    admissionNo,
    amount,
    paymentDate,
    createdAt,
    receiptNumber,
    notes,
  ];
}
