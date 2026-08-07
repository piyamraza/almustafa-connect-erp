import '../entities/document_type.dart';
import '../repositories/document_template_repository.dart';

class SetDefaultDocumentTemplate {
  const SetDefaultDocumentTemplate(
    this._repository,
  );

  final DocumentTemplateRepository _repository;

  Future<void> call({
    required DocumentType documentType,
    required String templateId,
  }) {
    final normalizedId =
        templateId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'Template id cannot be empty.',
      );
    }

    return _repository.setDefaultTemplate(
      documentType: documentType,
      templateId: normalizedId,
    );
  }
}
