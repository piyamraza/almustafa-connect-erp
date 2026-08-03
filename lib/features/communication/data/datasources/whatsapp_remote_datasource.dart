import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/whatsapp_message_request_entity.dart';
import '../../domain/entities/whatsapp_template_entity.dart';
import '../models/whatsapp_message_request_model.dart';
import '../models/whatsapp_template_model.dart';

abstract class WhatsAppRemoteDataSource {
  Future<List<WhatsAppTemplateEntity>> getTemplates();
  Future<void> saveTemplate(WhatsAppTemplateEntity template);
  Future<List<WhatsAppMessageRequestEntity>> getRequests();
  Future<void> saveRequest(WhatsAppMessageRequestEntity request);
}

class WhatsAppRemoteDataSourceImpl implements WhatsAppRemoteDataSource {
  const WhatsAppRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<WhatsAppTemplateEntity>> getTemplates() async {
    final snapshot = await _service
        .collection(FirestorePaths.whatsappTemplates)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => WhatsAppTemplateModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();

    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  @override
  Future<void> saveTemplate(WhatsAppTemplateEntity template) {
    return _service
        .collection(FirestorePaths.whatsappTemplates)
        .doc(template.id)
        .set(WhatsAppTemplateModel.fromEntity(template).toMap());
  }

  @override
  Future<List<WhatsAppMessageRequestEntity>> getRequests() async {
    final snapshot = await _service
        .collection(FirestorePaths.whatsappMessageRequests)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => WhatsAppMessageRequestModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  @override
  Future<void> saveRequest(WhatsAppMessageRequestEntity request) {
    return _service
        .collection(FirestorePaths.whatsappMessageRequests)
        .doc(request.id)
        .set(WhatsAppMessageRequestModel.fromEntity(request).toMap());
  }
}
