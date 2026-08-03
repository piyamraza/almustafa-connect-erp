import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../models/store_item_model.dart';
import '../models/store_purchase_model.dart';
import '../models/store_supplier_model.dart';

abstract class StorePurchaseRemoteDataSource {
  Future<List<StoreSupplierEntity>> getSuppliers();
  Future<void> saveSupplier(StoreSupplierEntity supplier);
  Future<List<StorePurchaseEntity>> getPurchases();
  Future<void> savePurchase(StorePurchaseEntity purchase);
}

class StorePurchaseRemoteDataSourceImpl
    implements StorePurchaseRemoteDataSource {
  const StorePurchaseRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreSupplierEntity>> getSuppliers() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeSuppliers)
        .get();

    final values = snapshot.docs
        .map((doc) => StoreSupplierModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  @override
  Future<void> saveSupplier(StoreSupplierEntity supplier) {
    return _service
        .collection(FirestorePaths.storeSuppliers)
        .doc(supplier.id)
        .set(StoreSupplierModel.fromEntity(supplier).toMap());
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() async {
    final snapshot = await _service
        .collection(FirestorePaths.storePurchases)
        .get();

    final values = snapshot.docs
        .map((doc) => StorePurchaseModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));

    return values;
  }

  @override
  Future<void> savePurchase(StorePurchaseEntity purchase) async {
    final itemRef = _service
        .collection(FirestorePaths.storeItems)
        .doc(purchase.itemId);

    final itemDoc = await itemRef.get();

    if (!itemDoc.exists) {
      throw StateError('Selected store item was not found.');
    }

    final item = StoreItemModel.fromMap({...itemDoc.data()!, 'id': itemDoc.id});

    final updatedItem = StoreItemEntity(
      id: item.id,
      name: item.name,
      category: item.category,
      purchasePrice: purchase.unitPrice,
      salePrice: item.salePrice,
      openingStock: item.openingStock,
      purchasedQuantity: item.purchasedQuantity + purchase.quantity,
      soldQuantity: item.soldQuantity,
      lowStockLevel: item.lowStockLevel,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      itemCode: item.itemCode,
    );

    await _service
        .collection(FirestorePaths.storePurchases)
        .doc(purchase.id)
        .set(StorePurchaseModel.fromEntity(purchase).toMap());

    await itemRef.set(StoreItemModel.fromEntity(updatedItem).toMap());
  }
}
