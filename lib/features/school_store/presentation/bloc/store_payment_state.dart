import 'package:equatable/equatable.dart';

import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';

sealed class StorePaymentState extends Equatable {
  const StorePaymentState();

  @override
  List<Object?> get props => const [];
}

class StorePaymentInitial extends StorePaymentState {
  const StorePaymentInitial();
}

class StorePaymentLoading extends StorePaymentState {
  const StorePaymentLoading();
}

class StorePaymentLoaded extends StorePaymentState {
  const StorePaymentLoaded({
    required this.sales,
    required this.purchases,
    required this.studentPayments,
    required this.supplierPayments,
    this.message,
  });

  final List<StoreSaleEntity> sales;
  final List<StorePurchaseEntity> purchases;
  final List<StoreStudentPaymentEntity> studentPayments;
  final List<StoreSupplierPaymentEntity> supplierPayments;
  final String? message;

  double get studentOutstanding =>
      sales.fold<double>(0, (sum, sale) => sum + sale.outstandingAmount);

  double get supplierOutstanding => purchases.fold<double>(
    0,
    (sum, purchase) => sum + purchase.outstandingAmount,
  );

  double get studentPaymentsReceived =>
      studentPayments.fold<double>(0, (sum, payment) => sum + payment.amount);

  double get supplierPaymentsMade =>
      supplierPayments.fold<double>(0, (sum, payment) => sum + payment.amount);

  @override
  List<Object?> get props => [
    sales,
    purchases,
    studentPayments,
    supplierPayments,
    message,
  ];
}

class StorePaymentFailure extends StorePaymentState {
  const StorePaymentFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
