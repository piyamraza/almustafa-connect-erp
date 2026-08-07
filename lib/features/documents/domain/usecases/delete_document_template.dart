import '../repositories/document_template_repository.dart';

class DeleteDocumentTemplate {
  const DeleteDocumentTemplate(
    this._repository,
  );

  final DocumentTemplateRepository _repository;

  Future<void> call(
    String templateId,
  ) {
    final normalizedId =
        templateId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'Template id cannot be empty.',
      );
    }

    return _repository.deleteTemplate(
      normalizedId,
    );
  }
}
