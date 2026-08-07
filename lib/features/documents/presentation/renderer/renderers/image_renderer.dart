import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/entities/document_element_entity.dart';
import '../../../domain/entities/document_element_style.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class ImageRenderer extends ElementRenderer {
  const ImageRenderer(
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

    if (value == null) {
      return const SizedBox.shrink();
    }

    final image = _buildImage(
      value,
      element,
    );

    if (image == null) {
      return const SizedBox.shrink();
    }

    final style = element.style;

    final hasBorder =
        style.borderWidth > 0 &&
        style.borderColor != null &&
        style.borderColor!.trim().isNotEmpty;

    final isCircle =
        style.shape ==
        DocumentElementShape.circle;

    final radius = style.shape ==
            DocumentElementShape
                .roundedRectangle
        ? style.borderRadius
        : 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: isCircle
            ? BoxShape.circle
            : BoxShape.rectangle,
        borderRadius: isCircle
            ? null
            : BorderRadius.circular(
                radius,
              ),
        border: hasBorder
            ? Border.all(
                color: _parseColor(
                  style.borderColor,
                  Colors.transparent,
                ),
                width: style.borderWidth,
              )
            : null,
      ),
      child: image,
    );
  }

  Widget? _buildImage(
    dynamic value,
    DocumentElementEntity element,
  ) {
    final fit = _boxFit(
      element.style.imageFit,
    );

    if (value is Uint8List) {
      return Image.memory(
        value,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    if (value is List<int>) {
      return Image.memory(
        Uint8List.fromList(value),
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    final source =
        value.toString().trim();

    if (source.isEmpty) {
      return null;
    }

    final sourceType =
        element.metadata['sourceType']
            ?.toString()
            .trim()
            .toLowerCase();

    if (sourceType == 'asset') {
      return Image.asset(
        source,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    if (source.startsWith('asset:')) {
      final assetPath =
          source.substring(6).trim();

      if (assetPath.isEmpty) {
        return null;
      }

      return Image.asset(
        assetPath,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: _errorBuilder,
      );
    }

    return Image.network(
      source,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      errorBuilder: _errorBuilder,
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: Color(0xFF98A2B3),
      ),
    );
  }

  BoxFit _boxFit(
    DocumentImageFit fit,
  ) {
    return switch (fit) {
      DocumentImageFit.contain =>
        BoxFit.contain,
      DocumentImageFit.cover =>
        BoxFit.cover,
      DocumentImageFit.fill =>
        BoxFit.fill,
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
