import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';

class SyllabusPdfService {
  const SyllabusPdfService();

  Future<void> generateAndShare({
    required String title,
    required String session,
    required String className,
    required String sectionName,
    required List<SyllabusPdfSubject> subjects,
  }) async {
    final settings = await sl<GetSchoolSettings>()();
    final logo = await _logo(settings);
    const navy = PdfColor.fromInt(0xFF173B67);
    const purple = PdfColor.fromInt(0xFF6D28D9);
    const pale = PdfColor.fromInt(0xFFF5F3FF);
    const border = PdfColor.fromInt(0xFFDDD6FE);
    const muted = PdfColor.fromInt(0xFF64748B);
    final document = pw.Document(title: title, author: settings.schoolName);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 30),
        header: (_) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: navy,
                borderRadius: pw.BorderRadius.circular(16),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 60,
                    height: 60,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: logo == null
                        ? pw.Center(child: pw.Text('SCHOOL'))
                        : pw.ClipOval(
                            child: pw.Image(logo, fit: pw.BoxFit.contain),
                          ),
                  ),
                  pw.SizedBox(width: 14),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.schoolName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 21,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (settings.tagLine.trim().isNotEmpty)
                          pw.Text(
                            settings.tagLine.trim(),
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFFEDE9FE),
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Text(
              title.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: purple,
                fontSize: 19,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 9),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: pale,
                borderRadius: pw.BorderRadius.circular(9),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Text(
                    'Class $className - Section $sectionName',
                    style: pw.TextStyle(
                      color: navy,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Session: $session',
                    style: pw.TextStyle(
                      color: navy,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
          ],
        ),
        build: (_) => [
          for (var i = 0; i < subjects.length; i++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: i.isEven ? PdfColors.white : pale,
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    subjects[i].name,
                    style: pw.TextStyle(
                      color: purple,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    subjects[i].content.trim().isEmpty
                        ? 'Syllabus not added.'
                        : subjects[i].content.trim(),
                    style: pw.TextStyle(
                      color: subjects[i].content.trim().isEmpty
                          ? muted
                          : const PdfColor.fromInt(0xFF334155),
                      fontSize: 10.5,
                      fontStyle: subjects[i].content.trim().isEmpty
                          ? pw.FontStyle.italic
                          : pw.FontStyle.normal,
                      lineSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
        ],
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Prepared by ${settings.schoolName}',
              style: pw.TextStyle(color: muted, fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(color: muted, fontSize: 8),
            ),
          ],
        ),
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: '${_safe(title)}_Class_${_safe(className)}.pdf',
    );
  }

  Future<pw.ImageProvider?> _logo(SchoolSettingsEntity settings) async {
    if (settings.logoUrl.trim().isNotEmpty) {
      try {
        return await networkImage(settings.logoUrl.trim());
      } catch (_) {}
    }
    try {
      final data = await rootBundle.load('assets/images/logo.jpeg');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _safe(String value) => value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
}

class SyllabusPdfSubject {
  const SyllabusPdfSubject({required this.name, required this.content});

  final String name;
  final String content;
}
