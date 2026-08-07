enum DocumentTextAlignment {
  left,
  center,
  right,
  justify,
}

enum DocumentVerticalAlignment {
  top,
  center,
  bottom,
}

enum DocumentFontWeight {
  normal,
  medium,
  semiBold,
  bold,
}

enum DocumentImageFit {
  contain,
  cover,
  fill,
}

enum DocumentElementShape {
  rectangle,
  roundedRectangle,
  circle,
}

class DocumentElementStyle {
  const DocumentElementStyle({
    this.fontFamily,
    this.fontSize = 16,
    this.fontWeight = DocumentFontWeight.normal,
    this.italic = false,
    this.textColor = '#000000',
    this.textAlignment = DocumentTextAlignment.left,
    this.verticalAlignment =
        DocumentVerticalAlignment.center,
    this.lineHeight = 1.2,
    this.letterSpacing = 0,
    this.maxLines,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = 0,
    this.imageFit = DocumentImageFit.contain,
    this.shape = DocumentElementShape.rectangle,
  });

  final String? fontFamily;
  final double fontSize;
  final DocumentFontWeight fontWeight;
  final bool italic;

  final String textColor;
  final DocumentTextAlignment textAlignment;
  final DocumentVerticalAlignment verticalAlignment;

  final double lineHeight;
  final double letterSpacing;
  final int? maxLines;

  final String? backgroundColor;

  final String? borderColor;
  final double borderWidth;
  final double borderRadius;

  final DocumentImageFit imageFit;
  final DocumentElementShape shape;

  DocumentElementStyle copyWith({
    String? fontFamily,
    double? fontSize,
    DocumentFontWeight? fontWeight,
    bool? italic,
    String? textColor,
    DocumentTextAlignment? textAlignment,
    DocumentVerticalAlignment? verticalAlignment,
    double? lineHeight,
    double? letterSpacing,
    int? maxLines,
    String? backgroundColor,
    String? borderColor,
    double? borderWidth,
    double? borderRadius,
    DocumentImageFit? imageFit,
    DocumentElementShape? shape,
  }) {
    return DocumentElementStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      fontWeight: fontWeight ?? this.fontWeight,
      italic: italic ?? this.italic,
      textColor: textColor ?? this.textColor,
      textAlignment:
          textAlignment ?? this.textAlignment,
      verticalAlignment:
          verticalAlignment ?? this.verticalAlignment,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing:
          letterSpacing ?? this.letterSpacing,
      maxLines: maxLines ?? this.maxLines,
      backgroundColor:
          backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius:
          borderRadius ?? this.borderRadius,
      imageFit: imageFit ?? this.imageFit,
      shape: shape ?? this.shape,
    );
  }
}
