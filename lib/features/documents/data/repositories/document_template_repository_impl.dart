import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/repositories/document_template_repository.dart';
import '../datasources/document_template_remote_datasource.dart';

class DocumentTemplateRepositoryImpl
    implements DocumentTemplateRepository {
  const DocumentTemplateRepositoryImpl(
    this._remoteDataSource,
  );

  final DocumentTemplateRemoteDataSource
      _remoteDataSource;

  @override
  Future<List<DocumentTemplateEntity>> getTemplates(
    DocumentType documentType,
  ) {
    return _remoteDataSource.getTemplates(
      documentType,
    );
  }

  @override
  Future<DocumentTemplateEntity?> getTemplateById(
    String templateId,
  ) {
    return _remoteDataSource.getTemplateById(
      templateId,
    );
  }

  @override
  Future<DocumentTemplateEntity?> getDefaultTemplate(
    DocumentType documentType,
  ) async {
    final templates = await getTemplates(
      documentType,
    );

    for (final template in templates) {
      if (template.isActive &&
          template.isDefault) {
        return template;
      }
    }

    for (final template in templates) {
      if (template.isActive) {
        return template;
      }
    }

    return null;
  }

  @override
  Future<void> saveTemplate(
    DocumentTemplateEntity template,
  ) {
    return _remoteDataSource.saveTemplate(
      template,
    );
  }

  @override
  Future<void> deleteTemplate(
    String templateId,
  ) {
    return _remoteDataSource.deleteTemplate(
      templateId,
    );
  }

  @override
  Future<void> setDefaultTemplate({
    required DocumentType documentType,
    required String templateId,
  }) {
    return _remoteDataSource.setDefaultTemplate(
      documentType: documentType,
      templateId: templateId,
    );
  }
}
