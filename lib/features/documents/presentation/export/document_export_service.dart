import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class DocumentExportService {
  const DocumentExportService();

  Future<Uint8List> capturePng({
    required GlobalKey boundaryKey,
    double pixelRatio = 3,
  }) async {
    final context = boundaryKey.currentContext;

    if (context == null) {
      throw StateError(
        'Document preview is not available for export.',
      );
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'Document preview must be wrapped in a RepaintBoundary.',
      );
    }

    await WidgetsBinding.instance.endOfFrame;

    if (!renderObject.attached) {
      throw StateError(
        'Document preview is no longer attached.',
      );
    }

    final image = await renderObject.toImage(
      pixelRatio: pixelRatio,
    );

    try {
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw StateError(
          'Unable to generate PNG data.',
        );
      }

      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<Uint8List> createPdfFromPng({
    required Uint8List pngBytes,
    required double aspectRatio,
    String title = 'School Document',
  }) async {
    if (aspectRatio <= 0) {
      throw ArgumentError.value(
        aspectRatio,
        'aspectRatio',
        'Aspect ratio must be greater than zero.',
      );
    }

    final document = pw.Document(
      title: title,
      author: 'Almustafa Connect ERP',
      creator:
          'Almustafa Connect ERP Document Engine',
      compress: true,
    );

    final image = pw.MemoryImage(
      pngBytes,
    );

    const pageWidth = 595.28;

    final pageHeight =
        pageWidth / aspectRatio;

    final pageFormat = PdfPageFormat(
      pageWidth,
      pageHeight,
      marginAll: 0,
    );

    document.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.SizedBox(
            width: pageFormat.width,
            height: pageFormat.height,
            child: pw.Image(
              image,
              fit: pw.BoxFit.fill,
            ),
          );
        },
      ),
    );

    return document.save();
  }

  Future<String?> savePng({
    required Uint8List bytes,
    required String fileName,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save document as PNG',
      fileName: _ensureExtension(
        fileName,
        '.png',
      ),
      type: FileType.custom,
      allowedExtensions: const [
        'png',
      ],
      bytes: bytes,
    );
  }

  Future<String?> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save document as PDF',
      fileName: _ensureExtension(
        fileName,
        '.pdf',
      ),
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
      ],
      bytes: bytes,
    );
  }

  Future<void> printPdf({
    required Uint8List bytes,
    String name = 'School Document',
  }) {
    return Printing.layoutPdf(
      name: name,
      onLayout: (_) async => bytes,
    );
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) {
    return Printing.sharePdf(
      bytes: bytes,
      filename: _ensureExtension(
        fileName,
        '.pdf',
      ),
    );
  }

  Future<ShareResult> sharePng({
    required Uint8List bytes,
    required String fileName,
    String? text,
  }) {
    final name = _ensureExtension(
      fileName,
      '.png',
    );

    return Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'image/png',
        ),
      ],
      text: text,
      fileNameOverrides: [
        name,
      ],
    );
  }

  String safeFileName(
    String value, {
    String fallback = 'document',
  }) {
    final cleaned = value
        .trim()
        .replaceAll(
          RegExp(r'[<>:"/\\|?*]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '_',
        );

    if (cleaned.isEmpty) {
      return fallback;
    }

    return cleaned;
  }

  String _ensureExtension(
    String fileName,
    String extension,
  ) {
    if (fileName.toLowerCase().endsWith(
          extension.toLowerCase(),
        )) {
      return fileName;
    }

    return '$fileName$extension';
  }
}