import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_system_health.dart';
import 'system_health_event.dart';
import 'system_health_state.dart';

class SystemHealthBloc extends Bloc<SystemHealthEvent, SystemHealthState> {
  SystemHealthBloc(this._checkHealth) : super(const SystemHealthInitial()) {
    on<LoadSystemHealth>(_load);
    on<RefreshSystemHealth>(_refresh);
  }

  final CheckSystemHealth _checkHealth;

  Future<void> _load(
    LoadSystemHealth event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(const SystemHealthLoading());
    await _run(emit);
  }

  Future<void> _refresh(
    RefreshSystemHealth event,
    Emitter<SystemHealthState> emit,
  ) async {
    emit(const SystemHealthLoading());
    await _run(emit);
  }

  Future<void> _run(Emitter<SystemHealthState> emit) async {
    try {
      emit(SystemHealthLoaded(await _checkHealth()));
    } catch (error) {
      emit(
        SystemHealthFailure(error.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}
