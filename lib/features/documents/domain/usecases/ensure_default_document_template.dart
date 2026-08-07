import '../entities/document_template_entity.dart';
import '../entities/document_type.dart';
import '../repositories/document_template_repository.dart';

class EnsureDefaultDocumentTemplate {
  const EnsureDefaultDocumentTemplate(
    this._repository,
  );

  final DocumentTemplateRepository _repository;

  Future<DocumentTemplateEntity?> call(
    DocumentType documentType,
  ) async {
    final currentDefault =
        await _repository.getDefaultTemplate(
      documentType,
    );

    if (currentDefault != null) {
      return currentDefault;
    }

    final templates =
        await _repository.getTemplates(
      documentType,
    );

    for (final template in templates) {
      if (!template.isActive) {
        continue;
      }

      await _repository.setDefaultTemplate(
        documentType: documentType,
        templateId: template.id,
      );

      return template.copyWith(
        isDefault: true,
      );
    }

    return null;
  }
}
