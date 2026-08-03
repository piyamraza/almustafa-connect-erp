import '../../domain/entities/store_item_entity.dart';
import '../../domain/repositories/school_store_repository.dart';
import '../datasources/school_store_remote_datasource.dart';

class SchoolStoreRepositoryImpl implements SchoolStoreRepository {
  const SchoolStoreRepositoryImpl(this._source);
  final SchoolStoreRemoteDataSource _source;
  @override
  Future<List<StoreItemEntity>> getItems() => _source.getItems();
  @override
  Future<void> saveItem(StoreItemEntity item) => _source.saveItem(item);
  @override
  Future<void> deleteItem(String itemId) => _source.deleteItem(itemId);
}
