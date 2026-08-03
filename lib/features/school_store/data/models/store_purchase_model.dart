import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_purchase_entity.dart';

class StorePurchaseModel extends StorePurchaseEntity {
  const StorePurchaseModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.itemId,
    required super.itemName,
    required super.invoiceNumber,
    required super.quantity,
    required super.unitPrice,
    required super.paidAmount,
    required super.purchaseDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StorePurchaseModel.fromEntity(StorePurchaseEntity entity) {
    return StorePurchaseModel(
      id: entity.id,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      itemId: entity.itemId,
      itemName: entity.itemName,
      invoiceNumber: entity.invoiceNumber,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      paidAmount: entity.paidAmount,
      purchaseDate: entity.purchaseDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StorePurchaseModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StorePurchaseModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      purchaseDate: date(map['purchaseDate']),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'itemId': itemId,
    'itemName': itemName,
    'invoiceNumber': invoiceNumber,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'paidAmount': paidAmount,
    'totalAmount': totalAmount,
    'outstandingAmount': outstandingAmount,
    'purchaseDate': purchaseDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'schemaVersion': 1,
  };
}
