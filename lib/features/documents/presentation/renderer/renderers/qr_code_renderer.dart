import 'package:flutter/widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class QrCodeRenderer extends ElementRenderer {
  const QrCodeRenderer(this._valueResolver);

  final DocumentElementValueResolver _valueResolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final value = _valueResolver
        .resolve(element: element, values: context.values)
        ?.toString()
        .trim();
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(2),
      child: QrImageView(data: value, padding: EdgeInsets.zero),
    );
  }
}
