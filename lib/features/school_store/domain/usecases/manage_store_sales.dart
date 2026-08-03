import '../entities/store_sale_entity.dart';
import '../entities/store_student_option_entity.dart';
import '../repositories/store_sale_repository.dart';

class GetStoreStudents {
  const GetStoreStudents(this._repository);

  final StoreSaleRepository _repository;

  Future<List<StoreStudentOptionEntity>> call() {
    return _repository.getStudents();
  }
}

class GetStoreSales {
  const GetStoreSales(this._repository);

  final StoreSaleRepository _repository;

  Future<List<StoreSaleEntity>> call() {
    return _repository.getSales();
  }
}

class SaveStoreSale {
  const SaveStoreSale(this._repository);

  final StoreSaleRepository _repository;

  Future<void> call(StoreSaleEntity sale) {
    if (sale.studentId.trim().isEmpty) {
      throw ArgumentError('Student is required.');
    }
    if (sale.itemId.trim().isEmpty) {
      throw ArgumentError('Item is required.');
    }
    if (sale.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (sale.unitSalePrice < 0) {
      throw ArgumentError('Sale price cannot be negative.');
    }
    if (sale.discount < 0 || sale.discount > sale.grossAmount) {
      throw ArgumentError('Discount is invalid.');
    }
    if (sale.paidAmount < 0 || sale.paidAmount > sale.netAmount) {
      throw ArgumentError('Paid amount is invalid.');
    }
    return _repository.saveSale(sale);
  }
}
