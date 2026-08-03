import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_supplier_entity.dart';

class StoreSupplierModel extends StoreSupplierEntity {
  const StoreSupplierModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
    super.contactPerson,
    super.mobileNumber,
    super.address,
    super.isActive,
  });

  factory StoreSupplierModel.fromEntity(StoreSupplierEntity entity) {
    return StoreSupplierModel(
      id: entity.id,
      name: entity.name,
      contactPerson: entity.contactPerson,
      mobileNumber: entity.mobileNumber,
      address: entity.address,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StoreSupplierModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSupplierModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactPerson: map['contactPerson'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'contactPerson': contactPerson,
    'mobileNumber': mobileNumber,
    'address': address,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'schemaVersion': 1,
  };
}
