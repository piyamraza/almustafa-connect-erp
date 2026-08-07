import 'package:flutter/material.dart';

import '../../../domain/entities/document_page_entity.dart';
import '../document_render_context.dart';
import '../flutter_document_renderer.dart';

class DocumentCanvas extends StatelessWidget {
  const DocumentCanvas({
    super.key,
    required this.page,
    required this.renderContext,
    required this.renderer,
    this.maxWidth,
    this.padding = const EdgeInsets.all(24),
    this.showShadow = true,
  });

  final DocumentPageEntity page;
  final DocumentRenderContext renderContext;
  final FlutterDocumentRenderer renderer;

  final double? maxWidth;
  final EdgeInsets padding;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final availableWidth =
            maxWidth == null
                ? constraints.maxWidth
                : constraints.maxWidth < maxWidth!
                    ? constraints.maxWidth
                    : maxWidth!;

        final horizontalPadding =
            padding.left + padding.right;

        final usableWidth =
            (availableWidth - horizontalPadding)
                .clamp(
                  0.0,
                  double.infinity,
                );

        final scale = page.width <= 0
            ? 1.0
            : usableWidth / page.width;

        final renderedPage =
            renderer.renderPage(
          page: page,
          renderContext: renderContext,
        );

        return Center(
          child: Padding(
            padding: padding,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: showShadow
                    ? const [
                        BoxShadow(
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: Offset(0, 6),
                          color: Color(
                            0x26000000,
                          ),
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                width: page.width * scale,
                height: page.height * scale,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment:
                      Alignment.topCenter,
                  child: renderedPage,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
