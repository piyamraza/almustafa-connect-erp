import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../../domain/usecases/manage_store_items.dart';
import '../../domain/usecases/manage_store_purchases.dart';
import 'store_purchase_event.dart';
import 'store_purchase_state.dart';

class StorePurchaseBloc extends Bloc<StorePurchaseEvent, StorePurchaseState> {
  StorePurchaseBloc({
    required this._getSuppliers,
    required this._saveSupplier,
    required this._getPurchases,
    required this._savePurchase,
    required this._getItems,
  }) : super(const StorePurchaseInitial()) {
    on<LoadStorePurchases>(_load);
    on<SaveStoreSupplierRequested>(_saveSupplierEvent);
    on<SaveStorePurchaseRequested>(_savePurchaseEvent);
  }

  final GetStoreSuppliers _getSuppliers;
  final SaveStoreSupplier _saveSupplier;
  final GetStorePurchases _getPurchases;
  final SaveStorePurchase _savePurchase;
  final GetStoreItems _getItems;

  Future<void> _load(
    LoadStorePurchases event,
    Emitter<StorePurchaseState> emit,
  ) async {
    emit(const StorePurchaseLoading());
    await _reload(emit);
  }

  Future<void> _saveSupplierEvent(
    SaveStoreSupplierRequested event,
    Emitter<StorePurchaseState> emit,
  ) async {
    try {
      await _saveSupplier(event.supplier);
      await _reload(emit, message: 'Supplier saved successfully.');
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  Future<void> _savePurchaseEvent(
    SaveStorePurchaseRequested event,
    Emitter<StorePurchaseState> emit,
  ) async {
    try {
      await _savePurchase(event.purchase);
      await _reload(emit, message: 'Purchase saved and stock updated.');
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StorePurchaseState> emit, {
    String? message,
  }) async {
    try {
      final values = await Future.wait<Object>([
        _getSuppliers(),
        _getPurchases(),
        _getItems(),
      ]);

      emit(
        StorePurchaseLoaded(
          suppliers: values[0] as List<StoreSupplierEntity>,
          purchases: values[1] as List<StorePurchaseEntity>,
          items: values[2] as List<StoreItemEntity>,
          message: message,
        ),
      );
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
