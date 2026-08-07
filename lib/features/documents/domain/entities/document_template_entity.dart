import 'document_page_entity.dart';
import 'document_template_category.dart';
import 'document_type.dart';

class DocumentTemplateEntity {
  const DocumentTemplateEntity({
    required this.id,
    required this.name,
    required this.documentType,
    required this.version,
    required this.layoutKey,
    required this.pages,
    this.category = DocumentTemplateCategory.custom,
    this.description = '',
    this.isDefault = false,
    this.isActive = true,
    this.useSchoolLogo = true,
    this.useSchoolName = true,
    this.usePrincipalName = false,
    this.usePrincipalDesignation = false,
    this.usePrincipalSignature = false,
    this.useSchoolStamp = false,
    this.createdAt,
    this.updatedAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String name;

  final DocumentType documentType;
  final DocumentTemplateCategory category;

  final int version;

  /// Stable renderer/layout identifier.
  ///
  /// Example:
  /// birthday_kids_blue
  final String layoutKey;

  final String description;

  final bool isDefault;
  final bool isActive;

  final bool useSchoolLogo;
  final bool useSchoolName;

  final bool usePrincipalName;
  final bool usePrincipalDesignation;
  final bool usePrincipalSignature;

  final bool useSchoolStamp;

  final List<DocumentPageEntity> pages;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final Map<String, dynamic> metadata;

  bool get hasPages => pages.isNotEmpty;

  int get pageCount => pages.length;

  List<DocumentPageEntity> get orderedPages {
    final result =
        List<DocumentPageEntity>.from(pages);

    result.sort(
      (a, b) =>
          a.pageNumber.compareTo(b.pageNumber),
    );

    return result;
  }

  DocumentTemplateEntity copyWith({
    String? id,
    String? name,
    DocumentType? documentType,
    DocumentTemplateCategory? category,
    int? version,
    String? layoutKey,
    String? description,
    bool? isDefault,
    bool? isActive,
    bool? useSchoolLogo,
    bool? useSchoolName,
    bool? usePrincipalName,
    bool? usePrincipalDesignation,
    bool? usePrincipalSignature,
    bool? useSchoolStamp,
    List<DocumentPageEntity>? pages,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentTemplateEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      documentType:
          documentType ?? this.documentType,
      category: category ?? this.category,
      version: version ?? this.version,
      layoutKey: layoutKey ?? this.layoutKey,
      description:
          description ?? this.description,
      isDefault:
          isDefault ?? this.isDefault,
      isActive:
          isActive ?? this.isActive,
      useSchoolLogo:
          useSchoolLogo ?? this.useSchoolLogo,
      useSchoolName:
          useSchoolName ?? this.useSchoolName,
      usePrincipalName:
          usePrincipalName ??
          this.usePrincipalName,
      usePrincipalDesignation:
          usePrincipalDesignation ??
          this.usePrincipalDesignation,
      usePrincipalSignature:
          usePrincipalSignature ??
          this.usePrincipalSignature,
      useSchoolStamp:
          useSchoolStamp ??
          this.useSchoolStamp,
      pages: pages ?? this.pages,
      createdAt:
          createdAt ?? this.createdAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
      metadata:
          metadata ?? this.metadata,
    );
  }
}
