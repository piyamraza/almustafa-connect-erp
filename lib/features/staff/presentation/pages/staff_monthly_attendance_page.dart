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

class StaffMonthlyAttendancePage extends StatelessWidget {
  const StaffMonthlyAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffAttendanceBloc>(
      create: (_) => sl<StaffAttendanceBloc>(),
      child: const _StaffMonthlyAttendanceView(),
    );
  }
}

class _StaffMonthlyAttendanceView extends StatefulWidget {
  const _StaffMonthlyAttendanceView();

  @override
  State<_StaffMonthlyAttendanceView> createState() =>
      _StaffMonthlyAttendanceViewState();
}

class _StaffMonthlyAttendanceViewState
    extends State<_StaffMonthlyAttendanceView> {
  late final Future<List<StaffEntity>> _staffFuture;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
    );

    _staffFuture = sl<StaffRepository>().getStaff();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSelectedMonth();
      }
    });
  }

  DateTime get _monthStart {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
  }

  DateTime get _monthEnd {
    final lastDay = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );

    final now = DateTime.now();

    final isCurrentMonth =
        _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;

    if (isCurrentMonth) {
      return DateTime(
        now.year,
        now.month,
        now.day,
      );
    }

    return lastDay;
  }

  bool get _canMoveToNextMonth {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  void _loadSelectedMonth() {
    context.read<StaffAttendanceBloc>().add(
          LoadStaffAttendanceByDateRangeEvent(
            startDate: _monthStart,
            endDate: _monthEnd,
          ),
        );
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
      );
    });

    _loadSelectedMonth();
  }

  void _showNextMonth() {
    if (!_canMoveToNextMonth) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
      );
    });

    _loadSelectedMonth();
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(
        now.year,
        now.month,
      );
    });

    _loadSelectedMonth();
  }

  String _monthName(int month) {
    const monthNames = [
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

    return monthNames[month - 1];
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  List<_StaffMonthlySummary> _buildStaffSummaries({
    required List<StaffEntity> staff,
    required List<StaffAttendanceEntity> records,
  }) {
    final staffById = <String, StaffEntity>{
      for (final staffMember in staff) staffMember.id: staffMember,
    };

    final recordsByStaffId =
        <String, List<StaffAttendanceEntity>>{};

    for (final record in records) {
      recordsByStaffId
          .putIfAbsent(
            record.staffId,
            () => <StaffAttendanceEntity>[],
          )
          .add(record);
    }

    final relevantStaffIds = <String>{
      ...recordsByStaffId.keys,
      ...staff
          .where((staffMember) => staffMember.isActive)
          .map((staffMember) => staffMember.id),
    };

    final summaries = <_StaffMonthlySummary>[];

    for (final staffId in relevantStaffIds) {
      final staffMember = staffById[staffId];
      final staffRecords =
          recordsByStaffId[staffId] ??
          const <StaffAttendanceEntity>[];

      final firstRecord =
          staffRecords.isEmpty ? null : staffRecords.first;

      var presentCount = 0;
      var absentCount = 0;
      var lateCount = 0;
      var leaveCount = 0;

      for (final record in staffRecords) {
        switch (record.status) {
          case StaffAttendanceStatus.present:
            presentCount++;
          case StaffAttendanceStatus.absent:
            absentCount++;
          case StaffAttendanceStatus.late:
            lateCount++;
          case StaffAttendanceStatus.leave:
            leaveCount++;
        }
      }

      final totalRecords = staffRecords.length;

      final attendancePercentage = totalRecords == 0
          ? 0.0
          : ((presentCount + lateCount) / totalRecords) * 100;

      final staffName =
          staffMember != null &&
              staffMember.fullName.trim().isNotEmpty
          ? staffMember.fullName.trim()
          : firstRecord?.staffName.trim().isNotEmpty == true
          ? firstRecord!.staffName.trim()
          : 'Unknown Staff Member';

      final staffCode =
          staffMember != null &&
              staffMember.staffId.trim().isNotEmpty
          ? staffMember.staffId.trim()
          : firstRecord?.staffCode.trim().isNotEmpty == true
          ? firstRecord!.staffCode.trim()
          : 'No Staff ID';

      final designation =
          staffMember != null &&
              staffMember.designation.trim().isNotEmpty
          ? staffMember.designation.trim()
          : firstRecord?.designation.trim().isNotEmpty == true
          ? firstRecord!.designation.trim()
          : 'Staff Member';

      summaries.add(
        _StaffMonthlySummary(
          staffId: staffId,
          staffName: staffName,
          staffCode: staffCode,
          designation: designation,
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          leaveCount: leaveCount,
          totalRecords: totalRecords,
          attendancePercentage: attendancePercentage,
        ),
      );
    }

    summaries.sort(
      (first, second) => first.staffName.toLowerCase().compareTo(
        second.staffName.toLowerCase(),
      ),
    );

    return summaries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Staff Attendance'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadSelectedMonth,
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

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        16,
                      ),
                      child: _MonthNavigationCard(
                        monthTitle:
                            '${_monthName(_selectedMonth.month)} '
                            '${_selectedMonth.year}',
                        dateRange:
                            '${_formatDate(_monthStart)} - '
                            '${_formatDate(_monthEnd)}',
                        canMoveNext: _canMoveToNextMonth,
                        onPrevious: _showPreviousMonth,
                        onNext: _showNextMonth,
                        onCurrentMonth: _showCurrentMonth,
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<StaffEntity>>(
                        future: _staffFuture,
                        builder: (context, staffSnapshot) {
                          if (staffSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (staffSnapshot.hasError) {
                            return _MonthlyErrorView(
                              message: staffSnapshot.error.toString(),
                              onRetry: _loadSelectedMonth,
                            );
                          }

                          final staff =
                              staffSnapshot.data ??
                              const <StaffEntity>[];

                          return BlocBuilder<
                            StaffAttendanceBloc,
                            StaffAttendanceState
                          >(
                            builder: (context, state) {
                              if (state
                                  is StaffAttendanceInitial) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              if (state
                                  is StaffAttendanceLoading) {
                                return const Center(
                                  child:
                                      CircularProgressIndicator(),
                                );
                              }

                              if (state is StaffAttendanceError) {
                                return _MonthlyErrorView(
                                  message: state.message,
                                  onRetry: _loadSelectedMonth,
                                );
                              }

                              if (state
                                  is StaffAttendanceLoaded) {
                                final summaries =
                                    _buildStaffSummaries(
                                      staff: staff,
                                      records: state.records,
                                    );

                                return _MonthlyAttendanceContent(
                                  records: state.records,
                                  summaries: summaries,
                                  horizontalPadding:
                                      horizontalPadding,
                                );
                              }

                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MonthNavigationCard extends StatelessWidget {
  const _MonthNavigationCard({
    required this.monthTitle,
    required this.dateRange,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrentMonth,
  });

  final String monthTitle;
  final String dateRange;
  final bool canMoveNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCurrentMonth;

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
            final isCompact = constraints.maxWidth < 650;

            final monthInformation = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dateRange,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            final controls = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                IconButton.outlined(
                  tooltip: 'Previous Month',
                  onPressed: onPrevious,
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCurrentMonth,
                  icon: const Icon(
                    Icons.today_outlined,
                  ),
                  label: const Text('Current Month'),
                ),
                IconButton.outlined(
                  tooltip: 'Next Month',
                  onPressed: canMoveNext ? onNext : null,
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  monthInformation,
                  const SizedBox(height: 16),
                  controls,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: monthInformation),
                const SizedBox(width: 20),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthlyAttendanceContent extends StatelessWidget {
  const _MonthlyAttendanceContent({
    required this.records,
    required this.summaries,
    required this.horizontalPadding,
  });

  final List<StaffAttendanceEntity> records;
  final List<_StaffMonthlySummary> summaries;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final presentCount = records
        .where(
          (record) =>
              record.status ==
              StaffAttendanceStatus.present,
        )
        .length;

    final absentCount = records
        .where(
          (record) =>
              record.status ==
              StaffAttendanceStatus.absent,
        )
        .length;

    final lateCount = records
        .where(
          (record) =>
              record.status == StaffAttendanceStatus.late,
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
        : ((presentCount + lateCount) / records.length) *
              100;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        32,
      ),
      children: [
        _MonthlySummarySection(
          totalRecords: records.length,
          presentCount: presentCount,
          absentCount: absentCount,
          lateCount: lateCount,
          leaveCount: leaveCount,
          attendancePercentage: attendancePercentage,
        ),
        const SizedBox(height: 20),
        _SectionHeader(
          title: 'Staff Monthly Summary',
          subtitle:
              '${summaries.length} staff member'
              '${summaries.length == 1 ? '' : 's'}',
        ),
        const SizedBox(height: 14),
        if (summaries.isEmpty)
          const _EmptyMonthlyAttendanceView()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 14.0;

              final columns =
                  constraints.maxWidth >= 850 ? 2 : 1;

              final cardWidth =
                  (constraints.maxWidth -
                      spacing * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: summaries.map((summary) {
                  return SizedBox(
                    width: cardWidth,
                    child: _StaffMonthlyAttendanceCard(
                      summary: summary,
                    ),
                  );
                }).toList(),
              );
            },
          ),
      ],
    );
  }
}

class _MonthlySummarySection extends StatelessWidget {
  const _MonthlySummarySection({
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.attendancePercentage,
  });

  final int totalRecords;
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
            (constraints.maxWidth -
                spacing * (columns - 1)) /
            columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: StaffAttendanceSummaryCard(
                title: 'Total Records',
                value: totalRecords.toString(),
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

class _StaffMonthlyAttendanceCard extends StatelessWidget {
  const _StaffMonthlyAttendanceCard({
    required this.summary,
  });

  final _StaffMonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final progressValue =
        (summary.attendancePercentage / 100).clamp(
          0.0,
          1.0,
        );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    color:
                        theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.staffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${summary.staffCode} • '
                        '${summary.designation}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(
                          color: theme
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${summary.attendancePercentage.toStringAsFixed(1)}%',
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusCount(
                  label: 'Present',
                  value: summary.presentCount,
                  color: Colors.green,
                ),
                _StatusCount(
                  label: 'Absent',
                  value: summary.absentCount,
                  color: Colors.red,
                ),
                _StatusCount(
                  label: 'Late',
                  value: summary.lateCount,
                  color: Colors.blue,
                ),
                _StatusCount(
                  label: 'Leave',
                  value: summary.leaveCount,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 18,
                  color:
                      theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 7),
                Text(
                  '${summary.totalRecords} marked day'
                  '${summary.totalRecords == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _EmptyMonthlyAttendanceView extends StatelessWidget {
  const _EmptyMonthlyAttendanceView();

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
              Icons.calendar_month_outlined,
              size: 68,
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
              'Staff attendance has not been marked for this month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyErrorView extends StatelessWidget {
  const _MonthlyErrorView({
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
          constraints: const BoxConstraints(
            maxWidth: 450,
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load monthly attendance',
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
      ),
    );
  }
}

class _StaffMonthlySummary {
  const _StaffMonthlySummary({
    required this.staffId,
    required this.staffName,
    required this.staffCode,
    required this.designation,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.leaveCount,
    required this.totalRecords,
    required this.attendancePercentage,
  });

  final String staffId;
  final String staffName;
  final String staffCode;
  final String designation;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final int totalRecords;
  final double attendancePercentage;
}