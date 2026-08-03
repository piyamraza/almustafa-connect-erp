import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_whatsapp_broadcasts.dart';
import 'whatsapp_broadcast_event.dart';
import 'whatsapp_broadcast_state.dart';

class WhatsAppBroadcastBloc
    extends Bloc<WhatsAppBroadcastEvent, WhatsAppBroadcastState> {
  WhatsAppBroadcastBloc({
    required this._getBroadcasts,
    required this._queueBroadcast,
    required this._retryBroadcast,
  }) : super(const WhatsAppBroadcastInitial()) {
    on<LoadWhatsAppBroadcasts>(_load);
    on<QueueWhatsAppBroadcastRequested>(_queue);
    on<RetryWhatsAppBroadcastRequested>(_retry);
  }

  final GetWhatsAppBroadcasts _getBroadcasts;
  final QueueWhatsAppBroadcast _queueBroadcast;
  final RetryWhatsAppBroadcast _retryBroadcast;

  Future<void> _load(
    LoadWhatsAppBroadcasts event,
    Emitter<WhatsAppBroadcastState> emit,
  ) async {
    emit(const WhatsAppBroadcastLoading());
    await _reload(emit);
  }

  Future<void> _queue(
    QueueWhatsAppBroadcastRequested event,
    Emitter<WhatsAppBroadcastState> emit,
  ) async {
    final current = state;
    if (current is WhatsAppBroadcastLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _queueBroadcast(event.broadcast);
      await _reload(emit, message: 'WhatsApp broadcast queued.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _retry(
    RetryWhatsAppBroadcastRequested event,
    Emitter<WhatsAppBroadcastState> emit,
  ) async {
    final current = state;
    if (current is WhatsAppBroadcastLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _retryBroadcast(event.broadcast);
      await _reload(emit, message: 'WhatsApp broadcast retry requested.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _reload(
    Emitter<WhatsAppBroadcastState> emit, {
    String? message,
  }) async {
    try {
      emit(
        WhatsAppBroadcastLoaded(
          broadcasts: await _getBroadcasts(),
          message: message,
        ),
      );
    } catch (error) {
      emit(
        WhatsAppBroadcastFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  void _emitError(
    WhatsAppBroadcastState current,
    Emitter<WhatsAppBroadcastState> emit,
    Object error,
  ) {
    final message = error.toString().replaceFirst('Exception: ', '');

    if (current is WhatsAppBroadcastLoaded) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: message,
          clearMessages: true,
        ),
      );
    } else {
      emit(WhatsAppBroadcastFailure(message));
    }
  }
}
