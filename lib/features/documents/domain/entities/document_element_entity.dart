import 'document_element_style.dart';
import 'document_element_type.dart';

class DocumentElementEntity {
  const DocumentElementEntity({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.zIndex = 0,
    this.rotation = 0,
    this.opacity = 1,
    this.isVisible = true,
    this.dataKey,
    this.staticValue,
    this.visibleWhenKey,
    this.visibleWhenValue,
    this.style = const DocumentElementStyle(),
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final DocumentElementType type;

  /// Normalized coordinate from 0.0 to 1.0.
  final double x;

  /// Normalized coordinate from 0.0 to 1.0.
  final double y;

  /// Normalized width from 0.0 to 1.0.
  final double width;

  /// Normalized height from 0.0 to 1.0.
  final double height;

  final int zIndex;

  /// Rotation in degrees.
  final double rotation;

  /// 0.0 = transparent, 1.0 = fully visible.
  final double opacity;

  final bool isVisible;

  /// Example: student.name
  final String? dataKey;

  /// Used for static text/image values.
  final String? staticValue;

  /// Optional simple conditional visibility.
  ///
  /// Example:
  /// visibleWhenKey = student.gender
  /// visibleWhenValue = female
  final String? visibleWhenKey;
  final String? visibleWhenValue;

  final DocumentElementStyle style;

  final Map<String, dynamic> metadata;

  bool get hasDynamicData =>
      dataKey != null &&
      dataKey!.trim().isNotEmpty;

  bool get hasStaticValue =>
      staticValue != null &&
      staticValue!.trim().isNotEmpty;

  DocumentElementEntity copyWith({
    String? id,
    DocumentElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    int? zIndex,
    double? rotation,
    double? opacity,
    bool? isVisible,
    String? dataKey,
    String? staticValue,
    String? visibleWhenKey,
    String? visibleWhenValue,
    DocumentElementStyle? style,
    Map<String, dynamic>? metadata,
  }) {
    return DocumentElementEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      zIndex: zIndex ?? this.zIndex,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      isVisible: isVisible ?? this.isVisible,
      dataKey: dataKey ?? this.dataKey,
      staticValue: staticValue ?? this.staticValue,
      visibleWhenKey:
          visibleWhenKey ?? this.visibleWhenKey,
      visibleWhenValue:
          visibleWhenValue ?? this.visibleWhenValue,
      style: style ?? this.style,
      metadata: metadata ?? this.metadata,
    );
  }
}
