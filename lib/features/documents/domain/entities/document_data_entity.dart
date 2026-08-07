import 'document_type.dart';

class DocumentDataEntity {
  const DocumentDataEntity({
    required this.documentType,
    required this.values,
    this.referenceId,
    this.referenceType,
    this.generatedAt,
  });

  final DocumentType documentType;

  final Map<String, dynamic> values;

  final String? referenceId;
  final String? referenceType;

  final DateTime? generatedAt;

  T? value<T>(
    String key,
  ) {
    final data = values[key];

    if (data is T) {
      return data;
    }

    return null;
  }

  String stringValue(
    String key, {
    String fallback = '',
  }) {
    final value = values[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  DocumentDataEntity copyWith({
    DocumentType? documentType,
    Map<String, dynamic>? values,
    String? referenceId,
    String? referenceType,
    DateTime? generatedAt,
  }) {
    return DocumentDataEntity(
      documentType:
          documentType ?? this.documentType,
      values: values ?? this.values,
      referenceId:
          referenceId ?? this.referenceId,
      referenceType:
          referenceType ?? this.referenceType,
      generatedAt:
          generatedAt ?? this.generatedAt,
    );
  }
}
