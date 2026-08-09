import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../../settings/domain/usecases/manage_settings.dart';
import '../../domain/entities/homework_entity.dart';

class HomeworkDiaryPdfService {
  const HomeworkDiaryPdfService();

  Future<void> generateAndShare({
    required String className,
    required String sectionName,
    required DateTime date,
    required List<HomeworkDiarySubject> subjects,
  }) async {
    final settings = await sl<GetSchoolSettings>()();
    final logo = await _loadLogo(settings);
    final bytes = await _buildPdf(
      settings: settings,
      logo: logo,
      className: className,
      sectionName: sectionName,
      date: date,
      subjects: subjects,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          'daily_diary_${_safe(className)}_${_safe(sectionName)}_${_fileDate(date)}.pdf',
    );
  }

  Future<Uint8List> _buildPdf({
    required SchoolSettingsEntity settings,
    required pw.ImageProvider? logo,
    required String className,
    required String sectionName,
    required DateTime date,
    required List<HomeworkDiarySubject> subjects,
  }) async {
    const navy = PdfColor.fromInt(0xFF173B67);
    const blue = PdfColor.fromInt(0xFF2563EB);
    const paleBlue = PdfColor.fromInt(0xFFEFF6FF);
    const paleGold = PdfColor.fromInt(0xFFFFF7E8);
    const border = PdfColor.fromInt(0xFFD8E2F0);
    const muted = PdfColor.fromInt(0xFF64748B);
    final document = pw.Document(
      title: 'Daily Homework Diary - Class $className',
      author: settings.schoolName,
      subject: 'Daily homework diary for ${_displayDate(date)}',
    );

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
                    width: 62,
                    height: 62,
                    padding: const pw.EdgeInsets.all(5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: logo == null
                        ? pw.Center(
                            child: pw.Text(
                              'SCHOOL',
                              style: pw.TextStyle(
                                color: navy,
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          )
                        : pw.ClipOval(
                            child: pw.Image(logo, fit: pw.BoxFit.contain),
                          ),
                  ),
                  pw.SizedBox(width: 15),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.schoolName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (settings.tagLine.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            settings.tagLine.trim(),
                            style: pw.TextStyle(
                              color: PdfColor.fromInt(0xFFDCEBFF),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              'DAILY HOMEWORK DIARY',
              style: pw.TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _infoBox(
                    label: 'CLASS',
                    value: 'Class $className - Section $sectionName',
                    color: paleBlue,
                    textColor: blue,
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _infoBox(
                    label: 'DATE',
                    value: _displayDate(date),
                    color: paleGold,
                    textColor: navy,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (_) => [
          for (var index = 0; index < subjects.length; index++)
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(13),
              decoration: pw.BoxDecoration(
                color: index.isEven ? PdfColors.white : paleBlue,
                border: pw.Border.all(color: border),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: pw.BoxDecoration(
                      color: subjects[index].homework == null
                          ? paleGold
                          : const PdfColor.fromInt(0xFFE7F8ED),
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        '${index + 1}',
                        style: pw.TextStyle(
                          color: subjects[index].homework == null
                              ? const PdfColor.fromInt(0xFFB45309)
                              : const PdfColor.fromInt(0xFF15803D),
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          subjects[index].subjectName,
                          style: pw.TextStyle(
                            color: navy,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        if (subjects[index].homework == null)
                          pw.Text(
                            'No homework assigned.',
                            style: pw.TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          )
                        else
                          _homeworkText(subjects[index].homework!),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: border)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Keep learning, keep growing!',
                style: const pw.TextStyle(color: muted, fontSize: 8),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(color: muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }

  pw.Widget _infoBox({
    required String label,
    required String value,
    required PdfColor color,
    required PdfColor textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(9),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: const PdfColor.fromInt(0xFF64748B),
              fontSize: 7,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _homeworkText(HomeworkEntity homework) {
    final lines = <String>[
      homework.title.trim(),
      if (homework.description.trim().isNotEmpty) homework.description.trim(),
      if (homework.instructions.trim().isNotEmpty) homework.instructions.trim(),
    ];
    return pw.Text(
      lines.join('\n'),
      style: const pw.TextStyle(
        color: PdfColor.fromInt(0xFF334155),
        fontSize: 10.5,
        lineSpacing: 3,
      ),
    );
  }

  Future<pw.ImageProvider?> _loadLogo(SchoolSettingsEntity settings) async {
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

  static String _displayDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  static String _fileDate(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _safe(String value) => value
      .trim()
      .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
}

class HomeworkDiarySubject {
  const HomeworkDiarySubject({required this.subjectName, this.homework});

  final String subjectName;
  final HomeworkEntity? homework;
}
