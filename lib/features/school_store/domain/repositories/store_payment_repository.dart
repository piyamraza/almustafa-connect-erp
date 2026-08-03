import '../entities/store_purchase_entity.dart';
import '../entities/store_sale_entity.dart';
import '../entities/store_student_payment_entity.dart';
import '../entities/store_supplier_payment_entity.dart';

abstract class StorePaymentRepository {
  Future<List<StoreSaleEntity>> getSales();
  Future<List<StorePurchaseEntity>> getPurchases();

  Future<List<StoreStudentPaymentEntity>> getStudentPayments();

  Future<List<StoreSupplierPaymentEntity>> getSupplierPayments();

  Future<void> receiveStudentPayment(StoreStudentPaymentEntity payment);

  Future<void> paySupplier(StoreSupplierPaymentEntity payment);
}
