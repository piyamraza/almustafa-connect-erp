import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_attendance_bloc.dart';
import '../bloc/staff_attendance_event.dart';
import '../bloc/staff_attendance_state.dart';
import '../widgets/staff_attendance_summary_card.dart';

class StaffAttendanceHistoryPage extends StatelessWidget {
  const StaffAttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffAttendanceBloc>(
      create: (_) => sl<StaffAttendanceBloc>(),
      child: const _StaffAttendanceHistoryView(),
    );
  }
}

class _StaffAttendanceHistoryView extends StatefulWidget {
  const _StaffAttendanceHistoryView();

  @override
  State<_StaffAttendanceHistoryView> createState() =>
      _StaffAttendanceHistoryViewState();
}

class _StaffAttendanceHistoryViewState
    extends State<_StaffAttendanceHistoryView> {
  late final Future<List<StaffEntity>> _staffFuture;

  StaffEntity? _selectedStaff;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(
      now.year,
      now.month,
      1,
    );

    _endDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    _staffFuture = sl<StaffRepository>().getStaff();
  }

  void _loadHistory() {
    final selectedStaff = _selectedStaff;

    if (selectedStaff == null) {
      return;
    }

    context.read<StaffAttendanceBloc>().add(
          LoadStaffAttendanceByStaffEvent(
            staffId: selectedStaff.id,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  Future<void> _pickDateRange() async {
    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      helpText: 'Select attendance period',
      saveText: 'Apply',
    );

    if (selectedRange == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedRange.start.year,
        selectedRange.start.month,
        selectedRange.start.day,
      );

      _endDate = DateTime(
        selectedRange.end.year,
        selectedRange.end.month,
        selectedRange.end.day,
      );
    });

    _loadHistory();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _statusLabel(StaffAttendanceStatus status) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return 'Present';
      case StaffAttendanceStatus.absent:
        return 'Absent';
      case StaffAttendanceStatus.late:
        return 'Late';
      case StaffAttendanceStatus.leave:
        return 'Leave';
    }
  }

  Color _statusColor(
    BuildContext context,
    StaffAttendanceStatus status,
  ) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return Colors.green;
      case StaffAttendanceStatus.absent:
        return Theme.of(context).colorScheme.error;
      case StaffAttendanceStatus.late:
        return Colors.blue;
      case StaffAttendanceStatus.leave:
        return Colors.orange;
    }
  }

  IconData _statusIcon(StaffAttendanceStatus status) {
    switch (status) {
      case StaffAttendanceStatus.present:
        return Icons.check_circle_outline;
      case StaffAttendanceStatus.absent:
        return Icons.cancel_outlined;
      case StaffAttendanceStatus.late:
        return Icons.schedule_outlined;
      case StaffAttendanceStatus.leave:
        return Icons.event_busy_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance History'),
        actions: [
          IconButton(
            tooltip: 'Refresh History',
            onPressed: _selectedStaff == null ? null : _loadHistory,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1200
                ? 32.0
                : constraints.maxWidth >= 700
                    ? 24.0
                    : 16.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HistoryFilters(
                        staffFuture: _staffFuture,
                        selectedStaff: _selectedStaff,
                        startDate: _formatDate(_startDate),
                        endDate: _formatDate(_endDate),
                        onStaffChanged: (staff) {
                          setState(() {
                            _selectedStaff = staff;
                          });

                          _loadHistory();
                        },
                        onPickDateRange: _pickDateRange,
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child:
                            BlocBuilder<StaffAttendanceBloc,
                                StaffAttendanceState>(
                          builder: (context, state) {
                            if (_selectedStaff == null) {
                              return const _SelectStaffView();
                            }

                            if (state is StaffAttendanceInitial) {
                              return const _SelectStaffView();
                            }

                            if (state is StaffAttendanceLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state is StaffAttendanceError) {
                              return _HistoryErrorView(
                                message: state.message,
                                onRetry: _loadHistory,
                              );
                            }

                            if (state is StaffAttendanceLoaded) {
                              return _AttendanceHistoryContent(
                                records: state.records,
                                startDate: _formatDate(_startDate),
                                endDate: _formatDate(_endDate),
                                statusLabel: _statusLabel,
                                statusColor: (status) {
                                  return _statusColor(
                                    context,
                                    status,
                                  );
                                },
                                statusIcon: _statusIcon,
                                formatDate: _formatDate,
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.staffFuture,
    required this.selectedStaff,
    required this.startDate,
    required this.endDate,
    required this.onStaffChanged,
    required this.onPickDateRange,
  });

  final Future<List<StaffEntity>> staffFuture;
  final StaffEntity? selectedStaff;
  final String startDate;
  final String endDate;
  final ValueChanged<StaffEntity?> onStaffChanged;
  final VoidCallback onPickDateRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns = constraints.maxWidth >= 700;
            final fieldWidth = useTwoColumns
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance History Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select a staff member and attendance period.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: FutureBuilder<List<StaffEntity>>(
                        future: staffFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Staff Member',
                                prefixIcon:
                                    Icon(Icons.person_search_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: LinearProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Staff Member',
                                prefixIcon:
                                    Icon(Icons.person_search_outlined),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                'Unable to load staff',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            );
                          }

                          final staff =
                              snapshot.data ?? const <StaffEntity>[];

                          final sortedStaff = List<StaffEntity>.from(staff)
                            ..sort(
                              (first, second) =>
                                  first.fullName.toLowerCase().compareTo(
                                        second.fullName.toLowerCase(),
                                      ),
                            );

                          return DropdownButtonFormField<StaffEntity>(
                            key: ValueKey(selectedStaff?.id),
                            initialValue: selectedStaff,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Staff Member',
                              prefixIcon:
                                  Icon(Icons.person_search_outlined),
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Select staff member'),
                            items: sortedStaff.map((staffMember) {
                              final name =
                                  staffMember.fullName.trim().isEmpty
                                      ? 'Unnamed Staff Member'
                                      : staffMember.fullName.trim();

                              final staffCode =
                                  staffMember.staffId.trim().isEmpty
                                      ? 'No Staff ID'
                                      : staffMember.staffId.trim();

                              return DropdownMenuItem<StaffEntity>(
                                value: staffMember,
                                child: Text(
                                  '$name ($staffCode)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: onStaffChanged,
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: onPickDateRange,
                        icon: const Icon(
                          Icons.date_range_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          child: Text(
                            '$startDate  -  $endDate',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceHistoryContent extends StatelessWidget {
  const _AttendanceHistoryContent({
    required this.records,
    required this.startDate,
    required this.endDate,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.formatDate,
  });

  final List<StaffAttendanceEntity> records;
  final String startDate;
  final String endDate;
  final String Function(StaffAttendanceStatus status) statusLabel;
  final Color Function(StaffAttendanceStatus status) statusColor;
  final IconData Function(StaffAttendanceStatus status) statusIcon;
  final String Function(DateTime date) formatDate;

  @override
  Widget build(BuildContext context) {
    final presentCount = records
        .where(
          (record) =>
              record.status == StaffAttendanceStatus.present,
        )
        .length;

    final absentCount = records
        .where(
          (record) =>
              record.status == StaffAttendanceStatus.absent,
        )
        .length;

    final lateCount = records
        .where(
          (record) => record.status == StaffAttendanceStatus.late,
        )
        .length;

    final leaveCount = records
        .where(
          (record) =>
              record.status == StaffAttendanceStatus.leave,
        )
        .length;

    final attendancePercentage = records.isEmpty
        ? 0.0
        : ((presentCount + lateCount) / records.length) * 100;

    final sortedRecords = List<StaffAttendanceEntity>.from(records)
      ..sort(
        (first, second) => second.attendanceDate.compareTo(
          first.attendanceDate,
        ),
      );

    return ListView(
      padding: const EdgeInsets.only(
        bottom: 32,
      ),
      children: [
        _AttendanceSummary(
          totalCount: records.length,
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          leaveCount: leaveCount,
          attendancePercentage: attendancePercentage,
        ),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.date_range_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Attendance records from $startDate to $endDate',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (sortedRecords.isEmpty)
          const _EmptyHistoryView()
        else
          ...sortedRecords.map(
            (record) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AttendanceHistoryItem(
                record: record,
                statusLabel: statusLabel(record.status),
                statusColor: statusColor(record.status),
                statusIcon: statusIcon(record.status),
                formattedDate: formatDate(record.attendanceDate),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({
    required this.totalCount,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.attendancePercentage,
  });

  final int totalCount;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final double attendancePercentage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;

        final columns = constraints.maxWidth >= 1100
            ? 5
            : constraints.maxWidth >= 650
                ? 2
                : 1;

        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) /
                columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Total Records',
                value: totalCount.toString(),
                icon: Icons.list_alt_outlined,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Present',
                value: presentCount.toString(),
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Absent',
                value: absentCount.toString(),
                icon: Icons.cancel_outlined,
                iconColor: Colors.red,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Late / Leave',
                value: '$lateCount / $leaveCount',
                icon: Icons.schedule_outlined,
                iconColor: Colors.orange,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Attendance',
                value:
                    '${attendancePercentage.toStringAsFixed(1)}%',
                icon: Icons.percent_outlined,
                iconColor: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceHistoryItem extends StatelessWidget {
  const _AttendanceHistoryItem({
    required this.record,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.formattedDate,
  });

  final StaffAttendanceEntity record;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final String formattedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            final information = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.designation.trim().isEmpty
                            ? record.staffCode
                            : '${record.staffCode} • ${record.designation}',
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (record.remarks.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          record.remarks.trim(),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final statusChip = Chip(
              avatar: Icon(
                statusIcon,
                size: 18,
                color: statusColor,
              ),
              label: Text(statusLabel),
              side: BorderSide.none,
              backgroundColor:
                  statusColor.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: statusChip,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 16),
                statusChip,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SelectStaffView extends StatelessWidget {
  const _SelectStaffView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a staff member',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a staff member above to view attendance history.',
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

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 50,
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No attendance records found',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no attendance records for the selected period.',
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

class _HistoryErrorView extends StatelessWidget {
  const _HistoryErrorView({
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load history',
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
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}