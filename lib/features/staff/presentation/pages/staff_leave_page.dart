import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_list_item.dart';
import '../widgets/staff_leave_summary_card.dart';
import 'add_staff_leave_page.dart';
import 'staff_leave_approval_page.dart';
import 'staff_leave_history_page.dart';
import 'staff_leave_report_page.dart';

class StaffLeavePage extends StatelessWidget {
  const StaffLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _StaffLeaveView(),
    );
  }
}

class _StaffLeaveView extends StatefulWidget {
  const _StaffLeaveView();

  @override
  State<_StaffLeaveView> createState() => _StaffLeaveViewState();
}

class _StaffLeaveViewState extends State<_StaffLeaveView> {
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

  String _formatMonth(DateTime date) {
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

  void _loadMonth() {
    context.read<StaffLeaveBloc>().add(
      LoadStaffLeavesByDateRangeEvent(
        startDate: _selectedMonth,
        endDate: _monthEnd,
      ),
    );
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });

    _loadMonth();
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
    });

    _loadMonth();
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });

    _loadMonth();
  }

  Future<void> _openAddLeave() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddStaffLeavePage()),
    );

    if (saved == true && mounted) {
      _loadMonth();
    }
  }

  Future<void> _openApprovals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StaffLeaveApprovalPage()),
    );

    if (mounted) {
      _loadMonth();
    }
  }

  void _openLeaveReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StaffLeaveReportPage()),
    );
  }

  void _openHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StaffLeaveHistoryPage()),
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
      return;
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
          title: const Text('Staff Leave Management'),
          actions: [const DashboardNavigationButton(),
            IconButton(
              tooltip: 'Leave Report',
              onPressed: _openLeaveReport,
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
          label: const Text('Add Leave'),
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
                          monthLabel: _formatMonth(_selectedMonth),
                          canMoveNext: _canMoveNext,
                          onPrevious: _showPreviousMonth,
                          onNext: _showNextMonth,
                          onCurrentMonth: _showCurrentMonth,
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
                              return _LeaveError(
                                message: state.message,
                                onRetry: _loadMonth,
                              );
                            }

                            if (state is StaffLeaveLoaded) {
                              return _LeaveContent(
                                leaves: state.leaves,
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
                  'Create, approve and review staff leave requests.',
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

class _LeaveContent extends StatelessWidget {
  const _LeaveContent({
    required this.leaves,
    required this.horizontalPadding,
    required this.onAddLeave,
  });

  final List<StaffLeaveEntity> leaves;
  final double horizontalPadding;
  final VoidCallback onAddLeave;

  @override
  Widget build(BuildContext context) {
    final pending = leaves.where((leave) => leave.isPending).toList();
    final approved = leaves.where((leave) => leave.isApproved).toList();
    final rejected = leaves.where((leave) => leave.isRejected).toList();

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
                  child: StaffLeaveSummaryCard(
                    title: 'Leave Requests',
                    value: leaves.length.toString(),
                    icon: Icons.event_note_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Pending',
                    value: pending.length.toString(),
                    icon: Icons.pending_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Approved',
                    value: approved.length.toString(),
                    subtitle:
                        '${approvedDays.toStringAsFixed(approvedDays == approvedDays.roundToDouble() ? 0 : 1)} day(s)',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Rejected',
                    value: rejected.length.toString(),
                    icon: Icons.cancel_outlined,
                    iconColor: Colors.red,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (leaves.isEmpty)
          _EmptyLeaveView(onAddLeave: onAddLeave)
        else
          ...leaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaffLeaveListItem(leave: leave),
            ),
          ),
      ],
    );
  }
}

class _EmptyLeaveView extends StatelessWidget {
  const _EmptyLeaveView({required this.onAddLeave});

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
              'No leave requests found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no leave requests for this month.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddLeave,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Leave'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaveError extends StatelessWidget {
  const _LeaveError({required this.message, required this.onRetry});

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
              'Unable to load staff leaves',
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
