import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_type.dart';
import 'document_element_style_model.dart';

class DocumentElementModel {
  const DocumentElementModel();

  static Map<String, dynamic> toMap(
    DocumentElementEntity element,
  ) {
    return {
      'id': element.id,
      'type': element.type.name,
      'x': element.x,
      'y': element.y,
      'width': element.width,
      'height': element.height,
      'zIndex': element.zIndex,
      'rotation': element.rotation,
      'opacity': element.opacity,
      'isVisible': element.isVisible,
      'dataKey': element.dataKey,
      'staticValue': element.staticValue,
      'visibleWhenKey':
          element.visibleWhenKey,
      'visibleWhenValue':
          element.visibleWhenValue,
      'style':
          DocumentElementStyleModel.toMap(
        element.style,
      ),
      'metadata': element.metadata,
    };
  }

  static DocumentElementEntity fromMap(
    Map<String, dynamic> map,
  ) {
    return DocumentElementEntity(
      id: map['id'] as String? ?? '',
      type: _elementType(
        map['type'],
      ),
      x: _double(
        map['x'],
      ),
      y: _double(
        map['y'],
      ),
      width: _double(
        map['width'],
        fallback: 0.1,
      ),
      height: _double(
        map['height'],
        fallback: 0.1,
      ),
      zIndex: _int(
        map['zIndex'],
      ),
      rotation: _double(
        map['rotation'],
      ),
      opacity: _double(
        map['opacity'],
        fallback: 1,
      ),
      isVisible:
          map['isVisible'] as bool? ?? true,
      dataKey:
          map['dataKey'] as String?,
      staticValue:
          map['staticValue'] as String?,
      visibleWhenKey:
          map['visibleWhenKey'] as String?,
      visibleWhenValue:
          map['visibleWhenValue'] as String?,
      style:
          DocumentElementStyleModel.fromMap(
        _map(
          map['style'],
        ),
      ),
      metadata: _map(
        map['metadata'],
      ),
    );
  }

  static DocumentElementType _elementType(
    dynamic raw,
  ) {
    final name = raw?.toString();

    for (final value
        in DocumentElementType.values) {
      if (value.name == name) {
        return value;
      }
    }

    return DocumentElementType.text;
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
