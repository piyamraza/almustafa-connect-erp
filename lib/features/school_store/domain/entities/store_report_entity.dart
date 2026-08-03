import 'package:equatable/equatable.dart';

class StoreItemMovementEntity extends Equatable {
  const StoreItemMovementEntity({
    required this.itemId,
    required this.itemName,
    required this.openingStock,
    required this.purchasedQuantity,
    required this.soldQuantity,
    required this.currentStock,
    required this.stockValue,
    required this.salesAmount,
    required this.profitAmount,
  });

  final String itemId;
  final String itemName;
  final int openingStock;
  final int purchasedQuantity;
  final int soldQuantity;
  final int currentStock;
  final double stockValue;
  final double salesAmount;
  final double profitAmount;

  @override
  List<Object?> get props => [
    itemId,
    itemName,
    openingStock,
    purchasedQuantity,
    soldQuantity,
    currentStock,
    stockValue,
    salesAmount,
    profitAmount,
  ];
}

class StorePartyBalanceEntity extends Equatable {
  const StorePartyBalanceEntity({
    required this.id,
    required this.name,
    required this.reference,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  final String id;
  final String name;
  final String reference;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  @override
  List<Object?> get props => [
    id,
    name,
    reference,
    totalAmount,
    paidAmount,
    outstandingAmount,
  ];
}

class StoreReportEntity extends Equatable {
  const StoreReportEntity({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalProfit,
    required this.stockValue,
    required this.studentReceivable,
    required this.supplierPayable,
    required this.lowStockCount,
    required this.itemMovements,
    required this.studentBalances,
    required this.supplierBalances,
  });

  final double totalSales;
  final double totalPurchases;
  final double totalProfit;
  final double stockValue;
  final double studentReceivable;
  final double supplierPayable;
  final int lowStockCount;
  final List<StoreItemMovementEntity> itemMovements;
  final List<StorePartyBalanceEntity> studentBalances;
  final List<StorePartyBalanceEntity> supplierBalances;

  @override
  List<Object?> get props => [
    totalSales,
    totalPurchases,
    totalProfit,
    stockValue,
    studentReceivable,
    supplierPayable,
    lowStockCount,
    itemMovements,
    studentBalances,
    supplierBalances,
  ];
}
