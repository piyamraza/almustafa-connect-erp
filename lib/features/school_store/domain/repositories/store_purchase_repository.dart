import '../entities/store_purchase_entity.dart';
import '../entities/store_supplier_entity.dart';

abstract class StorePurchaseRepository {
  Future<List<StoreSupplierEntity>> getSuppliers();
  Future<void> saveSupplier(StoreSupplierEntity supplier);
  Future<List<StorePurchaseEntity>> getPurchases();
  Future<void> savePurchase(StorePurchaseEntity purchase);
}
