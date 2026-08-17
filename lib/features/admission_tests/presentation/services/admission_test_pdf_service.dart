import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/admission_test_entities.dart';

class AdmissionTestPdfService {
  const AdmissionTestPdfService();
  Future<void> printPaper(AdmissionPaperEntity paper) async {
    final fonts = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
      PdfGoogleFonts.notoNaskhArabicRegular(),
    ]);
    final theme = pw.ThemeData.withFont(
      base: fonts[0],
      bold: fonts[1],
      fontFallback: [fonts[2]],
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (_) => _header(paper, 'ADMISSION TEST'),
        build: (_) => [
          pw.Row(
            children: [
              pw.Expanded(child: _line('Applicant Name')),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _line('Applicant No.')),
            ],
          ),
          pw.SizedBox(height: 14),
          ..._questionWidgets(paper, false),
        ],
      ),
    );
    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (_) => _header(paper, 'ANSWER KEY / MARKING GUIDE'),
        build: (_) => _questionWidgets(paper, true),
      ),
    );
    await Printing.layoutPdf(
      name:
          'admission_test_${paper.classLevel.replaceAll(' ', '_')}_${paper.variant}.pdf',
      onLayout: (_) => pdf.save(),
    );
  }

  pw.Widget _header(AdmissionPaperEntity paper, String heading) => pw.Column(
    children: [
      pw.Text(
        heading,
        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 5),
      pw.Text(
        '${paper.title}  •  ${paper.classLevel}  •  Variant ${paper.variant}',
      ),
      pw.Text(
        'Duration: ${paper.durationMinutes} minutes   |   Total Marks: ${paper.totalMarks.toStringAsFixed(0)}   |   Passing: ${paper.passingPercentage.toStringAsFixed(0)}%',
      ),
      pw.Divider(thickness: 1.2),
      pw.SizedBox(height: 8),
    ],
  );
  pw.Widget _line(String label) => pw.Row(
    children: [
      pw.Text('$label: '),
      pw.Expanded(
        child: pw.Container(
          height: 18,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide()),
          ),
        ),
      ),
    ],
  );
  List<pw.Widget> _questionWidgets(AdmissionPaperEntity paper, bool answers) {
    final widgets = <pw.Widget>[];
    String? subject;
    var number = 0;
    for (final q in paper.questions) {
      if (subject != q.subject) {
        subject = q.subject;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
            child: pw.Container(
              width: double.infinity,
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                subject,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        );
      }
      number++;
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$number. ${q.prompt}  [${q.marks.toStringAsFixed(q.marks % 1 == 0 ? 0 : 1)}]',
              ),
              if (q.options.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, top: 4),
                  child: pw.Text(
                    q.options
                        .asMap()
                        .entries
                        .map(
                          (e) =>
                              '${String.fromCharCode(65 + e.key)}. ${e.value}',
                        )
                        .join('     '),
                  ),
                ),
              if (answers)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 4),
                  child: pw.Text(
                    'Answer: ${q.correctAnswer.isEmpty ? 'Teacher observation' : q.correctAnswer}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                )
              else if (q.type == AdmissionQuestionType.shortAnswer)
                ...List.generate(
                  3,
                  (_) => pw.Container(
                    height: 18,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.grey400),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    widgets.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'Generated: ${DateFormat('dd MMM yyyy').format(paper.createdAt)}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
    );
    return widgets;
  }
}
