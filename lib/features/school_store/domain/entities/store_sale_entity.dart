import 'package:equatable/equatable.dart';

enum StoreSalePaymentStatus { paid, partial, credit }

class StoreSaleEntity extends Equatable {
  const StoreSaleEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitSalePrice,
    required this.unitPurchasePrice,
    required this.discount,
    required this.paidAmount,
    required this.saleDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitSalePrice;
  final double unitPurchasePrice;
  final double discount;
  final double paidAmount;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;

  double get grossAmount => quantity * unitSalePrice;

  double get netAmount {
    final value = grossAmount - discount;
    return value < 0 ? 0 : value;
  }

  double get outstandingAmount => netAmount - paidAmount;

  double get costAmount => quantity * unitPurchasePrice;

  double get profitAmount => netAmount - costAmount;

  StoreSalePaymentStatus get paymentStatus {
    if (paidAmount <= 0) {
      return StoreSalePaymentStatus.credit;
    }
    if (paidAmount < netAmount) {
      return StoreSalePaymentStatus.partial;
    }
    return StoreSalePaymentStatus.paid;
  }

  @override
  List<Object?> get props => [
    id,
    studentId,
    studentName,
    admissionNo,
    classId,
    sectionId,
    itemId,
    itemName,
    quantity,
    unitSalePrice,
    unitPurchasePrice,
    discount,
    paidAmount,
    saleDate,
    createdAt,
    updatedAt,
    notes,
  ];
}
