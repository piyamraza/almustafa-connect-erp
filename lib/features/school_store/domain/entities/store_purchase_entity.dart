import 'package:equatable/equatable.dart';

class StorePurchaseEntity extends Equatable {
  const StorePurchaseEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.invoiceNumber,
    required this.quantity,
    required this.unitPrice,
    required this.paidAmount,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final String invoiceNumber;
  final int quantity;
  final double unitPrice;
  final double paidAmount;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalAmount => quantity * unitPrice;
  double get outstandingAmount => totalAmount - paidAmount;

  @override
  List<Object?> get props => [
    id,
    supplierId,
    supplierName,
    itemId,
    itemName,
    invoiceNumber,
    quantity,
    unitPrice,
    paidAmount,
    purchaseDate,
    createdAt,
    updatedAt,
  ];
}
