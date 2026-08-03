import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../../domain/repositories/store_purchase_repository.dart';
import '../datasources/store_purchase_remote_datasource.dart';

class StorePurchaseRepositoryImpl implements StorePurchaseRepository {
  const StorePurchaseRepositoryImpl(this._source);

  final StorePurchaseRemoteDataSource _source;

  @override
  Future<List<StoreSupplierEntity>> getSuppliers() {
    return _source.getSuppliers();
  }

  @override
  Future<void> saveSupplier(StoreSupplierEntity supplier) {
    return _source.saveSupplier(supplier);
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() {
    return _source.getPurchases();
  }

  @override
  Future<void> savePurchase(StorePurchaseEntity purchase) {
    return _source.savePurchase(purchase);
  }
}
