import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/staff_leave_entity.dart';
import '../teacher_leave/teacher_leave_helpers.dart';

class TeacherLeaveReportService {
  const TeacherLeaveReportService._();

  static Future<Uint8List> buildPdf({
    required List<StaffLeaveEntity> leaves,
    required DateTime month,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title: 'Teacher Leave Report - ${teacherLeaveMonthLabel(month)}',
      author: 'Almustafa Connect ERP',
      subject: 'Monthly Teacher Leave Report',
      creator: 'Almustafa Connect ERP',
    );

    final approved = leaves
        .where((leave) => leave.status == StaffLeaveStatus.approved)
        .toList();

    final pending = leaves
        .where((leave) => leave.status == StaffLeaveStatus.pending)
        .length;

    final rejected = leaves
        .where((leave) => leave.status == StaffLeaveStatus.rejected)
        .length;

    final unpaid = leaves
        .where((leave) => leave.leaveType == StaffLeaveType.unpaid)
        .length;

    final approvedDays = approved.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    final sortedLeaves = [...leaves]
      ..sort((first, second) => second.startDate.compareTo(first.startDate));

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _header(month),
        footer: (context) => _footer(context),
        build: (context) {
          return [
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryBox('Requests', leaves.length.toString()),
                _summaryBox('Pending', pending.toString()),
                _summaryBox('Approved', approved.length.toString()),
                _summaryBox(
                  'Approved Days',
                  teacherLeaveDaysLabel(approvedDays),
                ),
                _summaryBox('Rejected', rejected.toString()),
                _summaryBox('Unpaid', unpaid.toString()),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Teacher',
                'Code',
                'Leave Type',
                'Start',
                'End',
                'Days',
                'Duration',
                'Status',
                'Reason',
              ],
              data: [
                for (var index = 0; index < sortedLeaves.length; index++)
                  [
                    '${index + 1}',
                    sortedLeaves[index].staffName,
                    sortedLeaves[index].staffCode,
                    teacherLeaveTypeLabel(sortedLeaves[index].leaveType),
                    teacherLeaveDateLabel(sortedLeaves[index].startDate),
                    teacherLeaveDateLabel(sortedLeaves[index].endDate),
                    teacherLeaveDaysLabel(sortedLeaves[index].totalDays),
                    teacherLeaveDurationLabel(sortedLeaves[index].duration),
                    teacherLeaveStatusLabel(sortedLeaves[index].status),
                    sortedLeaves[index].reason,
                  ],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 7),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 5,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(22),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(1.0),
                3: pw.FlexColumnWidth(1.1),
                4: pw.FlexColumnWidth(1.0),
                5: pw.FlexColumnWidth(1.0),
                6: pw.FlexColumnWidth(0.6),
                7: pw.FlexColumnWidth(0.9),
                8: pw.FlexColumnWidth(0.9),
                9: pw.FlexColumnWidth(2.4),
              },
            ),
            pw.SizedBox(height: 22),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _signature('Prepared By'),
                _signature('Checked By'),
                _signature('Approved By'),
              ],
            ),
          ];
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _header(DateTime month) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 44,
            height: 44,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(22),
            ),
            child: pw.Text(
              'AM',
              style: pw.TextStyle(
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ALMUSTAFA MODEL SCHOOL',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Vip Colony, Suraj Miani, Multan',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'MONTHLY TEACHER LEAVE REPORT',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                teacherLeaveMonthLabel(month),
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Almustafa Connect ERP',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
            ),
            pw.Text(
              'Page ${context.pageNumber} of '
              '${context.pagesCount}',
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(String label, String value) {
    return pw.Container(
      width: 125,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 8),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signature(String label) {
    return pw.SizedBox(
      width: 130,
      child: pw.Column(
        children: [
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey600),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}
