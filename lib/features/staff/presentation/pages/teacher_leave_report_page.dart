import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_leave_repository.dart';
import '../services/teacher_leave_report_service.dart';
import '../teacher_leave/teacher_leave_helpers.dart';

class TeacherLeaveReportPage extends StatefulWidget {
  const TeacherLeaveReportPage({super.key});

  @override
  State<TeacherLeaveReportPage> createState() => _TeacherLeaveReportPageState();
}

class _TeacherLeaveReportPageState extends State<TeacherLeaveReportPage> {
  late DateTime _selectedMonth;
  late Future<List<StaffLeaveEntity>> _future;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month, 1);

    _future = _loadReport();
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
  }

  Future<List<StaffLeaveEntity>> _loadReport() async {
    final leaves = await sl<StaffLeaveRepository>().getLeavesByDateRange(
      startDate: _selectedMonth,
      endDate: _monthEnd,
    );

    return leaves.where(isTeacherLeave).toList();
  }

  void _refresh() {
    setState(() {
      _future = _loadReport();
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
      _future = _loadReport();
    });
  }

  void _nextMonth() {
    if (!_canMoveNext) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
      _future = _loadReport();
    });
  }

  void _currentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
      _future = _loadReport();
    });
  }

  String _fileName() {
    final month = _selectedMonth.month.toString().padLeft(2, '0');

    return 'Teacher_Leave_Report_'
        '${_selectedMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Leave Report'),
        actions: [
          IconButton(
            tooltip: 'Previous Month',
            onPressed: _previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            tooltip: 'Current Month',
            onPressed: _currentMonth,
            icon: const Icon(Icons.today_outlined),
          ),
          IconButton(
            tooltip: 'Next Month',
            onPressed: _canMoveNext ? _nextMonth : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<StaffLeaveEntity>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ReportMessageView(
              title: 'Unable to load report',
              message: snapshot.error.toString(),
            );
          }

          final leaves = snapshot.data ?? const <StaffLeaveEntity>[];

          if (leaves.isEmpty) {
            return const _ReportMessageView(
              title: 'No teacher leave records',
              message:
                  'No teacher leave requests exist for the selected month.',
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
              return TeacherLeaveReportService.buildPdf(
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

class _ReportMessageView extends StatelessWidget {
  const _ReportMessageView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 68,
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
