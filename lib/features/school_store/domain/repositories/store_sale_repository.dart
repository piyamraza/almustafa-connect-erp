import '../entities/store_sale_entity.dart';
import '../entities/store_student_option_entity.dart';

abstract class StoreSaleRepository {
  Future<List<StoreStudentOptionEntity>> getStudents();
  Future<List<StoreSaleEntity>> getSales();
  Future<void> saveSale(StoreSaleEntity sale);
}
