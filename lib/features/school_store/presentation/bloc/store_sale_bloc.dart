import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../../domain/usecases/manage_store_items.dart';
import '../../domain/usecases/manage_store_sales.dart';
import 'store_sale_event.dart';
import 'store_sale_state.dart';

class StoreSaleBloc extends Bloc<StoreSaleEvent, StoreSaleState> {
  StoreSaleBloc({
    required this._getStudents,
    required GetStoreItems getItems,
    required this._getSales,
    required this._saveSale,
  }) : _getItems = getItems,
       super(const StoreSaleInitial()) {
    on<LoadStoreSales>(_load);
    on<SaveStoreSaleRequested>(_save);
  }

  final GetStoreStudents _getStudents;
  final GetStoreItems _getItems;
  final GetStoreSales _getSales;
  final SaveStoreSale _saveSale;

  Future<void> _load(LoadStoreSales event, Emitter<StoreSaleState> emit) async {
    emit(const StoreSaleLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveStoreSaleRequested event,
    Emitter<StoreSaleState> emit,
  ) async {
    try {
      await _saveSale(event.sale);
      await _reload(emit, message: 'Student sale saved and stock updated.');
    } catch (error) {
      emit(StoreSaleFailure(_message(error)));
    }
  }

  Future<void> _reload(Emitter<StoreSaleState> emit, {String? message}) async {
    try {
      final values = await Future.wait<Object>([
        _getStudents(),
        _getItems(),
        _getSales(),
      ]);

      emit(
        StoreSaleLoaded(
          students: values[0] as List<StoreStudentOptionEntity>,
          items: values[1] as List<StoreItemEntity>,
          sales: values[2] as List<StoreSaleEntity>,
          message: message,
        ),
      );
    } catch (error) {
      emit(StoreSaleFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
