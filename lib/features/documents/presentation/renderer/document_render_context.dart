import '../../domain/entities/document_branding_entity.dart';
import '../../domain/entities/document_data_entity.dart';
import '../../domain/entities/document_template_entity.dart';

class DocumentRenderContext {
  const DocumentRenderContext({
    required this.template,
    required this.data,
    required this.branding,
    required this.values,
  });

  final DocumentTemplateEntity template;
  final DocumentDataEntity data;
  final DocumentBrandingEntity branding;

  /// Final merged values used by the renderer.
  ///
  /// Example keys:
  /// student.name
  /// birthday.message
  /// branding.schoolName
  final Map<String, dynamic> values;
}
