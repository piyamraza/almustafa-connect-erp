import '../entities/store_purchase_entity.dart';
import '../entities/store_sale_entity.dart';
import '../entities/store_student_payment_entity.dart';
import '../entities/store_supplier_payment_entity.dart';
import '../repositories/store_payment_repository.dart';

class StorePaymentData {
  const StorePaymentData({
    required this.sales,
    required this.purchases,
    required this.studentPayments,
    required this.supplierPayments,
  });

  final List<StoreSaleEntity> sales;
  final List<StorePurchaseEntity> purchases;
  final List<StoreStudentPaymentEntity> studentPayments;
  final List<StoreSupplierPaymentEntity> supplierPayments;
}

class GetStorePaymentData {
  const GetStorePaymentData(this._repository);

  final StorePaymentRepository _repository;

  Future<StorePaymentData> call() async {
    final values = await Future.wait<Object>([
      _repository.getSales(),
      _repository.getPurchases(),
      _repository.getStudentPayments(),
      _repository.getSupplierPayments(),
    ]);

    return StorePaymentData(
      sales: values[0] as List<StoreSaleEntity>,
      purchases: values[1] as List<StorePurchaseEntity>,
      studentPayments: values[2] as List<StoreStudentPaymentEntity>,
      supplierPayments: values[3] as List<StoreSupplierPaymentEntity>,
    );
  }
}

class ReceiveStoreStudentPayment {
  const ReceiveStoreStudentPayment(this._repository);

  final StorePaymentRepository _repository;

  Future<void> call(StoreStudentPaymentEntity payment) {
    return _repository.receiveStudentPayment(payment);
  }
}

class PayStoreSupplier {
  const PayStoreSupplier(this._repository);

  final StorePaymentRepository _repository;

  Future<void> call(StoreSupplierPaymentEntity payment) {
    return _repository.paySupplier(payment);
  }
}
