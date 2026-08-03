import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../../domain/repositories/store_payment_repository.dart';
import '../datasources/store_payment_remote_datasource.dart';

class StorePaymentRepositoryImpl implements StorePaymentRepository {
  const StorePaymentRepositoryImpl(this._source);

  final StorePaymentRemoteDataSource _source;

  @override
  Future<List<StoreSaleEntity>> getSales() {
    return _source.getSales();
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() {
    return _source.getPurchases();
  }

  @override
  Future<List<StoreStudentPaymentEntity>> getStudentPayments() {
    return _source.getStudentPayments();
  }

  @override
  Future<List<StoreSupplierPaymentEntity>> getSupplierPayments() {
    return _source.getSupplierPayments();
  }

  @override
  Future<void> receiveStudentPayment(StoreStudentPaymentEntity payment) {
    return _source.receiveStudentPayment(payment);
  }

  @override
  Future<void> paySupplier(StoreSupplierPaymentEntity payment) {
    return _source.paySupplier(payment);
  }
}
