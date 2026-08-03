import 'package:equatable/equatable.dart';

class StoreSupplierPaymentEntity extends Equatable {
  const StoreSupplierPaymentEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    this.referenceNumber = '',
    this.notes = '',
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String referenceNumber;
  final String notes;

  @override
  List<Object?> get props => [
    id,
    supplierId,
    supplierName,
    amount,
    paymentDate,
    createdAt,
    referenceNumber,
    notes,
  ];
}
