import '../entities/whatsapp_message_request_entity.dart';
import '../entities/whatsapp_template_entity.dart';
import '../repositories/whatsapp_repository.dart';
import '../services/whatsapp_sender_service.dart';

class GetWhatsAppData {
  const GetWhatsAppData(this._repository);

  final WhatsAppRepository _repository;

  Future<WhatsAppData> call() async {
    final values = await Future.wait<Object>([
      _repository.getTemplates(),
      _repository.getRequests(),
    ]);

    return WhatsAppData(
      templates: values[0] as List<WhatsAppTemplateEntity>,
      requests: values[1] as List<WhatsAppMessageRequestEntity>,
    );
  }
}

class WhatsAppData {
  const WhatsAppData({required this.templates, required this.requests});

  final List<WhatsAppTemplateEntity> templates;
  final List<WhatsAppMessageRequestEntity> requests;
}

class SaveWhatsAppTemplate {
  const SaveWhatsAppTemplate(this._repository);

  final WhatsAppRepository _repository;

  Future<void> call(WhatsAppTemplateEntity template) {
    if (template.name.trim().isEmpty) {
      throw ArgumentError('Template name is required.');
    }
    if (template.body.trim().isEmpty) {
      throw ArgumentError('Template body is required.');
    }
    return _repository.saveTemplate(template);
  }
}

class SendWhatsAppMessage {
  const SendWhatsAppMessage(this._repository, this._sender);

  final WhatsAppRepository _repository;
  final WhatsAppSenderService _sender;

  Future<void> call(WhatsAppMessageRequestEntity request) async {
    final phone = request.recipientPhone.replaceAll(RegExp(r'[^0-9+]'), '');

    if (phone.length < 10) {
      throw ArgumentError('Valid WhatsApp number is required.');
    }

    if (request.templateName.trim().isEmpty) {
      throw ArgumentError('Approved template is required.');
    }

    await _repository.saveRequest(request);

    try {
      await _sender.send(request);
    } catch (error) {
      final failed = WhatsAppMessageRequestEntity(
        id: request.id,
        recipientPhone: request.recipientPhone,
        templateName: request.templateName,
        languageCode: request.languageCode,
        parameters: request.parameters,
        status: WhatsAppMessageStatus.failed,
        createdBy: request.createdBy,
        createdAt: request.createdAt,
        updatedAt: DateTime.now(),
        attachmentUrl: request.attachmentUrl,
        failureReason: error.toString(),
        retryCount: request.retryCount,
      );
      await _repository.saveRequest(failed);
      rethrow;
    }
  }
}
