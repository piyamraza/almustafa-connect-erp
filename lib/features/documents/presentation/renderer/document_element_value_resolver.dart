import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_element_type.dart';
import '../../domain/services/document_placeholder_resolver.dart';

class DocumentElementValueResolver {
  const DocumentElementValueResolver(
    this._placeholderResolver,
  );

  final DocumentPlaceholderResolver _placeholderResolver;

  dynamic resolve({
    required DocumentElementEntity element,
    required Map<String, dynamic> values,
  }) {
    final dynamicValue = _resolveDynamic(
      element,
      values,
    );

    if (dynamicValue != null) {
      return dynamicValue;
    }

    final staticValue =
        element.staticValue;

    if (staticValue == null) {
      return null;
    }

    if (_isTextLike(element.type)) {
      return _placeholderResolver.resolveText(
        source: staticValue,
        values: values,
      );
    }

    return staticValue;
  }

  dynamic _resolveDynamic(
    DocumentElementEntity element,
    Map<String, dynamic> values,
  ) {
    final key = element.dataKey?.trim();

    if (key == null || key.isEmpty) {
      return null;
    }

    return _placeholderResolver.resolveValue(
      key: key,
      values: values,
    );
  }

  bool _isTextLike(
    DocumentElementType type,
  ) {
    return switch (type) {
      DocumentElementType.text => true,
      DocumentElementType.qrCode => true,
      DocumentElementType.barcode => true,
      _ => false,
    };
  }
}
