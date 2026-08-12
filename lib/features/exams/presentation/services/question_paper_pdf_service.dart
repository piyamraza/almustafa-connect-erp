import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/exam_question_entity.dart';

class QuestionPaperPdfService {
  late pw.Font _urduFont;
  late pw.Font _urduBoldFont;

  Future<Uint8List> build(ExamQuestionPaperEntity paper) async {
    final loaded = await Future.wait([
      _downloadImages(paper),
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
      PdfGoogleFonts.notoNaskhArabicRegular(),
      PdfGoogleFonts.notoNaskhArabicBold(),
      rootBundle.load('assets/images/logo.jpeg'),
    ]);
    final images = loaded[0] as Map<String, Uint8List>;
    final baseFont = loaded[1] as pw.Font;
    final boldFont = loaded[2] as pw.Font;
    _urduFont = loaded[3] as pw.Font;
    _urduBoldFont = loaded[4] as pw.Font;
    final bundledLogo = (loaded[5] as ByteData).buffer.asUint8List();
    final paperIsUrdu = paper.questions.isNotEmpty &&
        paper.questions.where((question) => _containsUrdu(question.text)).length >=
            (paper.questions.length / 2).ceil();
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
          fontFallback: [_urduFont],
        ),
        pageFormat: PdfPageFormat.a4,
        textDirection:
            paperIsUrdu ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 30),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (_) => [
          _header(
            paper,
            images[paper.logoUrl] ??
                (bundledLogo.isNotEmpty ? bundledLogo : null),
          ),
          pw.SizedBox(height: 10),
          ..._sections(paper.questions, images),
        ],
      ),
    );
    return document.save();
  }

  Future<Map<String, Uint8List>> _downloadImages(
    ExamQuestionPaperEntity paper,
  ) async {
    final urls = <String>{
      paper.logoUrl,
      ...paper.questions.map((q) => q.imageUrl),
    }..remove('');
    final values = <String, Uint8List>{};
    for (final url in urls) {
      Uint8List? bytes;
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          bytes = response.bodyBytes;
        }
      } catch (_) {
        // Authenticated Firebase Storage access is attempted below.
      }
      if (bytes == null) {
        try {
          bytes = await FirebaseStorage.instance
              .refFromURL(url)
              .getData(10 * 1024 * 1024);
        } catch (_) {
          // A missing remote image must not prevent the paper printing.
        }
      }
      if (bytes != null && bytes.isNotEmpty) {
        values[url] = bytes;
      }
    }
    return values;
  }

  pw.Widget _header(ExamQuestionPaperEntity paper, Uint8List? logo) {
    final isSubjective = paper.questions.any((q) => !q.isObjective);
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            if (logo != null) ...[
              pw.Container(
                width: 48,
                height: 48,
                child: pw.Image(pw.MemoryImage(logo), fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  paper.schoolName,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  paper.title,
                  textDirection: _containsUrdu(paper.title)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  style: _textStyle(paper.title, fontSize: 13, bold: true),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: .6),
          columnWidths: isSubjective
              ? const {
                  0: pw.FlexColumnWidth(),
                  1: pw.FlexColumnWidth(),
                  2: pw.FlexColumnWidth(),
                }
              : const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
          children: [
            pw.TableRow(
              children: [
                _metaBox('Exam Name', paper.title),
                _metaBox('Class', paper.className),
                if (isSubjective)
                  _metaBox('Passing Marks', _marks(paper.passingMarks)),
              ],
            ),
            pw.TableRow(
              children: [
                _metaBox('Subject', _paperSubjectName(paper)),
                _metaBox('Total Time', '${paper.durationMinutes} minutes'),
                if (isSubjective)
                  _metaBox('Total Marks', _marks(paper.totalMarks)),
              ],
            ),
            if (!isSubjective)
              pw.TableRow(
                children: [
                  _metaBox('Total Marks', _marks(paper.totalMarks)),
                  _metaBox('Student Name', ''),
                ],
              ),
          ],
        ),
        if (paper.instructions.trim().isNotEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey600, width: .6),
                left: pw.BorderSide(color: PdfColors.grey600, width: .6),
                right: pw.BorderSide(color: PdfColors.grey600, width: .6),
              ),
            ),
            child: pw.Text(
              'Instructions: ${paper.instructions}',
              textDirection: _containsUrdu(paper.instructions)
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              style: _textStyle(
                paper.instructions,
                fontSize: 9.5,
                bold: true,
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _metaBox(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
    child: pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            textDirection: _containsUrdu(value)
                ? pw.TextDirection.rtl
                : pw.TextDirection.ltr,
            textAlign: _containsUrdu(value)
                ? pw.TextAlign.right
                : pw.TextAlign.left,
            style: _textStyle(value, fontSize: 9),
          ),
        ),
      ],
    ),
  );

  List<pw.Widget> _sections(
    List<ExamQuestionEntity> questions,
    Map<String, Uint8List> images,
  ) {
    final widgets = <pw.Widget>[];
    var subjectiveNumber = 1;
    for (final type in ExamQuestionType.values) {
      final values = questions.where((q) => q.type == type).toList();
      if (values.isEmpty) continue;
      widgets.add(_heading(type.label));
      widgets.add(pw.SizedBox(height: 5));
      var number = type.isObjective ? 1 : subjectiveNumber;
      if (type == ExamQuestionType.matchColumns) {
        widgets.add(_matchColumns(values));
      } else {
        for (final question in values) {
          widgets.add(_question(question, number, images[question.imageUrl]));
          number++;
        }
      }
      if (!type.isObjective) {
        subjectiveNumber = number;
      }
      widgets.add(pw.SizedBox(height: 5));
    }
    return widgets;
  }

  pw.Widget _heading(String label) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    color: PdfColors.grey200,
    child: pw.Text(
      label,
      style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold),
    ),
  );

  pw.Widget _question(
    ExamQuestionEntity question,
    int number,
    Uint8List? image,
  ) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 9),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: pw.Text(
                '$number. ${question.text}',
                textDirection: _containsUrdu(question.text)
                    ? pw.TextDirection.rtl
                    : pw.TextDirection.ltr,
                textAlign: _containsUrdu(question.text)
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
                style: _textStyle(question.text, fontSize: 9.5),
              ),
            ),
            if (question.type == ExamQuestionType.trueFalse) ...[
              _choiceBox('Right'),
              pw.SizedBox(width: 7),
              _choiceBox('Wrong'),
              pw.SizedBox(width: 7),
            ] else
              pw.SizedBox(width: 6),
            pw.Text(
              '[${_marks(question.marks)}]',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
        if (question.type == ExamQuestionType.multipleChoice ||
            question.type == ExamQuestionType.oddOneOut)
          _optionTable(question.cells),
        if (question.type == ExamQuestionType.labelDiagram)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 7),
            child: image == null
                ? pw.Container(
                    width: double.infinity,
                    height: 180,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey500),
                    ),
                    child: pw.Text('Diagram unavailable'),
                  )
                : pw.Center(
                    child: pw.Container(
                      width: 480,
                      height: 300,
                      child: pw.Image(
                        pw.MemoryImage(image),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
          ),
        if (question.cells.isNotEmpty &&
            question.type != ExamQuestionType.multipleChoice &&
            question.type != ExamQuestionType.oddOneOut)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 16, top: 4),
            child: pw.Text(
              question.cells.join('     '),
              textDirection: question.cells.any(_containsUrdu)
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              textAlign: question.cells.any(_containsUrdu)
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
              style: _textStyle(question.cells.join(' '), fontSize: 9),
            ),
          ),
        if (question.answerLines > 0)
          ...List.generate(
            question.answerLines,
            (_) => pw.Container(
              margin: const pw.EdgeInsets.only(top: 10),
              height: .5,
              color: PdfColors.grey500,
            ),
          ),
      ],
    ),
  );

  pw.Widget _optionTable(List<String> options) {
    final values = List<String>.generate(
      4,
      (index) => index < options.length ? options[index] : '',
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16, top: 5),
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
        children: [
          pw.TableRow(
            children: values.asMap().entries.map((entry) {
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 5,
                ),
                child: pw.Text(
                  '${String.fromCharCode(65 + entry.key)}. ${entry.value}',
                  textDirection: _containsUrdu(entry.value)
                      ? pw.TextDirection.rtl
                      : pw.TextDirection.ltr,
                  textAlign: _containsUrdu(entry.value)
                      ? pw.TextAlign.right
                      : pw.TextAlign.left,
                  style: _textStyle(entry.value, fontSize: 8.5),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _choiceBox(String label) => pw.Container(
    width: 62,
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: .7),
    ),
    child: pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey700, width: .6),
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8.5)),
      ],
    ),
  );

  pw.Widget _matchColumns(List<ExamQuestionEntity> values) {
    final right = values
        .map((q) => q.cells.isEmpty ? '' : q.cells.first)
        .toList();
    if (right.length > 1) right.add(right.removeAt(0));
    return pw.Column(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 24),
          child: pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey500, width: .5),
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _tableCell('Column A', bold: true),
                  _tableCell('Column B', bold: true),
                ],
              ),
            ],
          ),
        ),
        ...List.generate(
          values.length,
          (index) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 24,
                  child: pw.Text(
                    '${index + 1}.',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  child: pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey500,
                      width: .5,
                    ),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(),
                      1: pw.FlexColumnWidth(),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          _tableCell(values[index].text),
                          _tableCell(right[index]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool bold = false}) => pw.Container(
    height: 32,
    alignment: _containsUrdu(text)
        ? pw.Alignment.centerRight
        : pw.Alignment.centerLeft,
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    child: pw.Text(
      text,
      textDirection:
          _containsUrdu(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      textAlign: _containsUrdu(text) ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        font: _containsUrdu(text)
            ? (bold ? _urduBoldFont : _urduFont)
            : null,
      ),
    ),
  );

  String _marks(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  bool _containsUrdu(String value) => RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
  ).hasMatch(value);

  pw.TextStyle _textStyle(
    String value, {
    required double fontSize,
    bool bold = false,
  }) =>
      pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        font: _containsUrdu(value)
            ? (bold ? _urduBoldFont : _urduFont)
            : null,
      );
  String _paperSubjectName(ExamQuestionPaperEntity paper) {
    if (paper.componentName.isEmpty) {
      return paper.subjectName;
    }
    if (paper.componentName.toLowerCase().startsWith(
      paper.subjectName.toLowerCase(),
    )) {
      return paper.componentName;
    }
    return '${paper.subjectName} ${paper.componentName}';
  }
}
