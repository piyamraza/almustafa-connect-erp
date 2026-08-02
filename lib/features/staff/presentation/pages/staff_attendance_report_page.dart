import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../services/staff_reports_pdf_service.dart';

class StaffAttendanceReportPage extends StatefulWidget {
  const StaffAttendanceReportPage({super.key});

  @override
  State<StaffAttendanceReportPage> createState() =>
      _StaffAttendanceReportPageState();
}

class _StaffAttendanceReportPageState extends State<StaffAttendanceReportPage> {
  late DateTime _selectedMonth;
  late Future<List<StaffAttendanceReportRow>> _reportFuture;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month, 1);

    _reportFuture = _loadReport();
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
  }

  Future<List<StaffAttendanceReportRow>> _loadReport() async {
    final attendanceRepository = sl<StaffAttendanceRepository>();

    final staffRepository = sl<StaffRepository>();

    final records = await attendanceRepository.getAttendanceByDateRange(
      startDate: _selectedMonth,
      endDate: _monthEnd,
    );

    final staff = await staffRepository.getStaff();

    return StaffReportsPdfService.buildAttendanceRows(
      staff: staff,
      records: records,
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
      _selectedMonth = DateTime(now.year, now.month, 1);

      _reportFuture = _loadReport();
    });
  }

  String _fileName() {
    final month = _selectedMonth.month.toString().padLeft(2, '0');

    return 'Staff_Attendance_Report_'
        '${_selectedMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance Report'),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Previous Month',
            onPressed: _showPreviousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Current Month',
            onPressed: _showCurrentMonth,
            icon: const Icon(Icons.today_outlined),
          ),
          IconButton(
            tooltip: 'Next Month',
            onPressed: _canMoveNext ? _showNextMonth : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReport,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<StaffAttendanceReportRow>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ReportErrorView(
              title: 'Unable to load attendance report',
              message: snapshot.error.toString(),
              onRetry: _refreshReport,
            );
          }

          final rows = snapshot.data ?? const <StaffAttendanceReportRow>[];

          final hasMarkedAttendance = rows.any(
            (row) => row.totalMarkedDays > 0,
          );

          if (!hasMarkedAttendance) {
            return const _EmptyReportView(
              title: 'No attendance records found',
              message:
                  'No staff attendance records are available for the selected month.',
              icon: Icons.fact_check_outlined,
            );
          }

          return PdfPreview(
            pdfFileName: _fileName(),
            initialPageFormat: PdfPageFormat.a4.landscape,
            canChangeOrientation: true,
            canChangePageFormat: true,
            allowPrinting: true,
            allowSharing: true,
            build: (pageFormat) {
              return StaffReportsPdfService.buildAttendanceReportPdf(
                rows: rows,
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
            Icon(icon, size: 70, color: theme.colorScheme.onSurfaceVariant),
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
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
