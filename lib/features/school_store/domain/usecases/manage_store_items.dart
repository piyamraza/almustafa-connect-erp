import '../entities/store_item_entity.dart';
import '../repositories/school_store_repository.dart';

class GetStoreItems {
  const GetStoreItems(this._repository);
  final SchoolStoreRepository _repository;
  Future<List<StoreItemEntity>> call() => _repository.getItems();
}

class SaveStoreItem {
  const SaveStoreItem(this._repository);
  final SchoolStoreRepository _repository;
  Future<void> call(StoreItemEntity item) {
    if (item.name.trim().isEmpty) throw ArgumentError('Item name is required.');
    if (item.purchasePrice < 0 || item.salePrice < 0) {
      throw ArgumentError('Prices cannot be negative.');
    }
    return _repository.saveItem(item);
  }
}

class DeleteStoreItem {
  const DeleteStoreItem(this._repository);
  final SchoolStoreRepository _repository;
  Future<void> call(String id) => _repository.deleteItem(id);
}
