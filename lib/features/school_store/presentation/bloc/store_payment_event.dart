import 'package:equatable/equatable.dart';

import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';

sealed class StorePaymentEvent extends Equatable {
  const StorePaymentEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStorePayments extends StorePaymentEvent {
  const LoadStorePayments();
}

class ReceiveStudentPaymentRequested extends StorePaymentEvent {
  const ReceiveStudentPaymentRequested(this.payment);

  final StoreStudentPaymentEntity payment;

  @override
  List<Object?> get props => [payment];
}

class PaySupplierRequested extends StorePaymentEvent {
  const PaySupplierRequested(this.payment);

  final StoreSupplierPaymentEntity payment;

  @override
  List<Object?> get props => [payment];
}
