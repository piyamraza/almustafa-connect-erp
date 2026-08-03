import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/manage_store_items.dart';
import 'school_store_event.dart';
import 'school_store_state.dart';

class SchoolStoreBloc extends Bloc<SchoolStoreEvent, SchoolStoreState> {
  SchoolStoreBloc({
    required this._getItems,
    required this._saveItem,
    required this._deleteItem,
  }) : super(const SchoolStoreInitial()) {
    on<LoadSchoolStore>(_load);
    on<SaveStoreItemRequested>(_save);
    on<DeleteStoreItemRequested>(_delete);
  }
  final GetStoreItems _getItems;
  final SaveStoreItem _saveItem;
  final DeleteStoreItem _deleteItem;
  Future<void> _load(LoadSchoolStore e, Emitter<SchoolStoreState> emit) async {
    emit(const SchoolStoreLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveStoreItemRequested e,
    Emitter<SchoolStoreState> emit,
  ) async {
    try {
      await _saveItem(e.item);
      await _reload(emit, message: 'Item saved.');
    } catch (x) {
      emit(SchoolStoreFailure('$x'));
    }
  }

  Future<void> _delete(
    DeleteStoreItemRequested e,
    Emitter<SchoolStoreState> emit,
  ) async {
    try {
      await _deleteItem(e.itemId);
      await _reload(emit, message: 'Item deleted.');
    } catch (x) {
      emit(SchoolStoreFailure('$x'));
    }
  }

  Future<void> _reload(
    Emitter<SchoolStoreState> emit, {
    String? message,
  }) async {
    try {
      emit(SchoolStoreLoaded(items: await _getItems(), message: message));
    } catch (x) {
      emit(SchoolStoreFailure('$x'));
    }
  }
}
