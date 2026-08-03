import '../entities/store_purchase_entity.dart';
import '../entities/store_supplier_entity.dart';
import '../repositories/store_purchase_repository.dart';

class GetStoreSuppliers {
  const GetStoreSuppliers(this._repository);

  final StorePurchaseRepository _repository;

  Future<List<StoreSupplierEntity>> call() {
    return _repository.getSuppliers();
  }
}

class SaveStoreSupplier {
  const SaveStoreSupplier(this._repository);

  final StorePurchaseRepository _repository;

  Future<void> call(StoreSupplierEntity supplier) {
    if (supplier.name.trim().isEmpty) {
      throw ArgumentError('Supplier name is required.');
    }
    return _repository.saveSupplier(supplier);
  }
}

class GetStorePurchases {
  const GetStorePurchases(this._repository);

  final StorePurchaseRepository _repository;

  Future<List<StorePurchaseEntity>> call() {
    return _repository.getPurchases();
  }
}

class SaveStorePurchase {
  const SaveStorePurchase(this._repository);

  final StorePurchaseRepository _repository;

  Future<void> call(StorePurchaseEntity purchase) {
    if (purchase.supplierId.trim().isEmpty) {
      throw ArgumentError('Supplier is required.');
    }
    if (purchase.itemId.trim().isEmpty) {
      throw ArgumentError('Item is required.');
    }
    if (purchase.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (purchase.unitPrice < 0) {
      throw ArgumentError('Purchase price cannot be negative.');
    }
    if (purchase.paidAmount < 0 || purchase.paidAmount > purchase.totalAmount) {
      throw ArgumentError('Paid amount is invalid.');
    }
    return _repository.savePurchase(purchase);
  }
}
