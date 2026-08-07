import 'package:flutter/material.dart';

import '../../domain/entities/document_element_entity.dart';
import '../../domain/entities/document_page_entity.dart';
import 'document_element_visibility_resolver.dart';
import 'document_render_context.dart';
import 'document_renderer_registry.dart';

class FlutterDocumentRenderer {
  const FlutterDocumentRenderer({
    required DocumentRendererRegistry registry,
    required DocumentElementVisibilityResolver
        visibilityResolver,
  }) : _registry = registry,
       _visibilityResolver = visibilityResolver;

  final DocumentRendererRegistry _registry;

  final DocumentElementVisibilityResolver
      _visibilityResolver;

  Widget renderPage({
    required DocumentPageEntity page,
    required DocumentRenderContext renderContext,
  }) {
    final visibleElements =
        page.orderedElements.where(
      (element) {
        return _visibilityResolver.isVisible(
          element: element,
          values: renderContext.values,
        );
      },
    ).toList();

    return SizedBox(
      width: page.width,
      height: page.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildPageBackground(page),
          ...visibleElements.map(
            (element) => _buildElement(
              page: page,
              element: element,
              renderContext: renderContext,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElement({
    required DocumentPageEntity page,
    required DocumentElementEntity element,
    required DocumentRenderContext renderContext,
  }) {
    final renderer =
        _registry.rendererForOrThrow(
      element.type,
    );

    final left = element.x * page.width;
    final top = element.y * page.height;
    final width = element.width * page.width;
    final height = element.height * page.height;

    Widget child = SizedBox(
      width: width,
      height: height,
      child: renderer.render(
        element: element,
        context: renderContext,
      ),
    );

    if (element.opacity < 1) {
      child = Opacity(
        opacity: element.opacity.clamp(0.0, 1.0),
        child: child,
      );
    }

    if (element.rotation != 0) {
      child = Transform.rotate(
        angle:
            element.rotation * 3.141592653589793 / 180,
        child: child,
      );
    }

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: child,
    );
  }

  Widget _buildPageBackground(
    DocumentPageEntity page,
  ) {
    final color =
        _parseColor(page.backgroundColor);

    if (page.backgroundImageUrl == null ||
        page.backgroundImageUrl!.trim().isEmpty) {
      return Positioned.fill(
        child: ColoredBox(
          color: color,
        ),
      );
    }

    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: color,
          ),
          Image.network(
            page.backgroundImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Color _parseColor(
    String value,
  ) {
    var hex = value
        .replaceAll('#', '')
        .trim();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return Colors.white;
    }

    final parsed = int.tryParse(
      hex,
      radix: 16,
    );

    if (parsed == null) {
      return Colors.white;
    }

    return Color(parsed);
  }
}
