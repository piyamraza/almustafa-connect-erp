import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/document_page_entity.dart';
import '../../domain/entities/document_template_category.dart';
import '../../domain/entities/document_template_entity.dart';
import '../../domain/entities/document_type.dart';
import 'document_page_model.dart';

class DocumentTemplateModel {
  const DocumentTemplateModel();

  static Map<String, dynamic> toMap(
    DocumentTemplateEntity template,
  ) {
    return {
      'id': template.id,
      'name': template.name,
      'documentType': template.documentType.name,
      'category': template.category.name,
      'version': template.version,
      'layoutKey': template.layoutKey,
      'description': template.description,
      'isDefault': template.isDefault,
      'isActive': template.isActive,
      'useSchoolLogo': template.useSchoolLogo,
      'useSchoolName': template.useSchoolName,
      'usePrincipalName': template.usePrincipalName,
      'usePrincipalDesignation':
          template.usePrincipalDesignation,
      'usePrincipalSignature':
          template.usePrincipalSignature,
      'useSchoolStamp': template.useSchoolStamp,
      'pages': template.pages
          .map(
            DocumentPageModel.toMap,
          )
          .toList(),
      'createdAt': template.createdAt?.toIso8601String(),
      'updatedAt': template.updatedAt?.toIso8601String(),
      'metadata': template.metadata,
      'schemaVersion': 1,
    };
  }

  static DocumentTemplateEntity fromMap(
    Map<String, dynamic> map,
  ) {
    final rawPages = map['pages'];

    final List<DocumentPageEntity> pages =
        rawPages is Iterable
            ? rawPages
                .whereType<Map>()
                .map<DocumentPageEntity>(
                  (item) => DocumentPageModel.fromMap(
                    item.map(
                      (key, value) => MapEntry(
                        key.toString(),
                        value,
                      ),
                    ),
                  ),
                )
                .toList()
            : <DocumentPageEntity>[];

    return DocumentTemplateEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      documentType: _documentType(
        map['documentType'],
      ),
      category: _category(
        map['category'],
      ),
      version: _int(
        map['version'],
        fallback: 1,
      ),
      layoutKey:
          map['layoutKey'] as String? ?? '',
      pages: pages,
      description:
          map['description'] as String? ?? '',
      isDefault:
          map['isDefault'] as bool? ?? false,
      isActive:
          map['isActive'] as bool? ?? true,
      useSchoolLogo:
          map['useSchoolLogo'] as bool? ?? true,
      useSchoolName:
          map['useSchoolName'] as bool? ?? true,
      usePrincipalName:
          map['usePrincipalName'] as bool? ?? false,
      usePrincipalDesignation:
          map['usePrincipalDesignation'] as bool? ?? false,
      usePrincipalSignature:
          map['usePrincipalSignature'] as bool? ?? false,
      useSchoolStamp:
          map['useSchoolStamp'] as bool? ?? false,
      createdAt: _date(
        map['createdAt'],
      ),
      updatedAt: _date(
        map['updatedAt'],
      ),
      metadata: _map(
        map['metadata'],
      ),
    );
  }

  static DocumentType _documentType(
    dynamic raw,
  ) {
    final name = raw?.toString();

    for (final value in DocumentType.values) {
      if (value.name == name) {
        return value;
      }
    }

    return DocumentType.birthdayCard;
  }

  static DocumentTemplateCategory _category(
    dynamic raw,
  ) {
    final name = raw?.toString();

    for (final value
        in DocumentTemplateCategory.values) {
      if (value.name == name) {
        return value;
      }
    }

    return DocumentTemplateCategory.custom;
  }

  static DateTime? _date(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static Map<String, dynamic> _map(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(
          key.toString(),
          item,
        ),
      );
    }

    return <String, dynamic>{};
  }

  static int _int(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }
}