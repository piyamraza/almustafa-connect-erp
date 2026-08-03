import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_communication_broadcasts.dart';
import 'communication_broadcast_event.dart';
import 'communication_broadcast_state.dart';

class CommunicationBroadcastBloc
    extends Bloc<CommunicationBroadcastEvent, CommunicationBroadcastState> {
  CommunicationBroadcastBloc({
    required this._getBroadcasts,
    required this._queueBroadcast,
    required this._retryBroadcast,
  }) : super(const CommunicationBroadcastInitial()) {
    on<LoadCommunicationBroadcasts>(_load);
    on<QueueCommunicationBroadcastRequested>(_queue);
    on<RetryCommunicationBroadcastRequested>(_retry);
  }

  final GetCommunicationBroadcasts _getBroadcasts;
  final QueueCommunicationBroadcast _queueBroadcast;
  final RetryCommunicationBroadcast _retryBroadcast;

  Future<void> _load(
    LoadCommunicationBroadcasts event,
    Emitter<CommunicationBroadcastState> emit,
  ) async {
    emit(const CommunicationBroadcastLoading());
    await _reload(emit);
  }

  Future<void> _queue(
    QueueCommunicationBroadcastRequested event,
    Emitter<CommunicationBroadcastState> emit,
  ) async {
    final current = state;

    if (current is CommunicationBroadcastLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _queueBroadcast(event.broadcast);
      await _reload(emit, message: 'Broadcast queued successfully.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _retry(
    RetryCommunicationBroadcastRequested event,
    Emitter<CommunicationBroadcastState> emit,
  ) async {
    final current = state;

    if (current is CommunicationBroadcastLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _retryBroadcast(event.broadcast);
      await _reload(emit, message: 'Broadcast retry requested.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _reload(
    Emitter<CommunicationBroadcastState> emit, {
    String? message,
  }) async {
    try {
      emit(
        CommunicationBroadcastLoaded(
          broadcasts: await _getBroadcasts(),
          message: message,
        ),
      );
    } catch (error) {
      emit(CommunicationBroadcastFailure(_message(error)));
    }
  }

  void _emitError(
    CommunicationBroadcastState current,
    Emitter<CommunicationBroadcastState> emit,
    Object error,
  ) {
    if (current is CommunicationBroadcastLoaded) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    } else {
      emit(CommunicationBroadcastFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
