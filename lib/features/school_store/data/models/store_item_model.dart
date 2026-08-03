import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/store_item_entity.dart';

class StoreItemModel extends StoreItemEntity {
  const StoreItemModel({
    required super.id,
    required super.name,
    required super.category,
    required super.purchasePrice,
    required super.salePrice,
    required super.openingStock,
    required super.purchasedQuantity,
    required super.soldQuantity,
    required super.lowStockLevel,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    super.itemCode,
  });

  factory StoreItemModel.fromEntity(StoreItemEntity e) => StoreItemModel(
    id: e.id,
    name: e.name,
    category: e.category,
    purchasePrice: e.purchasePrice,
    salePrice: e.salePrice,
    openingStock: e.openingStock,
    purchasedQuantity: e.purchasedQuantity,
    soldQuantity: e.soldQuantity,
    lowStockLevel: e.lowStockLevel,
    isActive: e.isActive,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
    itemCode: e.itemCode,
  );

  factory StoreItemModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreItemModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: StoreItemCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => StoreItemCategory.other,
      ),
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0,
      openingStock: (map['openingStock'] as num?)?.toInt() ?? 0,
      purchasedQuantity: (map['purchasedQuantity'] as num?)?.toInt() ?? 0,
      soldQuantity: (map['soldQuantity'] as num?)?.toInt() ?? 0,
      lowStockLevel: (map['lowStockLevel'] as num?)?.toInt() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      itemCode: map['itemCode'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'category': category.name,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'openingStock': openingStock,
    'purchasedQuantity': purchasedQuantity,
    'soldQuantity': soldQuantity,
    'lowStockLevel': lowStockLevel,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'itemCode': itemCode,
    'schemaVersion': 1,
  };
}
