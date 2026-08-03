import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';
import '../../domain/repositories/whatsapp_repository.dart';
import '../datasources/whatsapp_remote_datasource.dart';

class WhatsAppRepositoryImpl implements WhatsAppRepository {
  const WhatsAppRepositoryImpl(this._source);

  final WhatsAppRemoteDataSource _source;

  @override
  Future<List<WhatsAppTemplateEntity>> getTemplates() {
    return _source.getTemplates();
  }

  @override
  Future<void> saveTemplate(WhatsAppTemplateEntity template) {
    return _source.saveTemplate(template);
  }

  @override
  Future<List<WhatsAppMessageRequestEntity>> getRequests() {
    return _source.getRequests();
  }

  @override
  Future<void> saveRequest(WhatsAppMessageRequestEntity request) {
    return _source.saveRequest(request);
  }
}
