import 'package:equatable/equatable.dart';

import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';

sealed class StorePurchaseEvent extends Equatable {
  const StorePurchaseEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStorePurchases extends StorePurchaseEvent {
  const LoadStorePurchases();
}

class SaveStoreSupplierRequested extends StorePurchaseEvent {
  const SaveStoreSupplierRequested(this.supplier);

  final StoreSupplierEntity supplier;

  @override
  List<Object?> get props => [supplier];
}

class SaveStorePurchaseRequested extends StorePurchaseEvent {
  const SaveStorePurchaseRequested(this.purchase);

  final StorePurchaseEntity purchase;

  @override
  List<Object?> get props => [purchase];
}
