import 'package:flutter/material.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../../../domain/entities/document_element_style.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class ShapeRenderer extends ElementRenderer {
  const ShapeRenderer();

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final style = element.style;

    final backgroundColor = _parseColor(
      style.backgroundColor,
      Colors.transparent,
    );

    final borderColor = _parseColor(
      style.borderColor,
      Colors.transparent,
    );

    final hasBorder =
        style.borderWidth > 0 &&
        style.borderColor != null &&
        style.borderColor!.trim().isNotEmpty;

    final isCircle =
        style.shape ==
        DocumentElementShape.circle;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: isCircle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(
                style.shape ==
                        DocumentElementShape
                            .roundedRectangle
                    ? style.borderRadius
                    : 0,
              ),
        border: hasBorder
            ? Border.all(
                color: borderColor,
                width: style.borderWidth,
              )
            : null,
      ),
      child: const SizedBox.expand(),
    );
  }

  Color _parseColor(
    String? value,
    Color fallback,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return fallback;
    }

    var hex = value
        .replaceAll('#', '')
        .trim();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    final parsed = int.tryParse(
      hex,
      radix: 16,
    );

    if (parsed == null) {
      return fallback;
    }

    return Color(parsed);
  }
}
