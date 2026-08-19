import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../domain/entities/document_element_entity.dart';
import '../../../domain/entities/document_element_style.dart';
import '../../../domain/entities/document_element_type.dart';
import '../document_element_value_resolver.dart';
import '../document_render_context.dart';
import 'element_renderer.dart';

class ImageRenderer extends ElementRenderer {
  const ImageRenderer(this._valueResolver);

  final DocumentElementValueResolver _valueResolver;
  static final Map<String, Future<Uint8List?>> _networkImageCache = {};

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

    final image = _buildImage(value, element);

    if (image == null) {
      return const SizedBox.shrink();
    }

    final style = element.style;

    final hasBorder =
        style.borderWidth > 0 &&
        style.borderColor != null &&
        style.borderColor!.trim().isNotEmpty;

    final isCircle = style.shape == DocumentElementShape.circle;

    final radius = style.shape == DocumentElementShape.roundedRectangle
        ? style.borderRadius
        : 0.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(radius),
        border: hasBorder
            ? Border.all(
                color: _parseColor(style.borderColor, Colors.transparent),
                width: style.borderWidth,
              )
            : null,
      ),
      child: image,
    );
  }

  Widget? _buildImage(dynamic value, DocumentElementEntity element) {
    final fit = _boxFit(element.style.imageFit);

    if (value is Map && value['studentId'] != null) {
      final studentId = value['studentId'].toString().trim();
      final storedUrl = value['storedUrl']?.toString().trim() ?? '';
      if (studentId.isEmpty) return null;
      return FutureBuilder<String?>(
        future: _studentPhotoUrl(studentId, storedUrl),
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url != null && url.isNotEmpty) {
            return Image.network(
              url,
              width: double.infinity,
              height: double.infinity,
              fit: fit,
              // Keep this identical to Student Information. Firebase images
              // can be displayed by the browser even when CanvasKit's XHR
              // request is rejected by the bucket CORS policy.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: _errorBuilder,
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox.shrink();
          }
          return _errorBuilder(
            context,
            snapshot.error ?? StateError('Student photo could not be loaded.'),
            null,
          );
        },
      );
    }

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

    final source = value.toString().trim();

    if (source.isEmpty) {
      return null;
    }

    final sourceType = element.metadata['sourceType']
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
      final assetPath = source.substring(6).trim();

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

    return FutureBuilder<Uint8List?>(
      future: _networkImageCache.putIfAbsent(
        source,
        () => _downloadImageBytes(source),
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null && bytes.isNotEmpty) {
          return Image.memory(
            bytes,
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            errorBuilder: _errorBuilder,
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (element.type == DocumentElementType.schoolLogo) {
          return Image.asset(
            'assets/images/logo.jpeg',
            width: double.infinity,
            height: double.infinity,
            fit: fit,
            errorBuilder: _errorBuilder,
          );
        }
        return _errorBuilder(
          context,
          snapshot.error ?? StateError('Image could not be loaded.'),
          null,
        );
      },
    );
  }

  Future<Uint8List?> _downloadImageBytes(String source) async {
    final directBytes = await _downloadHttpImage(source);
    if (directBytes != null) return directBytes;

    try {
      // Stored Firebase download URLs can expire or become stale after a photo
      // is replaced. Resolve the object reference and request a fresh URL
      // before falling back to the authenticated SDK download.
      final reference = FirebaseStorage.instance.refFromURL(source);
      final freshUrl = await reference.getDownloadURL();
      final refreshedBytes = await _downloadHttpImage(freshUrl);
      if (refreshedBytes != null) return refreshedBytes;

      return await reference.getData(10 * 1024 * 1024);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _studentPhotoUrl(String studentId, String storedUrl) async {
    final canonicalReference = FirebaseStorage.instance.ref(
      'students/$studentId/profile.jpg',
    );
    if (storedUrl.startsWith('http://') || storedUrl.startsWith('https://')) {
      final separator = storedUrl.contains('?') ? '&' : '?';
      return '$storedUrl${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    }
    try {
      final reference = storedUrl.isNotEmpty
          ? FirebaseStorage.instance.refFromURL(storedUrl)
          : canonicalReference;
      final url = await reference.getDownloadURL();
      final separator = url.contains('?') ? '&' : '?';
      return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      try {
        final url = await canonicalReference.getDownloadURL();
        final separator = url.contains('?') ? '&' : '?';
        return '$url${separator}v=${DateTime.now().millisecondsSinceEpoch}';
      } catch (_) {
        return null;
      }
    }
  }

  Future<Uint8List?> _downloadHttpImage(String source) async {
    try {
      final response = await http.get(Uri.parse(source));
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          response.bodyBytes.isNotEmpty &&
          (contentType.isEmpty || contentType.startsWith('image/'))) {
        return response.bodyBytes;
      }
    } catch (_) {
      // The caller can attempt a Firebase Storage authenticated fallback.
    }
    return null;
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Color(0xFF98A2B3)),
    );
  }

  BoxFit _boxFit(DocumentImageFit fit) {
    return switch (fit) {
      DocumentImageFit.contain => BoxFit.contain,
      DocumentImageFit.cover => BoxFit.cover,
      DocumentImageFit.fill => BoxFit.fill,
    };
  }

  Color _parseColor(String? value, Color fallback) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    var hex = value.replaceAll('#', '').trim();

    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    if (hex.length != 8) {
      return fallback;
    }

    final parsed = int.tryParse(hex, radix: 16);

    if (parsed == null) {
      return fallback;
    }

    return Color(parsed);
  }
}
