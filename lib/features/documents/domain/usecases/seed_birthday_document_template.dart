import '../../templates/birthday/birthday_card_template_v1.dart';
import '../entities/document_type.dart';
import '../repositories/document_template_repository.dart';
import '../services/document_template_validator.dart';

class SeedBirthdayDocumentTemplate {
  const SeedBirthdayDocumentTemplate(
    this._repository,
    this._validator,
  );

  final DocumentTemplateRepository _repository;
  final DocumentTemplateValidator _validator;

  Future<void> call() async {
    final template =
        buildBirthdayCardTemplateV1();

    final validation =
        _validator.validate(template);

    if (!validation.isValid) {
      throw StateError(
        validation.errors.join(' '),
      );
    }

    final existing =
        await _repository.getTemplateById(
      template.id,
    );

    if (existing == null) {
      await _repository.saveTemplate(
        template,
      );
    }

    final currentDefault =
        await _repository.getDefaultTemplate(
      DocumentType.birthdayCard,
    );

    if (currentDefault == null) {
      await _repository.setDefaultTemplate(
        documentType:
            DocumentType.birthdayCard,
        templateId: template.id,
      );
    }
  }
}
