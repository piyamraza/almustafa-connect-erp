import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_whatsapp.dart';
import 'whatsapp_event.dart';
import 'whatsapp_state.dart';

class WhatsAppBloc extends Bloc<WhatsAppEvent, WhatsAppState> {
  WhatsAppBloc({
    required this._getData,
    required this._saveTemplate,
    required this._sendMessage,
  }) : super(const WhatsAppInitial()) {
    on<LoadWhatsAppDashboard>(_load);
    on<SaveWhatsAppTemplateRequested>(_saveTemplateEvent);
    on<SendWhatsAppMessageRequested>(_sendMessageEvent);
  }

  final GetWhatsAppData _getData;
  final SaveWhatsAppTemplate _saveTemplate;
  final SendWhatsAppMessage _sendMessage;

  Future<void> _load(
    LoadWhatsAppDashboard event,
    Emitter<WhatsAppState> emit,
  ) async {
    emit(const WhatsAppLoading());
    await _reload(emit);
  }

  Future<void> _saveTemplateEvent(
    SaveWhatsAppTemplateRequested event,
    Emitter<WhatsAppState> emit,
  ) async {
    final current = state;
    if (current is WhatsAppLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _saveTemplate(event.template);
      await _reload(emit, message: 'WhatsApp template saved.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _sendMessageEvent(
    SendWhatsAppMessageRequested event,
    Emitter<WhatsAppState> emit,
  ) async {
    final current = state;
    if (current is WhatsAppLoaded) {
      emit(current.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _sendMessage(event.request);
      await _reload(emit, message: 'WhatsApp send request submitted.');
    } catch (error) {
      _emitError(current, emit, error);
    }
  }

  Future<void> _reload(Emitter<WhatsAppState> emit, {String? message}) async {
    try {
      final data = await _getData();
      emit(
        WhatsAppLoaded(
          templates: data.templates,
          requests: data.requests,
          message: message,
        ),
      );
    } catch (error) {
      emit(WhatsAppFailure(_message(error)));
    }
  }

  void _emitError(
    WhatsAppState current,
    Emitter<WhatsAppState> emit,
    Object error,
  ) {
    if (current is WhatsAppLoaded) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    } else {
      emit(WhatsAppFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
