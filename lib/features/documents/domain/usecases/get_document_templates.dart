import '../entities/document_template_entity.dart';
import '../entities/document_type.dart';
import '../repositories/document_template_repository.dart';

class GetDocumentTemplates {
  const GetDocumentTemplates(
    this._repository,
  );

  final DocumentTemplateRepository _repository;

  Future<List<DocumentTemplateEntity>> call(
    DocumentType documentType,
  ) {
    return _repository.getTemplates(
      documentType,
    );
  }
}
