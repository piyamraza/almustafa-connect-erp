import 'package:flutter/material.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../../../domain/entities/document_element_style.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class TextRenderer extends ElementRenderer {
  const TextRenderer(
    this._valueResolver,
  );

  final DocumentElementValueResolver _valueResolver;

  @override
  Widget render({
    required DocumentElementEntity element,
    required DocumentRenderContext context,
  }) {
    final value = _valueResolver.resolve(
      element: element,
      values: context.values,
    );

    final text = value?.toString() ?? '';
    final style = element.style;

    return Align(
      alignment: _alignment(style),
      child: Text(
        text,
        textAlign: _textAlign(
          style.textAlignment,
        ),
        maxLines: style.maxLines,
        overflow: style.maxLines == null
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: _fontWeight(
            style.fontWeight,
          ),
          fontStyle: style.italic
              ? FontStyle.italic
              : FontStyle.normal,
          color: _parseColor(
            style.textColor,
            Colors.black,
          ),
          height: style.lineHeight,
          letterSpacing: style.letterSpacing,
        ),
      ),
    );
  }

  Alignment _alignment(
    DocumentElementStyle style,
  ) {
    final horizontal = switch (
        style.textAlignment) {
      DocumentTextAlignment.left => -1.0,
      DocumentTextAlignment.center => 0.0,
      DocumentTextAlignment.right => 1.0,
      DocumentTextAlignment.justify => 0.0,
    };

    final vertical = switch (
        style.verticalAlignment) {
      DocumentVerticalAlignment.top => -1.0,
      DocumentVerticalAlignment.center => 0.0,
      DocumentVerticalAlignment.bottom => 1.0,
    };

    return Alignment(
      horizontal,
      vertical,
    );
  }

  TextAlign _textAlign(
    DocumentTextAlignment alignment,
  ) {
    return switch (alignment) {
      DocumentTextAlignment.left =>
        TextAlign.left,
      DocumentTextAlignment.center =>
        TextAlign.center,
      DocumentTextAlignment.right =>
        TextAlign.right,
      DocumentTextAlignment.justify =>
        TextAlign.justify,
    };
  }

  FontWeight _fontWeight(
    DocumentFontWeight weight,
  ) {
    return switch (weight) {
      DocumentFontWeight.normal =>
        FontWeight.w400,
      DocumentFontWeight.medium =>
        FontWeight.w500,
      DocumentFontWeight.semiBold =>
        FontWeight.w600,
      DocumentFontWeight.bold =>
        FontWeight.w700,
    };
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
