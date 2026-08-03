import '../entities/whatsapp_message_request_entity.dart';
import '../entities/whatsapp_template_entity.dart';

abstract class WhatsAppRepository {
  Future<List<WhatsAppTemplateEntity>> getTemplates();
  Future<void> saveTemplate(WhatsAppTemplateEntity template);
  Future<List<WhatsAppMessageRequestEntity>> getRequests();
  Future<void> saveRequest(WhatsAppMessageRequestEntity request);
}
