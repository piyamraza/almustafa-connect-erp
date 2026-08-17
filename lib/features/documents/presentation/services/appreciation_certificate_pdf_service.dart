import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../settings/domain/entities/school_settings_entity.dart';
import '../../domain/entities/appreciation_certificate_entity.dart';

class AppreciationCertificatePdfService {
  const AppreciationCertificatePdfService();
  Future<Uint8List> build(
    AppreciationCertificateEntity value,
    SchoolSettingsEntity settings,
  ) async {
    final loaded = await Future.wait([
      PdfGoogleFonts.notoSansRegular(),
      PdfGoogleFonts.notoSansBold(),
      PdfGoogleFonts.notoNaskhArabicRegular(),
      _image(settings.logoUrl, '', fallbackAsset: 'assets/images/logo.jpeg'),
      _image(settings.principalSignatureUrl, settings.principalSignatureData),
      _image(settings.schoolStampUrl, settings.schoolStampData),
    ]);
    final base = loaded[0] as pw.Font,
        bold = loaded[1] as pw.Font,
        urdu = loaded[2] as pw.Font;
    final logo = loaded[3] as Uint8List?,
        signature = loaded[4] as Uint8List?,
        stamp = loaded[5] as Uint8List?;
    final colors = _colors(value.theme);
    final pdf = pw.Document(title: value.title);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        theme: pw.ThemeData.withFont(
          base: base,
          bold: bold,
          fontFallback: [urdu],
        ),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: colors.$2, width: 9),
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: colors.$1, width: 2),
            ),
            padding: const pw.EdgeInsets.fromLTRB(38, 22, 38, 18),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logo != null)
                      pw.Container(
                        width: 55,
                        height: 55,
                        margin: const pw.EdgeInsets.only(right: 14),
                        child: pw.Image(
                          pw.MemoryImage(logo),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    pw.Column(
                      children: [
                        pw.Text(
                          settings.schoolName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 25,
                            fontWeight: pw.FontWeight.bold,
                            color: colors.$1,
                          ),
                        ),
                        if (settings.tagLine.trim().isNotEmpty)
                          pw.Text(
                            settings.tagLine,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),
                pw.Text(
                  value.title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 31,
                    fontWeight: pw.FontWeight.bold,
                    color: colors.$1,
                    letterSpacing: 2,
                  ),
                ),
                pw.Container(
                  width: 180,
                  height: 2,
                  color: colors.$2,
                  margin: const pw.EdgeInsets.symmetric(vertical: 10),
                ),
                pw.Text(
                  'THIS CERTIFICATE IS PROUDLY PRESENTED TO',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.4,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  value.studentName,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: colors.$1,
                  ),
                ),
                pw.Text(
                  '${value.classSection}${value.rollNumber.isEmpty ? '' : '  •  Roll No. ${value.rollNumber}'}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 28),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 55),
                  child: pw.Text(
                    value.description,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 13, height: 1.55),
                  ),
                ),
                pw.SizedBox(height: 13),
                pw.Text(
                  value.categoryLabel,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: colors.$2,
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _signatureBlock(
                      'Achievement Date',
                      DateFormat('dd MMM yyyy').format(value.achievementDate),
                      null,
                      colors.$1,
                    ),
                    _signatureBlock(
                      value.teacherName.isEmpty
                          ? 'Class Teacher'
                          : value.teacherName,
                      'Teacher',
                      null,
                      colors.$1,
                    ),
                    _signatureBlock(
                      value.principalName.isEmpty
                          ? settings.principalName
                          : value.principalName,
                      settings.principalDesignation,
                      signature,
                      colors.$1,
                    ),
                    if (stamp != null)
                      pw.SizedBox(
                        width: 60,
                        height: 60,
                        child: pw.Image(
                          pw.MemoryImage(stamp),
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Certificate No: ${value.serialNumber}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Issued: ${DateFormat('dd MMM yyyy').format(value.issueDate)}',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> printCertificate(
    AppreciationCertificateEntity value,
    SchoolSettingsEntity settings,
  ) async {
    final bytes = await build(value, settings);
    await Printing.layoutPdf(
      name: '${value.serialNumber}_${value.studentName}.pdf',
      onLayout: (_) => bytes,
    );
  }

  pw.Widget _signatureBlock(
    String name,
    String label,
    Uint8List? image,
    PdfColor color,
  ) => pw.SizedBox(
    width: 130,
    child: pw.Column(
      children: [
        if (image != null)
          pw.SizedBox(
            height: 30,
            child: pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(height: 30),
        pw.Container(height: 1, color: color),
        pw.SizedBox(height: 3),
        pw.Text(
          name,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ],
    ),
  );
  (PdfColor, PdfColor) _colors(AppreciationTheme theme) => switch (theme) {
    AppreciationTheme.blueGold => (
      PdfColor.fromHex('#123B72'),
      PdfColor.fromHex('#C99A2E'),
    ),
    AppreciationTheme.greenGold => (
      PdfColor.fromHex('#176B4D'),
      PdfColor.fromHex('#C99A2E'),
    ),
    AppreciationTheme.maroonGold => (
      PdfColor.fromHex('#7A2330'),
      PdfColor.fromHex('#C99A2E'),
    ),
  };
  Future<Uint8List?> _image(
    String url,
    String data, {
    String? fallbackAsset,
  }) async {
    try {
      if (data.trim().isNotEmpty) {
        final raw = data.contains(',') ? data.split(',').last : data;
        return base64Decode(raw);
      }
      if (url.trim().isNotEmpty) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) return response.bodyBytes;
      }
    } catch (_) {}
    if (fallbackAsset != null) {
      try {
        return (await rootBundle.load(fallbackAsset)).buffer.asUint8List();
      } catch (_) {}
    }
    return null;
  }
}
