import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_attendance_summary.dart';
import '../../domain/services/parent_attendance_service.dart';

class ParentAttendancePage extends StatefulWidget {
  const ParentAttendancePage({super.key, required this.student});

  final StudentEntity student;

  @override
  State<ParentAttendancePage> createState() => _ParentAttendancePageState();
}

class _ParentAttendancePageState extends State<ParentAttendancePage> {
  final ParentAttendanceService _service = sl<ParentAttendanceService>();

  late DateTime _selectedMonth;
  ParentAttendanceSummary? _summary;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final value = await _service.loadMonthlyAttendance(
        studentId: widget.student.id,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (!mounted) return;

      setState(() {
        _summary = value;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  void _changeMonth(int offset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + offset,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.fullName} Attendance'),
        actions: const [DashboardNavigationButton()],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 54),
          const SizedBox(height: 14),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _MonthSelector(
          value: _selectedMonth,
          onPrevious: () => _changeMonth(-1),
          onNext: () => _changeMonth(1),
        ),
        const SizedBox(height: 16),
        _SummaryGrid(summary: summary),
        const SizedBox(height: 16),
        _AttendancePercentageCard(summary: summary),
        const SizedBox(height: 16),
        Text(
          'Daily Attendance',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (summary.records.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No attendance records found for this month.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...summary.records.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _AttendanceRecordTile(record: record),
            ),
          ),
      ],
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.value,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime value;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${months[value.month - 1]} ${value.year}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final ParentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total', summary.total, Icons.calendar_month_outlined),
      ('Present', summary.present, Icons.check_circle_outline),
      ('Absent', summary.absent, Icons.cancel_outlined),
      ('Late', summary.late, Icons.schedule_outlined),
      ('Leave', summary.leave, Icons.event_available_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 560
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(item.$3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item.$1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AttendancePercentageCard extends StatelessWidget {
  const _AttendancePercentageCard({required this.summary});

  final ParentAttendanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final value = summary.attendancePercentage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(value: value / 100, strokeWidth: 8),
                  Center(
                    child: Text(
                      '${value.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Percentage',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Present and Late records are counted as attended days.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  const _AttendanceRecordTile({required this.record});

  final AttendanceEntity record;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (record.status) {
      AttendanceStatus.present => ('Present', Icons.check_circle_outline),
      AttendanceStatus.absent => ('Absent', Icons.cancel_outlined),
      AttendanceStatus.leave => ('Leave', Icons.event_available_outlined),
      AttendanceStatus.late => ('Late', Icons.schedule_outlined),
    };

    final date = record.attendanceDate;

    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text('${date.day}')),
        title: Text(
          '${_weekday(date.weekday)}, '
          '${date.day}/${date.month}/${date.year}',
        ),
        subtitle: record.remarks.trim().isEmpty ? null : Text(record.remarks),
        trailing: Chip(avatar: Icon(icon, size: 18), label: Text(label)),
      ),
    );
  }

  String _weekday(int value) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[value - 1];
  }
}
