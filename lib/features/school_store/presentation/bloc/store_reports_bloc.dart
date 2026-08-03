import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_store_reports.dart';
import 'store_reports_event.dart';
import 'store_reports_state.dart';

class StoreReportsBloc extends Bloc<StoreReportsEvent, StoreReportsState> {
  StoreReportsBloc(this._getReports) : super(const StoreReportsInitial()) {
    on<LoadStoreReports>(_load);
  }

  final GetStoreReports _getReports;

  Future<void> _load(
    LoadStoreReports event,
    Emitter<StoreReportsState> emit,
  ) async {
    emit(const StoreReportsLoading());

    try {
      emit(StoreReportsLoaded(await _getReports()));
    } catch (error) {
      emit(
        StoreReportsFailure(error.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}
