import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../models/store_purchase_model.dart';
import '../models/store_sale_model.dart';
import '../models/store_student_payment_model.dart';
import '../models/store_supplier_payment_model.dart';

abstract class StorePaymentRemoteDataSource {
  Future<List<StoreSaleEntity>> getSales();
  Future<List<StorePurchaseEntity>> getPurchases();

  Future<List<StoreStudentPaymentEntity>> getStudentPayments();

  Future<List<StoreSupplierPaymentEntity>> getSupplierPayments();

  Future<void> receiveStudentPayment(StoreStudentPaymentEntity payment);

  Future<void> paySupplier(StoreSupplierPaymentEntity payment);
}

class StorePaymentRemoteDataSourceImpl implements StorePaymentRemoteDataSource {
  const StorePaymentRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreSaleEntity>> getSales() async {
    final snapshot = await _service.collection(FirestorePaths.storeSales).get();

    final values = snapshot.docs
        .map((doc) => StoreSaleModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => a.saleDate.compareTo(b.saleDate));
    return values;
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() async {
    final snapshot = await _service
        .collection(FirestorePaths.storePurchases)
        .get();

    final values = snapshot.docs
        .map((doc) => StorePurchaseModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    values.sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));

    return values;
  }

  @override
  Future<List<StoreStudentPaymentEntity>> getStudentPayments() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeStudentPayments)
        .get();

    final values = snapshot.docs
        .map(
          (doc) =>
              StoreStudentPaymentModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return values;
  }

  @override
  Future<List<StoreSupplierPaymentEntity>> getSupplierPayments() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeSupplierPayments)
        .get();

    final values = snapshot.docs
        .map(
          (doc) =>
              StoreSupplierPaymentModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return values;
  }

  @override
  Future<void> receiveStudentPayment(StoreStudentPaymentEntity payment) async {
    final sales = (await getSales())
        .where(
          (sale) =>
              sale.studentId == payment.studentId && sale.outstandingAmount > 0,
        )
        .toList();

    final due = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.outstandingAmount,
    );

    if (payment.amount <= 0 || payment.amount > due) {
      throw ArgumentError(
        'Payment must be above zero and not exceed outstanding.',
      );
    }

    var balance = payment.amount;

    for (final sale in sales) {
      if (balance <= 0) break;

      final allocation = balance >= sale.outstandingAmount
          ? sale.outstandingAmount
          : balance;

      final updated = StoreSaleEntity(
        id: sale.id,
        studentId: sale.studentId,
        studentName: sale.studentName,
        admissionNo: sale.admissionNo,
        classId: sale.classId,
        sectionId: sale.sectionId,
        itemId: sale.itemId,
        itemName: sale.itemName,
        quantity: sale.quantity,
        unitSalePrice: sale.unitSalePrice,
        unitPurchasePrice: sale.unitPurchasePrice,
        discount: sale.discount,
        paidAmount: sale.paidAmount + allocation,
        saleDate: sale.saleDate,
        createdAt: sale.createdAt,
        updatedAt: DateTime.now(),
        notes: sale.notes,
      );

      await _service
          .collection(FirestorePaths.storeSales)
          .doc(sale.id)
          .set(StoreSaleModel.fromEntity(updated).toMap());

      balance -= allocation;
    }

    await _service
        .collection(FirestorePaths.storeStudentPayments)
        .doc(payment.id)
        .set(StoreStudentPaymentModel.fromEntity(payment).toMap());
  }

  @override
  Future<void> paySupplier(StoreSupplierPaymentEntity payment) async {
    final purchases = (await getPurchases())
        .where(
          (purchase) =>
              purchase.supplierId == payment.supplierId &&
              purchase.outstandingAmount > 0,
        )
        .toList();

    final due = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.outstandingAmount,
    );

    if (payment.amount <= 0 || payment.amount > due) {
      throw ArgumentError(
        'Payment must be above zero and not exceed supplier due.',
      );
    }

    var balance = payment.amount;

    for (final purchase in purchases) {
      if (balance <= 0) break;

      final allocation = balance >= purchase.outstandingAmount
          ? purchase.outstandingAmount
          : balance;

      final updated = StorePurchaseEntity(
        id: purchase.id,
        supplierId: purchase.supplierId,
        supplierName: purchase.supplierName,
        itemId: purchase.itemId,
        itemName: purchase.itemName,
        invoiceNumber: purchase.invoiceNumber,
        quantity: purchase.quantity,
        unitPrice: purchase.unitPrice,
        paidAmount: purchase.paidAmount + allocation,
        purchaseDate: purchase.purchaseDate,
        createdAt: purchase.createdAt,
        updatedAt: DateTime.now(),
      );

      await _service
          .collection(FirestorePaths.storePurchases)
          .doc(purchase.id)
          .set(StorePurchaseModel.fromEntity(updated).toMap());

      balance -= allocation;
    }

    await _service
        .collection(FirestorePaths.storeSupplierPayments)
        .doc(payment.id)
        .set(StoreSupplierPaymentModel.fromEntity(payment).toMap());
  }
}
