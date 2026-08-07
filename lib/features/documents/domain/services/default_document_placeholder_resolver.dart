import '../../domain/services/document_placeholder_resolver.dart';

class DefaultDocumentPlaceholderResolver
    implements DocumentPlaceholderResolver {
  const DefaultDocumentPlaceholderResolver();

  static final RegExp _placeholderPattern =
      RegExp(r'\{\{\s*([a-zA-Z0-9_.-]+)\s*\}\}');

  @override
  String resolveText({
    required String source,
    required Map<String, dynamic> values,
  }) {
    return source.replaceAllMapped(
      _placeholderPattern,
      (match) {
        final key = match.group(1);

        if (key == null || key.trim().isEmpty) {
          return '';
        }

        final value = resolveValue(
          key: key,
          values: values,
        );

        return value?.toString() ?? '';
      },
    );
  }

  @override
  dynamic resolveValue({
    required String key,
    required Map<String, dynamic> values,
  }) {
    if (values.containsKey(key)) {
      return values[key];
    }

    final parts = key.split('.');

    dynamic current = values;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(part)) {
          return null;
        }

        current = current[part];
        continue;
      }

      if (current is Map) {
        if (!current.containsKey(part)) {
          return null;
        }

        current = current[part];
        continue;
      }

      return null;
    }

    return current;
  }

  @override
  bool hasValue({
    required String key,
    required Map<String, dynamic> values,
  }) {
    final value = resolveValue(
      key: key,
      values: values,
    );

    if (value == null) {
      return false;
    }

    if (value is String) {
      return value.trim().isNotEmpty;
    }

    if (value is Iterable) {
      return value.isNotEmpty;
    }

    if (value is Map) {
      return value.isNotEmpty;
    }

    return true;
  }
}
