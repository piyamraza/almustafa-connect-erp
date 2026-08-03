import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_item_entity.dart';
import '../models/store_item_model.dart';

abstract class SchoolStoreRemoteDataSource {
  Future<List<StoreItemEntity>> getItems();
  Future<void> saveItem(StoreItemEntity item);
  Future<void> deleteItem(String itemId);
}

class SchoolStoreRemoteDataSourceImpl implements SchoolStoreRemoteDataSource {
  const SchoolStoreRemoteDataSourceImpl(this._service);
  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreItemEntity>> getItems() async {
    final snapshot = await _service.collection(FirestorePaths.storeItems).get();
    final values = snapshot.docs
        .map((doc) => StoreItemModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();
    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  @override
  Future<void> saveItem(StoreItemEntity item) => _service
      .collection(FirestorePaths.storeItems)
      .doc(item.id)
      .set(StoreItemModel.fromEntity(item).toMap());

  @override
  Future<void> deleteItem(String itemId) =>
      _service.collection(FirestorePaths.storeItems).doc(itemId).delete();
}
