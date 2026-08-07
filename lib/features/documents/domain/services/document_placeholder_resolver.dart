abstract class DocumentPlaceholderResolver {
  String resolveText({
    required String source,
    required Map<String, dynamic> values,
  });

  dynamic resolveValue({
    required String key,
    required Map<String, dynamic> values,
  });

  bool hasValue({
    required String key,
    required Map<String, dynamic> values,
  });
}
