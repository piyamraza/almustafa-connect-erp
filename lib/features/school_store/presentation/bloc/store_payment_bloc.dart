import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_store_payments.dart';
import 'store_payment_event.dart';
import 'store_payment_state.dart';

class StorePaymentBloc extends Bloc<StorePaymentEvent, StorePaymentState> {
  StorePaymentBloc({
    required this._getData,
    required this._receiveStudentPayment,
    required this._paySupplier,
  }) : super(const StorePaymentInitial()) {
    on<LoadStorePayments>(_load);
    on<ReceiveStudentPaymentRequested>(_receive);
    on<PaySupplierRequested>(_pay);
  }

  final GetStorePaymentData _getData;
  final ReceiveStoreStudentPayment _receiveStudentPayment;
  final PayStoreSupplier _paySupplier;

  Future<void> _load(
    LoadStorePayments event,
    Emitter<StorePaymentState> emit,
  ) async {
    emit(const StorePaymentLoading());
    await _reload(emit);
  }

  Future<void> _receive(
    ReceiveStudentPaymentRequested event,
    Emitter<StorePaymentState> emit,
  ) async {
    try {
      await _receiveStudentPayment(event.payment);
      await _reload(emit, message: 'Student payment received.');
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  Future<void> _pay(
    PaySupplierRequested event,
    Emitter<StorePaymentState> emit,
  ) async {
    try {
      await _paySupplier(event.payment);
      await _reload(emit, message: 'Supplier payment saved.');
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StorePaymentState> emit, {
    String? message,
  }) async {
    try {
      final data = await _getData();

      emit(
        StorePaymentLoaded(
          sales: data.sales,
          purchases: data.purchases,
          studentPayments: data.studentPayments,
          supplierPayments: data.supplierPayments,
          message: message,
        ),
      );
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
