import '../entities/store_item_entity.dart';

abstract class SchoolStoreRepository {
  Future<List<StoreItemEntity>> getItems();
  Future<void> saveItem(StoreItemEntity item);
  Future<void> deleteItem(String itemId);
}
