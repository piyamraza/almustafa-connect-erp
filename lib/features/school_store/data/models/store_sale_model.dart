import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_sale_entity.dart';

class StoreSaleModel extends StoreSaleEntity {
  const StoreSaleModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.itemId,
    required super.itemName,
    required super.quantity,
    required super.unitSalePrice,
    required super.unitPurchasePrice,
    required super.discount,
    required super.paidAmount,
    required super.saleDate,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
  });

  factory StoreSaleModel.fromEntity(StoreSaleEntity entity) {
    return StoreSaleModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      classId: entity.classId,
      sectionId: entity.sectionId,
      itemId: entity.itemId,
      itemName: entity.itemName,
      quantity: entity.quantity,
      unitSalePrice: entity.unitSalePrice,
      unitPurchasePrice: entity.unitPurchasePrice,
      discount: entity.discount,
      paidAmount: entity.paidAmount,
      saleDate: entity.saleDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      notes: entity.notes,
    );
  }

  factory StoreSaleModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSaleModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitSalePrice: (map['unitSalePrice'] as num?)?.toDouble() ?? 0,
      unitPurchasePrice: (map['unitPurchasePrice'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      saleDate: date(map['saleDate']),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'classId': classId,
    'sectionId': sectionId,
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'unitSalePrice': unitSalePrice,
    'unitPurchasePrice': unitPurchasePrice,
    'discount': discount,
    'grossAmount': grossAmount,
    'netAmount': netAmount,
    'paidAmount': paidAmount,
    'outstandingAmount': outstandingAmount,
    'costAmount': costAmount,
    'profitAmount': profitAmount,
    'paymentStatus': paymentStatus.name,
    'saleDate': saleDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'notes': notes,
    'schemaVersion': 1,
  };
}
