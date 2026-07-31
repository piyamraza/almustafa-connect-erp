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
  State<StaffLeaveReportPage> createState() => _StaffLeaveReportPageState();
}

class _StaffLeaveReportPageState extends State<StaffLeaveReportPage> {
  late DateTime _selectedMonth;
  late Future<List<StaffLeaveEntity>> _reportFuture;

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

  Future<List<StaffLeaveEntity>> _loadReport() {
    return sl<StaffLeaveRepository>().getLeavesByDateRange(
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
      _selectedMonth = DateTime(now.year, now.month, 1);
      _reportFuture = _loadReport();
    });
  }

  String _fileName() {
    final month = _selectedMonth.month.toString().padLeft(2, '0');

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
      body: FutureBuilder<List<StaffLeaveEntity>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _LeaveReportErrorView(
              message: snapshot.error.toString(),
              onRetry: _refreshReport,
            );
          }

          final leaves = snapshot.data ?? const <StaffLeaveEntity>[];

          if (leaves.isEmpty) {
            return const _EmptyLeaveReportView();
          }

          return PdfPreview(
            pdfFileName: _fileName(),
            initialPageFormat: PdfPageFormat.a4.landscape,
            canChangeOrientation: true,
            canChangePageFormat: true,
            allowPrinting: true,
            allowSharing: true,
            build: (pageFormat) {
              return StaffReportsPdfService.buildLeaveReportPdf(
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
  const _LeaveReportErrorView({required this.message, required this.onRetry});

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
              'Unable to load leave report',
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
