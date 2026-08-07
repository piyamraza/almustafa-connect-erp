import 'document_element_entity.dart';

enum DocumentPageOrientation {
  portrait,
  landscape,
  square,
  custom,
}

class DocumentPageEntity {
  const DocumentPageEntity({
    required this.id,
    required this.width,
    required this.height,
    required this.elements,
    this.orientation =
        DocumentPageOrientation.portrait,
    this.backgroundColor = '#FFFFFF',
    this.backgroundImageUrl,
    this.pageNumber = 1,
  });

  final String id;

  /// Logical design width.
  ///
  /// Example:
  /// A4 can use 595 x 842 points.
  /// Social card can use 1080 x 1080.
  final double width;

  /// Logical design height.
  final double height;

  final DocumentPageOrientation orientation;

  final String backgroundColor;
  final String? backgroundImageUrl;

  final int pageNumber;

  final List<DocumentElementEntity> elements;

  List<DocumentElementEntity> get orderedElements {
    final result =
        List<DocumentElementEntity>.from(elements);

    result.sort(
      (a, b) => a.zIndex.compareTo(b.zIndex),
    );

    return result;
  }

  DocumentPageEntity copyWith({
    String? id,
    double? width,
    double? height,
    List<DocumentElementEntity>? elements,
    DocumentPageOrientation? orientation,
    String? backgroundColor,
    String? backgroundImageUrl,
    int? pageNumber,
  }) {
    return DocumentPageEntity(
      id: id ?? this.id,
      width: width ?? this.width,
      height: height ?? this.height,
      elements: elements ?? this.elements,
      orientation:
          orientation ?? this.orientation,
      backgroundColor:
          backgroundColor ?? this.backgroundColor,
      backgroundImageUrl:
          backgroundImageUrl ??
          this.backgroundImageUrl,
      pageNumber:
          pageNumber ?? this.pageNumber,
    );
  }
}
