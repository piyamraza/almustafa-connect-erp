import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../../domain/repositories/store_sale_repository.dart';
import '../datasources/store_sale_remote_datasource.dart';

class StoreSaleRepositoryImpl implements StoreSaleRepository {
  const StoreSaleRepositoryImpl(this._source);

  final StoreSaleRemoteDataSource _source;

  @override
  Future<List<StoreStudentOptionEntity>> getStudents() {
    return _source.getStudents();
  }

  @override
  Future<List<StoreSaleEntity>> getSales() {
    return _source.getSales();
  }

  @override
  Future<void> saveSale(StoreSaleEntity sale) {
    return _source.saveSale(sale);
  }
}
