$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $fullPath = Join-Path $projectRoot $RelativePath
    $directory = Split-Path -Parent $fullPath

    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $fullPath) {
        $backupPath = "$fullPath.staff_final_$timestamp.bak"
        Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
        Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
    }

    [System.IO.File]::WriteAllText(
        $fullPath,
        $Content,
        $utf8NoBom
    )

    Write-Host "Written: $RelativePath" -ForegroundColor Green
}

function Patch-ProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Patch
    )

    $fullPath = Join-Path $projectRoot $RelativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Required file not found: $fullPath"
    }

    $content = [System.IO.File]::ReadAllText($fullPath)
    $updatedContent = & $Patch $content

    if ($updatedContent -eq $content) {
        Write-Host "Already configured or no change: $RelativePath" -ForegroundColor Yellow
        return
    }

    $backupPath = "$fullPath.staff_final_$timestamp.bak"
    Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray

    [System.IO.File]::WriteAllText(
        $fullPath,
        $updatedContent,
        $utf8NoBom
    )

    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Staff Module Final Reports Setup" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# STAFF REPORT PDF SERVICE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\services\staff_reports_pdf_service.dart" `
    -Content @'
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
    final recordsByStaff =
        <String, List<StaffAttendanceEntity>>{};

    for (final record in records) {
      recordsByStaff
          .putIfAbsent(
            record.staffId,
            () => <StaffAttendanceEntity>[],
          )
          .add(record);
    }

    final rows = <StaffAttendanceReportRow>[];
    final includedStaffIds = <String>{};

    for (final staffMember in staff) {
      final staffRecords =
          recordsByStaff[staffMember.id] ??
          const <StaffAttendanceEntity>[];

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
      if (includedStaffIds.contains(entry.key) ||
          entry.value.isEmpty) {
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
      (first, second) => first.staffName
          .toLowerCase()
          .compareTo(second.staffName.toLowerCase()),
    );

    return rows;
  }

  static Future<Uint8List> buildAttendanceReportPdf({
    required List<StaffAttendanceReportRow> rows,
    required DateTime month,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title:
          'Staff Attendance Report - ${_monthLabel(month)}',
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
    final totalLate = rows.fold<int>(
      0,
      (total, row) => total + row.lateDays,
    );
    final totalLeave = rows.fold<int>(
      0,
      (total, row) => total + row.leaveDays,
    );

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
                _summaryBox(
                  'Staff',
                  rows.length.toString(),
                ),
                _summaryBox(
                  'Present',
                  totalPresent.toString(),
                ),
                _summaryBox(
                  'Absent',
                  totalAbsent.toString(),
                ),
                _summaryBox(
                  'Late',
                  totalLate.toString(),
                ),
                _summaryBox(
                  'Leave',
                  totalLeave.toString(),
                ),
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
                for (var index = 0;
                    index < rows.length;
                    index++)
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
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 7,
              ),
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
      title:
          'Staff Leave Report - ${_monthLabel(month)}',
      author: 'Almustafa Connect ERP',
      subject: 'Monthly Staff Leave Report',
      creator: 'Almustafa Connect ERP',
    );

    final pending = leaves
        .where(
          (leave) =>
              leave.status == StaffLeaveStatus.pending,
        )
        .length;

    final approvedLeaves = leaves
        .where(
          (leave) =>
              leave.status == StaffLeaveStatus.approved,
        )
        .toList();

    final rejected = leaves
        .where(
          (leave) =>
              leave.status == StaffLeaveStatus.rejected,
        )
        .length;

    final unpaid = leaves
        .where(
          (leave) =>
              leave.leaveType == StaffLeaveType.unpaid,
        )
        .length;

    final approvedDays = approvedLeaves.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    final sortedLeaves = [...leaves]
      ..sort(
        (first, second) {
          final dateComparison =
              second.startDate.compareTo(first.startDate);

          if (dateComparison != 0) {
            return dateComparison;
          }

          return first.staffName
              .toLowerCase()
              .compareTo(second.staffName.toLowerCase());
        },
      );

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
                _summaryBox(
                  'Requests',
                  leaves.length.toString(),
                ),
                _summaryBox(
                  'Pending',
                  pending.toString(),
                ),
                _summaryBox(
                  'Approved',
                  approvedLeaves.length.toString(),
                ),
                _summaryBox(
                  'Approved Days',
                  _number(approvedDays),
                ),
                _summaryBox(
                  'Rejected',
                  rejected.toString(),
                ),
                _summaryBox(
                  'Unpaid',
                  unpaid.toString(),
                ),
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
                for (var index = 0;
                    index < sortedLeaves.length;
                    index++)
                  [
                    '${index + 1}',
                    sortedLeaves[index].staffName,
                    sortedLeaves[index].staffCode,
                    _leaveTypeLabel(
                      sortedLeaves[index].leaveType,
                    ),
                    _dateLabel(
                      sortedLeaves[index].startDate,
                    ),
                    _dateLabel(
                      sortedLeaves[index].endDate,
                    ),
                    _number(
                      sortedLeaves[index].totalDays,
                    ),
                    _durationLabel(
                      sortedLeaves[index].duration,
                    ),
                    _leaveStatusLabel(
                      sortedLeaves[index].status,
                    ),
                    sortedLeaves[index].reason,
                  ],
              ],
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue900,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(
                fontSize: 7,
              ),
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
              crossAxisAlignment:
                  pw.CrossAxisAlignment.start,
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
            crossAxisAlignment:
                pw.CrossAxisAlignment.end,
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
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _reportFooter(
    pw.Context context,
  ) {
    return pw.Column(
      children: [
        pw.Divider(
          color: PdfColors.grey400,
        ),
        pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Almustafa Connect ERP',
              style: const pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 8,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of '
              '${context.pagesCount}',
              style: const pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _summaryBox(
    String label,
    String value,
  ) {
    return pw.Container(
      width: 125,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              color: PdfColors.grey700,
              fontSize: 8,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureRow() {
    return pw.Row(
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
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
          pw.Divider(
            color: PdfColors.grey600,
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 8,
            ),
          ),
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
    final month =
        date.month.toString().padLeft(2, '0');

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

  static String _leaveTypeLabel(
    StaffLeaveType type,
  ) {
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

  static String _durationLabel(
    StaffLeaveDuration duration,
  ) {
    switch (duration) {
      case StaffLeaveDuration.fullDay:
        return 'Full Day';
      case StaffLeaveDuration.halfDay:
        return 'Half Day';
    }
  }

  static String _leaveStatusLabel(
    StaffLeaveStatus status,
  ) {
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
'@

# ============================================================
# STAFF ATTENDANCE REPORT PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_attendance_report_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../services/staff_reports_pdf_service.dart';

class StaffAttendanceReportPage extends StatefulWidget {
  const StaffAttendanceReportPage({super.key});

  @override
  State<StaffAttendanceReportPage> createState() =>
      _StaffAttendanceReportPageState();
}

class _StaffAttendanceReportPageState
    extends State<StaffAttendanceReportPage> {
  late DateTime _selectedMonth;
  late Future<_AttendanceReportData> _reportFuture;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    _reportFuture = _loadReport();
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
  }

  Future<_AttendanceReportData> _loadReport() async {
    final attendanceRepository =
        sl<StaffAttendanceRepository>();

    final staffRepository = sl<StaffRepository>();

    final records =
        await attendanceRepository.getAttendanceByDateRange(
      startDate: _selectedMonth,
      endDate: _monthEnd,
    );

    final staff = await staffRepository.getStaff();

    final rows =
        StaffReportsPdfService.buildAttendanceRows(
      staff: staff,
      records: records,
    );

    return _AttendanceReportData(
      rows: rows,
      records: records,
      staff: staff,
    );
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  void _showNextMonth() {
    if (!_canMoveNext) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(
        now.year,
        now.month,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  String _fileName() {
    final month =
        _selectedMonth.month.toString().padLeft(2, '0');

    return 'Staff_Attendance_Report_'
        '${_selectedMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance Report'),
        actions: [
          IconButton(
            tooltip: 'Previous Month',
            onPressed: _showPreviousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Current Month',
            onPressed: _showCurrentMonth,
            icon: const Icon(
              Icons.today_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Next Month',
            onPressed:
                _canMoveNext ? _showNextMonth : null,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReport,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<_AttendanceReportData>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ReportErrorView(
              title:
                  'Unable to load attendance report',
              message: snapshot.error.toString(),
              onRetry: _refreshReport,
            );
          }

          final data = snapshot.data;

          if (data == null || data.rows.isEmpty) {
            return const _EmptyReportView(
              title: 'No attendance records found',
              message:
                  'No staff attendance records are available for the selected month.',
              icon: Icons.fact_check_outlined,
            );
          }

          return PdfPreview(
            pdfFileName: _fileName(),
            initialPageFormat:
                PdfPageFormat.a4.landscape,
            canChangeOrientation: true,
            canChangePageFormat: true,
            allowPrinting: true,
            allowSharing: true,
            build: (pageFormat) {
              return StaffReportsPdfService
                  .buildAttendanceReportPdf(
                rows: data.rows,
                month: _selectedMonth,
                pageFormat: pageFormat,
              );
            },
          );
        },
      ),
    );
  }
}

class _AttendanceReportData {
  const _AttendanceReportData({
    required this.rows,
    required this.records,
    required this.staff,
  });

  final List<StaffAttendanceReportRow> rows;
  final List<StaffAttendanceEntity> records;
  final List<StaffEntity> staff;
}

class _EmptyReportView extends StatelessWidget {
  const _EmptyReportView({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportErrorView extends StatelessWidget {
  const _ReportErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
'@

# ============================================================
# STAFF LEAVE REPORT PAGE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_leave_report_page.dart" `
    -Content @'
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_leave_repository.dart';
import '../services/staff_reports_pdf_service.dart';

