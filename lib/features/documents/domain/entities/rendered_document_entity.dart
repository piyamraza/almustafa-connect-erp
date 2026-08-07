import 'document_type.dart';

class RenderedDocumentEntity {
  const RenderedDocumentEntity({
    required this.documentType,
    required this.templateId,
    required this.generatedAt,
    this.pngBytes,
    this.pdfBytes,
    this.fileName,
  });

  final DocumentType documentType;

  final String templateId;

  final DateTime generatedAt;

  final List<int>? pngBytes;
  final List<int>? pdfBytes;

  final String? fileName;

  bool get hasPng =>
      pngBytes != null &&
      pngBytes!.isNotEmpty;

  bool get hasPdf =>
      pdfBytes != null &&
      pdfBytes!.isNotEmpty;

  RenderedDocumentEntity copyWith({
    DocumentType? documentType,
    String? templateId,
    DateTime? generatedAt,
    List<int>? pngBytes,
    List<int>? pdfBytes,
    String? fileName,
  }) {
    return RenderedDocumentEntity(
      documentType:
          documentType ?? this.documentType,
      templateId:
          templateId ?? this.templateId,
      generatedAt:
          generatedAt ?? this.generatedAt,
      pngBytes:
          pngBytes ?? this.pngBytes,
      pdfBytes:
          pdfBytes ?? this.pdfBytes,
      fileName:
          fileName ?? this.fileName,
    );
  }
}
