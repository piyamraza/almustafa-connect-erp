import 'package:equatable/equatable.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';

sealed class StorePurchaseState extends Equatable {
  const StorePurchaseState();

  @override
  List<Object?> get props => const [];
}

class StorePurchaseInitial extends StorePurchaseState {
  const StorePurchaseInitial();
}

class StorePurchaseLoading extends StorePurchaseState {
  const StorePurchaseLoading();
}

class StorePurchaseLoaded extends StorePurchaseState {
  const StorePurchaseLoaded({
    required this.suppliers,
    required this.purchases,
    required this.items,
    this.message,
  });

  final List<StoreSupplierEntity> suppliers;
  final List<StorePurchaseEntity> purchases;
  final List<StoreItemEntity> items;
  final String? message;

  double get totalPurchases =>
      purchases.fold<double>(0, (sum, item) => sum + item.totalAmount);

  double get totalPaid =>
      purchases.fold<double>(0, (sum, item) => sum + item.paidAmount);

  double get outstanding =>
      purchases.fold<double>(0, (sum, item) => sum + item.outstandingAmount);

  @override
  List<Object?> get props => [suppliers, purchases, items, message];
}

class StorePurchaseFailure extends StorePurchaseState {
  const StorePurchaseFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