class StaffLeaveReportPage extends StatefulWidget {
  const StaffLeaveReportPage({super.key});

  @override
  State<StaffLeaveReportPage> createState() =>
      _StaffLeaveReportPageState();
}

class _StaffLeaveReportPageState
    extends State<StaffLeaveReportPage> {
  late DateTime _selectedMonth;
  late Future<List<StaffLeaveEntity>> _reportFuture;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    _reportFuture = _loadReport();
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
  }

  Future<List<StaffLeaveEntity>> _loadReport() {
    return sl<StaffLeaveRepository>()
        .getLeavesByDateRange(
      startDate: _selectedMonth,
      endDate: _monthEnd,
    );
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  void _showNextMonth() {
    if (!_canMoveNext) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(
        now.year,
        now.month,
        1,
      );
      _reportFuture = _loadReport();
    });
  }

  String _fileName() {
    final month =
        _selectedMonth.month.toString().padLeft(2, '0');

    return 'Staff_Leave_Report_'
        '${_selectedMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Leave Report'),
        actions: [
          IconButton(
            tooltip: 'Previous Month',
            onPressed: _showPreviousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Current Month',
            onPressed: _showCurrentMonth,
            icon: const Icon(
              Icons.today_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Next Month',
            onPressed:
                _canMoveNext ? _showNextMonth : null,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReport,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<StaffLeaveEntity>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _LeaveReportErrorView(
              message: snapshot.error.toString(),
              onRetry: _refreshReport,
            );
          }

          final leaves =
              snapshot.data ?? const <StaffLeaveEntity>[];

          if (leaves.isEmpty) {
            return const _EmptyLeaveReportView();
          }

          return PdfPreview(
            pdfFileName: _fileName(),
            initialPageFormat:
                PdfPageFormat.a4.landscape,
            canChangeOrientation: true,
            canChangePageFormat: true,
            allowPrinting: true,
            allowSharing: true,
            build: (pageFormat) {
              return StaffReportsPdfService
                  .buildLeaveReportPdf(
                leaves: leaves,
                month: _selectedMonth,
                pageFormat: pageFormat,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyLeaveReportView extends StatelessWidget {
  const _EmptyLeaveReportView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leave records found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No staff leave requests are available for the selected month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveReportErrorView extends StatelessWidget {
  const _LeaveReportErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load leave report',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
'@

# ============================================================
# PATCH STAFF ATTENDANCE PAGE
# ============================================================

Patch-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_attendance_page.dart" `
    -Patch {
        param($content)

        if (-not $content.Contains(
            "import 'staff_attendance_report_page.dart';"
        )) {
            $importMarker =
                "import 'staff_attendance_history_page.dart';"

            if (-not $content.Contains($importMarker)) {
                throw "Attendance Page import marker was not found."
            }

            $content = $content.Replace(
                $importMarker,
                "$importMarker`r`nimport 'staff_attendance_report_page.dart';"
            )
        }

        if (-not $content.Contains(
            "void _openAttendanceReport()"
        )) {
            $methodMarker = @'
  void _openHistory() {
'@

            $newMethod = @'
  void _openAttendanceReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffAttendanceReportPage(),
      ),
    );
  }

'@

            if (-not $content.Contains($methodMarker)) {
                throw "Attendance Page history method marker was not found."
            }

            $content = $content.Replace(
                $methodMarker,
                "$newMethod$methodMarker"
            )
        }

        if (-not $content.Contains(
            "tooltip: 'Attendance Report'"
        )) {
            $actionMarker = @'
            IconButton(
              tooltip: 'Attendance History',
'@

            $newAction = @'
            IconButton(
              tooltip: 'Attendance Report',
              onPressed: _openAttendanceReport,
              icon: const Icon(
                Icons.description_outlined,
              ),
            ),
'@

            if (-not $content.Contains($actionMarker)) {
                throw "Attendance Page AppBar marker was not found."
            }

            $content = $content.Replace(
                $actionMarker,
                "$newAction$actionMarker"
            )
        }

        return $content
    }

# ============================================================
# PATCH STAFF LEAVE PAGE
# ============================================================

Patch-ProjectFile `
    -RelativePath "lib\features\staff\presentation\pages\staff_leave_page.dart" `
    -Patch {
        param($content)

        if (-not $content.Contains(
            "import 'staff_leave_report_page.dart';"
        )) {
            $importMarker =
                "import 'staff_leave_history_page.dart';"

            if (-not $content.Contains($importMarker)) {
                throw "Leave Page import marker was not found."
            }

            $content = $content.Replace(
                $importMarker,
                "$importMarker`r`nimport 'staff_leave_report_page.dart';"
            )
        }

        if (-not $content.Contains(
            "void _openLeaveReport()"
        )) {
            $methodMarker = @'
  void _openHistory() {
'@

            $newMethod = @'
  void _openLeaveReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffLeaveReportPage(),
      ),
    );
  }

'@

            if (-not $content.Contains($methodMarker)) {
                throw "Leave Page history method marker was not found."
            }

            $content = $content.Replace(
                $methodMarker,
                "$newMethod$methodMarker"
            )
        }

        if (-not $content.Contains(
            "tooltip: 'Leave Report'"
        )) {
            $actionMarker = @'
            IconButton(
              tooltip: 'Pending Approvals',
'@

            $newAction = @'
            IconButton(
              tooltip: 'Leave Report',
              onPressed: _openLeaveReport,
              icon: const Icon(
                Icons.description_outlined,
              ),
            ),
'@

            if (-not $content.Contains($actionMarker)) {
                throw "Leave Page AppBar marker was not found."
            }

            $content = $content.Replace(
                $actionMarker,
                "$newAction$actionMarker"
            )
        }

        return $content
    }

# ============================================================
# STAFF MODULE COMPLETION DOCUMENT
# ============================================================

Write-ProjectFile `
    -RelativePath "DOCS\15_STAFF_MODULE_COMPLETION.md" `
    -Content @'
# Almustafa Connect ERP - Staff Module Completion

## Status

The Staff Module is functionally complete.

## Completed Features

### Staff Profiles

- Add staff
- Edit staff
- Delete staff
- Search staff
- Active and inactive status
- Staff details and directory
- Employment and salary information

### Staff Attendance

- Daily attendance marking
- Present, Absent, Late and Leave statuses
- Mark all present
- Attendance remarks
- Attendance history
- Monthly staff attendance
- Monthly attendance PDF report
- PDF preview, print, share and download

### Staff Leave Management

- Casual Leave
- Sick Leave
- Annual Leave
- Unpaid Leave
- Other Leave
- Full-day and half-day leave
- Pending, Approved, Rejected and Cancelled statuses
- Approval and rejection remarks
- Staff-wise leave history
- Monthly leave summary
- Monthly leave PDF report
- PDF preview, print, share and download

### Attendance and Leave Integration

- Approved leave automatically marks Staff Attendance as Leave
- Existing attendance record is updated instead of duplicated
- Leave type and duration are stored in attendance remarks

### Staff Salary Management

- Monthly salary generation
- Basic salary from staff profile
- Attendance counts
- Allowance
- Other deduction
- Attendance and unpaid-leave deduction
- Gross salary
- Net salary
- Paid and Unpaid status
- Payment date
- Payment method
- Payment reference
- Salary details
- Staff salary history

### Salary and Leave Integration

- Approved Unpaid Leave automatically calculates salary deduction
- Half-day unpaid leave deducts 0.5 day
- Paid salary records preserve their saved deduction

### Payroll Reports

- Individual Salary Slip PDF
- Monthly Payroll PDF Report
- PDF preview
- Print
- Share and download
- Payroll Excel export
- Payroll Summary worksheet
- Payroll Details worksheet

## Final Validation

Run:

```cmd
cd /d D:\Projects\almustafa-connect-erp
flutter analyze
```

Expected result:

```text
No issues found!
```

Runtime testing can be completed later using the Staff Dashboard.
'@

# ============================================================
# FORMAT CREATED / UPDATED DART FILES
# ============================================================

$dartFiles = @(
    "lib\features\staff\presentation\services\staff_reports_pdf_service.dart",
    "lib\features\staff\presentation\pages\staff_attendance_report_page.dart",
    "lib\features\staff\presentation\pages\staff_leave_report_page.dart",
    "lib\features\staff\presentation\pages\staff_attendance_page.dart",
    "lib\features\staff\presentation\pages\staff_leave_page.dart"
)

Push-Location $projectRoot

try {
    & dart format $dartFiles

    if ($LASTEXITCODE -ne 0) {
        throw "dart format failed."
    }

    Write-Host ""
    Write-Host "Running flutter analyze..." -ForegroundColor Cyan

    & flutter analyze

    if ($LASTEXITCODE -ne 0) {
        throw "flutter analyze found issues. Review the output above."
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "STAFF MODULE FINALIZATION COMPLETED." -ForegroundColor Green
Write-Host "Attendance Report added." -ForegroundColor Green
Write-Host "Leave Report added." -ForegroundColor Green
Write-Host "PDF preview, print, share and download enabled." -ForegroundColor Green
Write-Host "Completion document created in DOCS." -ForegroundColor Green
Write-Host ""
