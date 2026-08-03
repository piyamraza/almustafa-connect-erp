import 'package:equatable/equatable.dart';

enum StoreItemCategory { book, copy, diary, stationery, other }

class StoreItemEntity extends Equatable {
  const StoreItemEntity({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.salePrice,
    required this.openingStock,
    required this.purchasedQuantity,
    required this.soldQuantity,
    required this.lowStockLevel,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.itemCode = '',
  });

  final String id;
  final String name;
  final StoreItemCategory category;
  final double purchasePrice;
  final double salePrice;
  final int openingStock;
  final int purchasedQuantity;
  final int soldQuantity;
  final int lowStockLevel;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String itemCode;

  int get currentStock => openingStock + purchasedQuantity - soldQuantity;
  bool get isLowStock => currentStock <= lowStockLevel;
  double get unitProfit => salePrice - purchasePrice;
  double get stockValue => currentStock * purchasePrice;

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    purchasePrice,
    salePrice,
    openingStock,
    purchasedQuantity,
    soldQuantity,
    lowStockLevel,
    isActive,
    createdAt,
    updatedAt,
    itemCode,
  ];
}
