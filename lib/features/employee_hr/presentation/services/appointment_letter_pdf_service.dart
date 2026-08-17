import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../settings/domain/entities/school_settings_entity.dart';

class AppointmentLetterPdfService {
  static Future<Uint8List> build(
    Map<String, dynamic> letter,
    SchoolSettingsEntity school,
  ) async {
    final pdf = pw.Document();
    final terms = (letter['terms'] as List? ?? const [])
        .whereType<Map>()
        .where((e) => e['enabled'] != false)
        .map((e) => e['text']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    String date(dynamic value) {
      if (value is Timestamp) return DateFormat('dd MMMM yyyy').format(value.toDate());
      if (value is DateTime) return DateFormat('dd MMMM yyyy').format(value);
      return value?.toString() ?? '-';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 34),
        header: (_) => pw.Column(children: [
          pw.Text(school.schoolName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          if (school.address.isNotEmpty) pw.Text(school.address, style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 5), pw.Divider(color: PdfColors.blue700),
        ]),
        footer: (c) => pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount}', style: const pw.TextStyle(fontSize: 8))),
        build: (_) => [
          pw.Center(child: pw.Text('TEACHER APPOINTMENT LETTER', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline))),
          pw.SizedBox(height: 14),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Letter No: ${letter['letterNumber']}'), pw.Text('Issue Date: ${date(letter['issueDate'])}')]),
          pw.SizedBox(height: 14),
          pw.Text('Dear ${letter['teacherName']},', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('We are pleased to appoint you as ${letter['designation']} at ${letter['branch']} with effect from ${date(letter['joiningDate'])}. Your appointment details are given below:'),
          pw.SizedBox(height: 10),
          pw.Table(border: pw.TableBorder.all(color: PdfColors.grey400, width: .5), children: [
            _row('Employee ID', letter['employeeId'], 'CNIC', letter['cnic']),
            _row('Father / Husband', letter['fatherName'], 'Employment Type', letter['employmentType']),
            _row('Subjects / Classes', letter['assignment'], 'Reporting To', letter['reportingAuthority']),
            _row('Monthly Salary', 'Rs. ${letter['monthlySalary']}', 'Allowances / Deductions', letter['allowancesDeductions']),
            _row('Working Days / Timings', letter['workingTimings'], 'Contract / Probation', '${date(letter['startDate'])} - ${date(letter['endDate'])}'),
          ]),
          pw.SizedBox(height: 12),
          pw.Text('Terms & Conditions', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...terms.asMap().entries.map((e) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 3), child: pw.Text('${e.key + 1}. ${e.value}', style: const pw.TextStyle(fontSize: 8.5)))),
          if ((letter['remarks'] ?? '').toString().isNotEmpty) ...[pw.SizedBox(height: 8), pw.Text('Remarks: ${letter['remarks']}')],
          pw.SizedBox(height: 22),
          pw.Text('I have read, understood and accepted the appointment and its terms and conditions.'),
          pw.SizedBox(height: 30),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [_sign('Teacher Signature / Date'), _sign('Thumb Impression'), _sign('${school.principalDesignation} / Authorized Officer')]),
          pw.SizedBox(height: 28),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [_sign('HR / Admin'), _sign('School Stamp'), if (letter['witnessesRequired'] == true) _sign('Witness(es)')]),
        ],
      ),
    );
    return pdf.save();
  }

  static pw.TableRow _row(String a, dynamic b, String c, dynamic d) => pw.TableRow(children: [_cell(a, true), _cell(b), _cell(c, true), _cell(d)]);
  static pw.Widget _cell(dynamic text, [bool bold = false]) => pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text((text ?? '-').toString(), style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : null)));
  static pw.Widget _sign(String title) => pw.SizedBox(width: 130, child: pw.Column(children: [pw.Container(height: .5, color: PdfColors.grey700), pw.SizedBox(height: 3), pw.Text(title, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))]));
}
