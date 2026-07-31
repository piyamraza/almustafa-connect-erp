import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../teacher_leave/teacher_leave_helpers.dart';
import '../widgets/teacher_leave_list_item.dart';
import 'add_teacher_leave_page.dart';
import 'teacher_leave_approval_page.dart';
import 'teacher_leave_history_page.dart';
import 'teacher_leave_report_page.dart';

class TeacherLeavePage extends StatelessWidget {
  const TeacherLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _TeacherLeaveView(),
    );
  }
}

class _TeacherLeaveView extends StatefulWidget {
  const _TeacherLeaveView();

  @override
  State<_TeacherLeaveView> createState() => _TeacherLeaveViewState();
}

class _TeacherLeaveViewState extends State<_TeacherLeaveView> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(now.year, now.month, 1);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMonth();
      }
    });
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year && _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
  }

  void _loadMonth() {
    context.read<StaffLeaveBloc>().add(
      LoadStaffLeavesByDateRangeEvent(
        startDate: _selectedMonth,
        endDate: _monthEnd,
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });

    _loadMonth();
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
    });

    _loadMonth();
  }

  void _currentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });

    _loadMonth();
  }

  Future<void> _openAddLeave() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddTeacherLeavePage()),
    );

    if (saved == true && mounted) {
      _loadMonth();
    }
  }

  Future<void> _openApprovals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TeacherLeaveApprovalPage()),
    );

    if (mounted) {
      _loadMonth();
    }
  }

  void _openHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TeacherLeaveHistoryPage()),
    );
  }

  void _openReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const TeacherLeaveReportPage()),
    );
  }

  void _handleState(BuildContext context, StaffLeaveState state) {
    if (state is StaffLeaveError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    if (state is StaffLeaveLoaded && state.successMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Teacher Leave Management'),
          actions: [
            IconButton(
              tooltip: 'Leave Report',
              onPressed: _openReport,
              icon: const Icon(Icons.description_outlined),
            ),
            IconButton(
              tooltip: 'Pending Approvals',
              onPressed: _openApprovals,
              icon: const Icon(Icons.approval_outlined),
            ),
            IconButton(
              tooltip: 'Leave History',
              onPressed: _openHistory,
              icon: const Icon(Icons.history_outlined),
            ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadMonth,
              icon: const Icon(Icons.refresh_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddLeave,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Teacher Leave'),
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
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          18,
                        ),
                        child: _MonthHeader(
                          monthLabel: teacherLeaveMonthLabel(_selectedMonth),
                          canMoveNext: _canMoveNext,
                          onPrevious: _previousMonth,
                          onNext: _nextMonth,
                          onCurrentMonth: _currentMonth,
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<StaffLeaveBloc, StaffLeaveState>(
                          builder: (context, state) {
                            if (state is StaffLeaveInitial ||
                                state is StaffLeaveLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (state is StaffLeaveError) {
                              return _TeacherLeaveMessage(
                                title: 'Unable to load teacher leaves',
                                message: state.message,
                              );
                            }

                            if (state is StaffLeaveLoaded) {
                              final leaves = state.leaves
                                  .where(isTeacherLeave)
                                  .toList();

                              return _TeacherLeaveContent(
                                leaves: leaves,
                                horizontalPadding: horizontalPadding,
                                onAddLeave: _openAddLeave,
                              );
                            }

                            return const SizedBox.shrink();
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
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.monthLabel,
    required this.canMoveNext,
    required this.onPrevious,
    required this.onNext,
    required this.onCurrentMonth,
  });

  final String monthLabel;
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
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Leave has no salary deduction. Unpaid Leave deducts salary.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
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
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                OutlinedButton.icon(
                  onPressed: onCurrentMonth,
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('Current Month'),
                ),
                IconButton.outlined(
                  tooltip: 'Next Month',
                  onPressed: canMoveNext ? onNext : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [information, const SizedBox(height: 18), controls],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
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

class _TeacherLeaveContent extends StatelessWidget {
  const _TeacherLeaveContent({
    required this.leaves,
    required this.horizontalPadding,
    required this.onAddLeave,
  });

  final List<StaffLeaveEntity> leaves;
  final double horizontalPadding;
  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context) {
    final pending = leaves.where((leave) => leave.isPending).length;

    final approved = leaves.where((leave) => leave.isApproved).toList();

    final unpaid = leaves
        .where((leave) => leave.leaveType == StaffLeaveType.unpaid)
        .length;

    final approvedDays = approved.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 96),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final columns = constraints.maxWidth >= 1100
                ? 4
                : constraints.maxWidth >= 650
                ? 2
                : 1;

            final cardWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'Requests',
                    value: leaves.length.toString(),
                    icon: Icons.event_note_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'Pending',
                    value: pending.toString(),
                    icon: Icons.pending_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'Approved',
                    value: approved.length.toString(),
                    subtitle: '${teacherLeaveDaysLabel(approvedDays)} day(s)',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _SummaryCard(
                    title: 'Unpaid Leave',
                    value: unpaid.toString(),
                    icon: Icons.money_off_csred_outlined,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (leaves.isEmpty)
          _EmptyTeacherLeaveView(onAddLeave: onAddLeave)
        else
          ...leaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TeacherLeaveListItem(leave: leave),
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

class _EmptyTeacherLeaveView extends StatelessWidget {
  const _EmptyTeacherLeaveView({required this.onAddLeave});

  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 68,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No teacher leave requests found',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no teacher leave requests for this month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddLeave,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Teacher Leave'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherLeaveMessage extends StatelessWidget {
  const _TeacherLeaveMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
          ],
        ),
      ),
    );
  }
}
