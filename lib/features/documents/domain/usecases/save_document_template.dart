import '../entities/document_template_entity.dart';
import '../repositories/document_template_repository.dart';
import '../services/document_template_validator.dart';

class SaveDocumentTemplate {
  const SaveDocumentTemplate(
    this._repository,
    this._validator,
  );

  final DocumentTemplateRepository _repository;
  final DocumentTemplateValidator _validator;

  Future<void> call(
    DocumentTemplateEntity template,
  ) async {
    final validation =
        _validator.validate(template);

    if (!validation.isValid) {
      throw StateError(
        validation.errors.join(' '),
      );
    }

    await _repository.saveTemplate(
      template,
    );
  }
}
