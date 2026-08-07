import 'package:flutter/widgets.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../document_render_context.dart';

abstract class ElementRenderer {
  const ElementRenderer();

  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  });
}
