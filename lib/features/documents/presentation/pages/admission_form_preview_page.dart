import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../../settings/domain/usecases/manage_settings.dart';

class AdmissionFormPreviewPage extends StatelessWidget {
  const AdmissionFormPreviewPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admission Form Preview')),
    body: PdfPreview(
      pdfFileName: 'student_admission_form.pdf',
      initialPageFormat: PdfPageFormat.a4,
      canChangeOrientation: false,
      canChangePageFormat: false,
      allowPrinting: true,
      allowSharing: true,
      build: (_) => _AdmissionFormPdf.build(),
    ),
  );
}

class _AdmissionFormPdf {
  static Future<Uint8List> build() async {
    final settings = await sl<GetSchoolSettings>()();
    pw.ImageProvider? logo;
    if (settings.logoUrl.trim().isNotEmpty) {
      try {
        logo = await networkImage(settings.logoUrl.trim());
      } catch (_) {
        logo = null;
      }
    }
    logo ??= pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.jpeg')).buffer.asUint8List(),
    );

    pw.ImageProvider? principalSignature;
    final signatureData = settings.principalSignatureData.trim();
    if (signatureData.isNotEmpty) {
      try {
        final encoded = signatureData.contains(',')
            ? signatureData.substring(signatureData.indexOf(',') + 1)
            : signatureData;
        principalSignature = pw.MemoryImage(base64Decode(encoded));
      } catch (_) {
        principalSignature = null;
      }
    }
    if (principalSignature == null &&
        settings.principalSignatureUrl.trim().isNotEmpty) {
      try {
        principalSignature = await networkImage(
          settings.principalSignatureUrl.trim(),
        );
      } catch (_) {
        principalSignature = null;
      }
    }

    final address = settings.address.trim();
    final city = settings.city.trim();
    final displayAddress =
        city.isEmpty || address.toLowerCase().contains(city.toLowerCase())
        ? address
        : [address, city].where((value) => value.isNotEmpty).join(', ');
    final pdf = pw.Document(title: 'Student Admission Form');
    const blue = PdfColor.fromInt(0xFF123D78);
    const pale = PdfColor.fromInt(0xFFEAF2FF);
    const grey = PdfColor.fromInt(0xFF5F6B7A);

    pw.Widget header() => pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: pw.BoxDecoration(
            color: blue,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                width: 42,
                height: 42,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(21),
                ),
                child: logo == null
                    ? pw.Text(
                        'AMS',
                        style: pw.TextStyle(
                          color: blue,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      )
                    : pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Image(logo, fit: pw.BoxFit.contain),
                      ),
              ),
              pw.SizedBox(width: 11),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      settings.schoolName.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 17,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      displayAddress,
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Text(
                'ADMISSION FORM',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Please complete all applicable fields in clear BLOCK LETTERS.',
          style: const pw.TextStyle(color: grey, fontSize: 8),
        ),
        pw.SizedBox(height: 8),
      ],
    );

    pw.Widget field(String label, {double height = 14}) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: grey, fontSize: 7.3)),
        pw.Container(
          height: height,
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(
                color: PdfColor.fromInt(0xFF7E8A99),
                width: .7,
              ),
            ),
          ),
        ),
      ],
    );

    pw.Widget row(List<String> labels, {List<int>? flex}) => pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          pw.Expanded(flex: flex?[i] ?? 1, child: field(labels[i])),
          if (i < labels.length - 1) pw.SizedBox(width: 10),
        ],
      ],
    );

    pw.Widget section(String title, List<pw.Widget> children) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCCD7E6)),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: const pw.BoxDecoration(color: pale),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                color: blue,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            child: pw.Column(children: children),
          ),
        ],
      ),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        build: (_) => pw.Column(
          children: [
            header(),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: section('OFFICE USE ONLY', [
                    row([
                      'Admission No.',
                      'Admission Date',
                      'Academic Session',
                    ]),
                    pw.SizedBox(height: 5),
                    row(['Class', 'Section', 'Roll No.']),
                  ]),
                ),
                pw.SizedBox(width: 9),
                pw.Container(
                  width: 70,
                  height: 76,
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: pale,
                    border: pw.Border.all(color: blue),
                  ),
                  child: pw.Text(
                    'Recent\nPhotograph',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(color: grey, fontSize: 8.5),
                  ),
                ),
              ],
            ),
            section('STUDENT INFORMATION', [
              row(['First Name', 'Last Name']),
              pw.SizedBox(height: 4),
              row(
                ['Date of Birth (DD/MM/YYYY)', 'Gender', 'Blood Group'],
                flex: [2, 1, 1],
              ),
              pw.SizedBox(height: 4),
              row(['Previous School (if any)', 'Previous Class'], flex: [3, 1]),
            ]),
            section('FATHER INFORMATION', [
              row(['Full Name', 'CNIC No.'], flex: [2, 1]),
              pw.SizedBox(height: 4),
              row(['Mobile No.', 'WhatsApp No.', 'Occupation']),
            ]),
            section('MOTHER INFORMATION', [
              row(['Full Name', 'CNIC No.'], flex: [2, 1]),
              pw.SizedBox(height: 4),
              row(['Mobile No.', 'WhatsApp No.', 'Occupation']),
            ]),
            section('HOME ADDRESS', [
              field('Complete Residential Address', height: 22),
            ]),
            section('GUARDIAN / EMERGENCY CONTACT', [
              row(
                ['Guardian Full Name', 'Relationship', 'CNIC No.'],
                flex: [2, 1, 1],
              ),
              pw.SizedBox(height: 4),
              row(['Mobile No.', 'WhatsApp No.', 'Email Address']),
              pw.SizedBox(height: 4),
              field(
                'Preferred WhatsApp Contact:   Father [   ]     Mother [   ]     Guardian [   ]',
              ),
            ]),
            section('MEDICAL INFORMATION', [
              row(
                [
                  'Blood Group',
                  'Medical conditions, allergies, medication or special assistance required',
                ],
                flex: [1, 4],
              ),
            ]),
            section('PARENT / GUARDIAN DECLARATION', [
              pw.Text(
                'I certify that the information provided in this form is complete and correct. I agree to inform the school of any change in contact, medical or guardian information. I understand and agree to follow the school rules, fee policy and code of conduct.',
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 8.3, lineSpacing: 2),
              ),
              pw.SizedBox(height: 7),
              row(
                ['Parent / Guardian Name', 'Signature', 'Date'],
                flex: [2, 1, 1],
              ),
            ]),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 155,
                  height: 42,
                  alignment: pw.Alignment.bottomCenter,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: grey, width: .7),
                    ),
                  ),
                  child: principalSignature == null
                      ? pw.SizedBox()
                      : pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 2),
                          child: pw.Image(
                            principalSignature,
                            height: 34,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.SizedBox(
                  width: 155,
                  child: pw.Text(
                    'Principal Signature',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(color: grey, fontSize: 7.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }
}
