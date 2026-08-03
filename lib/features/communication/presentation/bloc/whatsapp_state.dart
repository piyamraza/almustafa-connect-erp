import 'package:equatable/equatable.dart';

import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';

sealed class WhatsAppState extends Equatable {
  const WhatsAppState();

  @override
  List<Object?> get props => const [];
}

class WhatsAppInitial extends WhatsAppState {
  const WhatsAppInitial();
}

class WhatsAppLoading extends WhatsAppState {
  const WhatsAppLoading();
}

class WhatsAppLoaded extends WhatsAppState {
  const WhatsAppLoaded({
    required this.templates,
    required this.requests,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<WhatsAppTemplateEntity> templates;
  final List<WhatsAppMessageRequestEntity> requests;
  final bool isProcessing;
  final String? message;
  final String? error;

  WhatsAppLoaded copyWith({
    List<WhatsAppTemplateEntity>? templates,
    List<WhatsAppMessageRequestEntity>? requests,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return WhatsAppLoaded(
      templates: templates ?? this.templates,
      requests: requests ?? this.requests,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    templates,
    requests,
    isProcessing,
    message,
    error,
  ];
}

class WhatsAppFailure extends WhatsAppState {
  const WhatsAppFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
