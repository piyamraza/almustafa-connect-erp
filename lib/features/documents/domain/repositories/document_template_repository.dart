import '../entities/document_template_entity.dart';
import '../entities/document_type.dart';

abstract class DocumentTemplateRepository {
  Future<List<DocumentTemplateEntity>>
      getTemplates(
    DocumentType documentType,
  );

  Future<DocumentTemplateEntity?>
      getTemplateById(
    String templateId,
  );

  Future<DocumentTemplateEntity?>
      getDefaultTemplate(
    DocumentType documentType,
  );

  Future<void> saveTemplate(
    DocumentTemplateEntity template,
  );

  Future<void> deleteTemplate(
    String templateId,
  );

  Future<void> setDefaultTemplate({
    required DocumentType documentType,
    required String templateId,
  });
}
