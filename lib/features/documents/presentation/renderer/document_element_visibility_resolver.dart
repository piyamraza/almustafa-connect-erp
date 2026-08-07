import '../../domain/entities/document_element_entity.dart';
import '../../domain/services/document_placeholder_resolver.dart';

class DocumentElementVisibilityResolver {
  const DocumentElementVisibilityResolver(
    this._placeholderResolver,
  );

  final DocumentPlaceholderResolver _placeholderResolver;

  bool isVisible({
    required DocumentElementEntity element,
    required Map<String, dynamic> values,
  }) {
    if (!element.isVisible) {
      return false;
    }

    final key = element.visibleWhenKey?.trim();

    if (key == null || key.isEmpty) {
      return true;
    }

    final expected =
        element.visibleWhenValue?.trim();

    if (expected == null || expected.isEmpty) {
      return _placeholderResolver.hasValue(
        key: key,
        values: values,
      );
    }

    if (expected == 'exists') {
      return _placeholderResolver.hasValue(
        key: key,
        values: values,
      );
    }

    if (expected == 'missing') {
      return !_placeholderResolver.hasValue(
        key: key,
        values: values,
      );
    }

    final actual =
        _placeholderResolver.resolveValue(
      key: key,
      values: values,
    );

    if (actual == null) {
      return false;
    }

    return actual.toString() == expected;
  }
}
