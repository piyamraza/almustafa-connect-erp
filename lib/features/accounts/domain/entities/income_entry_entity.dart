import 'package:equatable/equatable.dart';

enum IncomeType {
  tuitionFee,
  admissionFee,
  examinationFee,
  annualCharges,
  previousDues,
  other,
}

enum IncomeSourceType { feePayment, manual, system }

enum IncomeEntryStatus { active, reversed }

class IncomeEntryEntity extends Equatable {
  const IncomeEntryEntity({
    required this.id,
    required this.incomeType,
    required this.amount,
    required this.incomeDate,
    required this.description,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.studentId,
    required this.studentName,
    required this.feePaymentId,
    required this.enteredBy,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceType,
    required this.sourceId,
    required this.status,
    this.reversedAt,
    this.reversalReason = '',
  });

  final String id;
  final IncomeType incomeType;

  /// Stored as whole Pakistani rupees.
  final int amount;

  final DateTime incomeDate;
  final String description;
  final String paymentMethod;
  final String referenceNumber;
  final String studentId;
  final String studentName;
  final String feePaymentId;
  final String enteredBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final IncomeSourceType sourceType;
  final String sourceId;
  final IncomeEntryStatus status;
  final DateTime? reversedAt;
  final String reversalReason;

  bool get isActive => status == IncomeEntryStatus.active;

  String get uniqueSourceKey => '${sourceType.name}:${sourceId.trim()}';

  IncomeEntryEntity copyWith({
    String? id,
    IncomeType? incomeType,
    int? amount,
    DateTime? incomeDate,
    String? description,
    String? paymentMethod,
    String? referenceNumber,
    String? studentId,
    String? studentName,
    String? feePaymentId,
    String? enteredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    IncomeSourceType? sourceType,
    String? sourceId,
    IncomeEntryStatus? status,
    DateTime? reversedAt,
    String? reversalReason,
  }) {
    return IncomeEntryEntity(
      id: id ?? this.id,
      incomeType: incomeType ?? this.incomeType,
      amount: amount ?? this.amount,
      incomeDate: incomeDate ?? this.incomeDate,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      feePaymentId: feePaymentId ?? this.feePaymentId,
      enteredBy: enteredBy ?? this.enteredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      status: status ?? this.status,
      reversedAt: reversedAt ?? this.reversedAt,
      reversalReason: reversalReason ?? this.reversalReason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    incomeType,
    amount,
    incomeDate,
    description,
    paymentMethod,
    referenceNumber,
    studentId,
    studentName,
    feePaymentId,
    enteredBy,
    createdAt,
    updatedAt,
    sourceType,
    sourceId,
    status,
    reversedAt,
    reversalReason,
  ];
}
