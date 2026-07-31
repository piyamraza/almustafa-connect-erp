import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';

class StaffAttendanceReportRow {
  const StaffAttendanceReportRow({
    required this.staffId,
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
  });

  final String staffId;
  final String staffCode;
  final String staffName;
  final String designation;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;

  int get totalMarkedDays {
    return presentDays + absentDays + lateDays + leaveDays;
  }

  double get attendancePercentage {
    if (totalMarkedDays == 0) {
      return 0;
    }

    return ((presentDays + lateDays) / totalMarkedDays) * 100;
  }
}

class StaffReportsPdfService {
  const StaffReportsPdfService._();

  static List<StaffAttendanceReportRow> buildAttendanceRows({
    required List<StaffEntity> staff,
    required List<StaffAttendanceEntity> records,
  }) {
    final recordsByStaff = <String, List<StaffAttendanceEntity>>{};

    for (final record in records) {
      recordsByStaff
          .putIfAbsent(record.staffId, () => <StaffAttendanceEntity>[])
          .add(record);
    }

    final rows = <StaffAttendanceReportRow>[];
    final includedStaffIds = <String>{};

    for (final staffMember in staff) {
      final staffRecords =
          recordsByStaff[staffMember.id] ?? const <StaffAttendanceEntity>[];

      if (!staffMember.isActive && staffRecords.isEmpty) {
        continue;
      }

      includedStaffIds.add(staffMember.id);

      rows.add(
        _attendanceRow(
          staffId: staffMember.id,
          staffCode: staffMember.staffId,
          staffName: staffMember.fullName,
          designation: staffMember.designation,
          records: staffRecords,
        ),
      );
    }

    for (final entry in recordsByStaff.entries) {
      if (includedStaffIds.contains(entry.key) || entry.value.isEmpty) {
        continue;
      }

      final firstRecord = entry.value.first;

      rows.add(
        _attendanceRow(
          staffId: firstRecord.staffId,
          staffCode: firstRecord.staffCode,
          staffName: firstRecord.staffName,
          designation: firstRecord.designation,
          records: entry.value,
        ),
      );
    }

    rows.sort(
      (first, second) => first.staffName.toLowerCase().compareTo(
        second.staffName.toLowerCase(),
      ),
    );

    return rows;
  }

