import 'package:equatable/equatable.dart';

import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';

sealed class WhatsAppEvent extends Equatable {
  const WhatsAppEvent();

  @override
  List<Object?> get props => const [];
}

class LoadWhatsAppDashboard extends WhatsAppEvent {
  const LoadWhatsAppDashboard();
}

class SaveWhatsAppTemplateRequested extends WhatsAppEvent {
  const SaveWhatsAppTemplateRequested(this.template);

  final WhatsAppTemplateEntity template;

  @override
  List<Object?> get props => [template];
}

class SendWhatsAppMessageRequested extends WhatsAppEvent {
  const SendWhatsAppMessageRequested(this.request);

  final WhatsAppMessageRequestEntity request;

  @override
  List<Object?> get props => [request];
}
