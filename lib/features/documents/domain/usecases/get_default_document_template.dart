import '../entities/document_template_entity.dart';
import '../entities/document_type.dart';
import '../repositories/document_template_repository.dart';

class GetDefaultDocumentTemplate {
  const GetDefaultDocumentTemplate(
    this._repository,
  );

  final DocumentTemplateRepository _repository;

  Future<DocumentTemplateEntity?> call(
    DocumentType documentType,
  ) {
    return _repository.getDefaultTemplate(
      documentType,
    );
  }
}
