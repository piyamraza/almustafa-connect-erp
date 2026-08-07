import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';
import '../models/document_template_model.dart';

abstract class DocumentTemplateRemoteDataSource {
  Future<List<DocumentTemplateEntity>> getTemplates(
    DocumentType documentType,
  );

  Future<DocumentTemplateEntity?> getTemplateById(
    String templateId,
  );

  Future<void> saveTemplate(
    DocumentTemplateEntity template,
  );

  Future<void> deleteTemplate(
    String templateId,
  );

  Future<void> setDefaultTemplate({
    required DocumentType documentType,
    required String templateId,
  });
}

class DocumentTemplateRemoteDataSourceImpl
    implements DocumentTemplateRemoteDataSource {
  const DocumentTemplateRemoteDataSourceImpl(
    this._firestoreService,
  );

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<DocumentTemplateEntity>> getTemplates(
    DocumentType documentType,
  ) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.documentTemplates)
        .where(
          'documentType',
          isEqualTo: documentType.name,
        )
        .get();

    final templates = snapshot.docs.map(
      (document) {
        return DocumentTemplateModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    templates.sort(
      (a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }

        final nameComparison = a.name.compareTo(
          b.name,
        );

        if (nameComparison != 0) {
          return nameComparison;
        }

        return b.version.compareTo(
          a.version,
        );
      },
    );

    return templates;
  }

  @override
  Future<DocumentTemplateEntity?> getTemplateById(
    String templateId,
  ) async {
    final normalizedId = templateId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final document = await _firestoreService
        .collection(FirestorePaths.documentTemplates)
        .doc(normalizedId)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data();

    if (data == null) {
      return null;
    }

    return DocumentTemplateModel.fromMap({
      ...data,
      'id': document.id,
    });
  }

  @override
  Future<void> saveTemplate(
    DocumentTemplateEntity template,
  ) {
    final templateId = template.id.trim();

    if (templateId.isEmpty) {
      throw ArgumentError(
        'Template id cannot be empty.',
      );
    }

    return _firestoreService
        .collection(FirestorePaths.documentTemplates)
        .doc(templateId)
        .set(
          DocumentTemplateModel.toMap(
            template,
          ),
        );
  }

  @override
  Future<void> deleteTemplate(
    String templateId,
  ) {
    final normalizedId = templateId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'Template id cannot be empty.',
      );
    }

    return _firestoreService
        .collection(FirestorePaths.documentTemplates)
        .doc(normalizedId)
        .delete();
  }

  @override
  Future<void> setDefaultTemplate({
    required DocumentType documentType,
    required String templateId,
  }) async {
    final normalizedId = templateId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'Template id cannot be empty.',
      );
    }

    final collection = _firestoreService.collection(
      FirestorePaths.documentTemplates,
    );

    final targetDocument =
        await collection.doc(normalizedId).get();

    if (!targetDocument.exists) {
      throw StateError(
        'Template "$normalizedId" does not exist.',
      );
    }

    final targetData = targetDocument.data();

    if (targetData == null) {
      throw StateError(
        'Template "$normalizedId" has no data.',
      );
    }

    final targetType =
        targetData['documentType']?.toString();

    if (targetType != documentType.name) {
      throw StateError(
        'Template "$normalizedId" does not belong to ${documentType.name}.',
      );
    }

    final snapshot = await collection
        .where(
          'documentType',
          isEqualTo: documentType.name,
        )
        .get();

    final batch =
        _firestoreService.instance.batch();

    for (final document in snapshot.docs) {
      batch.update(
        document.reference,
        {
          'isDefault':
              document.id == normalizedId,
          'updatedAt':
              DateTime.now().toIso8601String(),
        },
      );
    }

    await batch.commit();
  }
}
