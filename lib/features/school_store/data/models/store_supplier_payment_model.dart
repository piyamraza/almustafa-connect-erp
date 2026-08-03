import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_supplier_payment_entity.dart';

class StoreSupplierPaymentModel extends StoreSupplierPaymentEntity {
  const StoreSupplierPaymentModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.amount,
    required super.paymentDate,
    required super.createdAt,
    super.referenceNumber,
    super.notes,
  });

  factory StoreSupplierPaymentModel.fromEntity(
    StoreSupplierPaymentEntity entity,
  ) {
    return StoreSupplierPaymentModel(
      id: entity.id,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      createdAt: entity.createdAt,
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
    );
  }

  factory StoreSupplierPaymentModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSupplierPaymentModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: date(map['paymentDate']),
      createdAt: date(map['createdAt']),
      referenceNumber: map['referenceNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'amount': amount,
    'paymentDate': paymentDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'referenceNumber': referenceNumber,
    'notes': notes,
    'schemaVersion': 1,
  };
}
