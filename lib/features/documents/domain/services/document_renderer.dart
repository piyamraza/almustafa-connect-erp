import '../entities/document_branding_entity.dart';
import '../entities/document_data_entity.dart';
import '../entities/document_template_entity.dart';
import '../entities/rendered_document_entity.dart';

abstract class DocumentRenderer {
  Future<RenderedDocumentEntity> render({
    required DocumentTemplateEntity template,
    required DocumentDataEntity data,
    required DocumentBrandingEntity branding,
  });
}
