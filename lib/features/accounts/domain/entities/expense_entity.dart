import 'package:equatable/equatable.dart';

enum ExpenseStatus { draft, approved, paid, cancelled }

enum ExpenseSourceType { manual, payroll, system }

class ExpenseEntity extends Equatable {
  const ExpenseEntity({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.expenseDate,
    required this.description,
    required this.payeeName,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.receiptUrl,
    required this.status,
    required this.enteredBy,
    required this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceType,
    required this.sourceId,
    this.approvedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final int amount;
  final DateTime expenseDate;
  final String description;
  final String payeeName;
  final String paymentMethod;
  final String referenceNumber;
  final String receiptUrl;
  final ExpenseStatus status;
  final String enteredBy;
  final String approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ExpenseSourceType sourceType;
  final String sourceId;

  @override
  List<Object?> get props => [
    id,
    categoryId,
    categoryName,
    amount,
    expenseDate,
    description,
    payeeName,
    paymentMethod,
    referenceNumber,
    receiptUrl,
    status,
    enteredBy,
    approvedBy,
    approvedAt,
    createdAt,
    updatedAt,
    sourceType,
    sourceId,
  ];
}