  static Future<Uint8List> buildAttendanceReportPdf({
    required List<StaffAttendanceReportRow> rows,
    required DateTime month,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title: 'Staff Attendance Report - ${_monthLabel(month)}',
      author: 'Almustafa Connect ERP',
      subject: 'Monthly Staff Attendance Report',
      creator: 'Almustafa Connect ERP',
    );

    final totalPresent = rows.fold<int>(
      0,
      (total, row) => total + row.presentDays,
    );
    final totalAbsent = rows.fold<int>(
      0,
      (total, row) => total + row.absentDays,
    );
    final totalLate = rows.fold<int>(0, (total, row) => total + row.lateDays);
    final totalLeave = rows.fold<int>(0, (total, row) => total + row.leaveDays);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _reportHeader(
          title: 'MONTHLY STAFF ATTENDANCE REPORT',
          subtitle: _monthLabel(month),
        ),
        footer: _reportFooter,
        build: (context) {
          return [
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryBox('Staff', rows.length.toString()),
                _summaryBox('Present', totalPresent.toString()),
                _summaryBox('Absent', totalAbsent.toString()),
                _summaryBox('Late', totalLate.toString()),
                _summaryBox('Leave', totalLeave.toString()),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Staff Name',
                'Code',
                'Designation',
                'Present',
                'Absent',
                'Late',
                'Leave',
                'Marked',
                'Attendance %',
              ],
              data: [
                for (var index = 0; index < rows.length; index++)
                  [
                    '${index + 1}',
                    rows[index].staffName,
                    rows[index].staffCode,
                    rows[index].designation,
                    '${rows[index].presentDays}',
                    '${rows[index].absentDays}',
                    '${rows[index].lateDays}',
                    '${rows[index].leaveDays}',
                    '${rows[index].totalMarkedDays}',
                    '${rows[index].attendancePercentage.toStringAsFixed(1)}%',
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
                1: pw.FlexColumnWidth(2.2),
                2: pw.FlexColumnWidth(1.1),
                3: pw.FlexColumnWidth(1.7),
                4: pw.FlexColumnWidth(0.8),
                5: pw.FlexColumnWidth(0.8),
                6: pw.FlexColumnWidth(0.7),
                7: pw.FlexColumnWidth(0.7),
                8: pw.FlexColumnWidth(0.8),
                9: pw.FlexColumnWidth(1.1),
              },
            ),
            pw.SizedBox(height: 22),
            _signatureRow(),
          ];
        },
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildLeaveReportPdf({
    required List<StaffLeaveEntity> leaves,
    required DateTime month,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title: 'Staff Leave Report - ${_monthLabel(month)}',
      author: 'Almustafa Connect ERP',
      subject: 'Monthly Staff Leave Report',
      creator: 'Almustafa Connect ERP',
    );

    final pending = leaves
        .where((leave) => leave.status == StaffLeaveStatus.pending)
        .length;

    final approvedLeaves = leaves
        .where((leave) => leave.status == StaffLeaveStatus.approved)
        .toList();

    final rejected = leaves
        .where((leave) => leave.status == StaffLeaveStatus.rejected)
        .length;

    final unpaid = leaves
        .where((leave) => leave.leaveType == StaffLeaveType.unpaid)
        .length;

    final approvedDays = approvedLeaves.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    final sortedLeaves = [...leaves]
      ..sort((first, second) {
        final dateComparison = second.startDate.compareTo(first.startDate);

        if (dateComparison != 0) {
          return dateComparison;
        }

        return first.staffName.toLowerCase().compareTo(
          second.staffName.toLowerCase(),
        );
      });

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => _reportHeader(
          title: 'MONTHLY STAFF LEAVE REPORT',
          subtitle: _monthLabel(month),
        ),
        footer: _reportFooter,
        build: (context) {
          return [
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _summaryBox('Requests', leaves.length.toString()),
                _summaryBox('Pending', pending.toString()),
                _summaryBox('Approved', approvedLeaves.length.toString()),
                _summaryBox('Approved Days', _number(approvedDays)),
                _summaryBox('Rejected', rejected.toString()),
                _summaryBox('Unpaid', unpaid.toString()),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.TableHelper.fromTextArray(
              headers: const [
                '#',
                'Staff',
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
                    _leaveTypeLabel(sortedLeaves[index].leaveType),
                    _dateLabel(sortedLeaves[index].startDate),
                    _dateLabel(sortedLeaves[index].endDate),
                    _number(sortedLeaves[index].totalDays),
                    _durationLabel(sortedLeaves[index].duration),
                    _leaveStatusLabel(sortedLeaves[index].status),
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
                3: pw.FlexColumnWidth(1.2),
                4: pw.FlexColumnWidth(1.0),
                5: pw.FlexColumnWidth(1.0),
                6: pw.FlexColumnWidth(0.6),
                7: pw.FlexColumnWidth(0.9),
                8: pw.FlexColumnWidth(0.9),
                9: pw.FlexColumnWidth(2.3),
              },
            ),
            pw.SizedBox(height: 22),
            _signatureRow(),
          ];
        },
      ),
    );

    return document.save();
  }

  static StaffAttendanceReportRow _attendanceRow({
    required String staffId,
    required String staffCode,
    required String staffName,
    required String designation,
    required List<StaffAttendanceEntity> records,
  }) {
    var present = 0;
    var absent = 0;
    var late = 0;
    var leave = 0;

    for (final record in records) {
      switch (record.status) {
        case StaffAttendanceStatus.present:
          present++;
        case StaffAttendanceStatus.absent:
          absent++;
        case StaffAttendanceStatus.late:
          late++;
        case StaffAttendanceStatus.leave:
          leave++;
      }
    }

    return StaffAttendanceReportRow(
      staffId: staffId,
      staffCode: staffCode,
      staffName: staffName,
      designation: designation,
      presentDays: present,
      absentDays: absent,
      lateDays: late,
      leaveDays: leave,
    );
  }

  static pw.Widget _reportHeader({
    required String title,
    required String subtitle,
  }) {
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
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitle,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _reportFooter(pw.Context context) {
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

  static pw.Widget _signatureRow() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureBox('Prepared By'),
        _signatureBox('Checked By'),
        _signatureBox('Approved By'),
      ],
    );
  }

  static pw.Widget _signatureBox(String label) {
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

  static String _number(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  static String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _monthLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  static String _leaveTypeLabel(StaffLeaveType type) {
    switch (type) {
      case StaffLeaveType.casual:
        return 'Casual';
      case StaffLeaveType.sick:
        return 'Sick';
      case StaffLeaveType.annual:
        return 'Annual';
      case StaffLeaveType.unpaid:
        return 'Unpaid';
      case StaffLeaveType.other:
        return 'Other';
    }
  }

  static String _durationLabel(StaffLeaveDuration duration) {
    switch (duration) {
      case StaffLeaveDuration.fullDay:
        return 'Full Day';
      case StaffLeaveDuration.halfDay:
        return 'Half Day';
    }
  }

  static String _leaveStatusLabel(StaffLeaveStatus status) {
    switch (status) {
      case StaffLeaveStatus.pending:
        return 'Pending';
      case StaffLeaveStatus.approved:
        return 'Approved';
      case StaffLeaveStatus.rejected:
        return 'Rejected';
      case StaffLeaveStatus.cancelled:
        return 'Cancelled';
    }
  }
}
