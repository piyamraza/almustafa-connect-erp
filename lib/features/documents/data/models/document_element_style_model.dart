import '../../domain/entities/document_element_style.dart';

class DocumentElementStyleModel {
  const DocumentElementStyleModel();

  static Map<String, dynamic> toMap(
    DocumentElementStyle style,
  ) {
    return {
      'fontFamily': style.fontFamily,
      'fontSize': style.fontSize,
      'fontWeight': style.fontWeight.name,
      'italic': style.italic,
      'textColor': style.textColor,
      'textAlignment': style.textAlignment.name,
      'verticalAlignment':
          style.verticalAlignment.name,
      'lineHeight': style.lineHeight,
      'letterSpacing': style.letterSpacing,
      'maxLines': style.maxLines,
      'backgroundColor': style.backgroundColor,
      'borderColor': style.borderColor,
      'borderWidth': style.borderWidth,
      'borderRadius': style.borderRadius,
      'imageFit': style.imageFit.name,
      'shape': style.shape.name,
    };
  }

  static DocumentElementStyle fromMap(
    Map<String, dynamic> map,
  ) {
    return DocumentElementStyle(
      fontFamily: map['fontFamily'] as String?,
      fontSize: _double(
        map['fontSize'],
        fallback: 16,
      ),
      fontWeight: _enumValue(
        DocumentFontWeight.values,
        map['fontWeight'],
        DocumentFontWeight.normal,
      ),
      italic: map['italic'] as bool? ?? false,
      textColor:
          map['textColor'] as String? ?? '#000000',
      textAlignment: _enumValue(
        DocumentTextAlignment.values,
        map['textAlignment'],
        DocumentTextAlignment.left,
      ),
      verticalAlignment: _enumValue(
        DocumentVerticalAlignment.values,
        map['verticalAlignment'],
        DocumentVerticalAlignment.center,
      ),
      lineHeight: _double(
        map['lineHeight'],
        fallback: 1.2,
      ),
      letterSpacing: _double(
        map['letterSpacing'],
      ),
      maxLines: _intOrNull(
        map['maxLines'],
      ),
      backgroundColor:
          map['backgroundColor'] as String?,
      borderColor:
          map['borderColor'] as String?,
      borderWidth: _double(
        map['borderWidth'],
      ),
      borderRadius: _double(
        map['borderRadius'],
      ),
      imageFit: _enumValue(
        DocumentImageFit.values,
        map['imageFit'],
        DocumentImageFit.contain,
      ),
      shape: _enumValue(
        DocumentElementShape.values,
        map['shape'],
        DocumentElementShape.rectangle,
      ),
    );
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    dynamic raw,
    T fallback,
  ) {
    final name = raw?.toString();

    if (name == null || name.isEmpty) {
      return fallback;
    }

    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }

    return fallback;
  }

  static double _double(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        fallback;
  }

  static int? _intOrNull(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }
}
