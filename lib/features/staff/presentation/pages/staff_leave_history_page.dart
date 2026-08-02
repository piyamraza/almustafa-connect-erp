import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_list_item.dart';
import '../widgets/staff_leave_summary_card.dart';

class StaffLeaveHistoryPage extends StatelessWidget {
  const StaffLeaveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _StaffLeaveHistoryView(),
    );
  }
}

class _StaffLeaveHistoryView extends StatefulWidget {
  const _StaffLeaveHistoryView();

  @override
  State<_StaffLeaveHistoryView> createState() =>
      _StaffLeaveHistoryViewState();
}

class _StaffLeaveHistoryViewState
    extends State<_StaffLeaveHistoryView> {
  late final Future<List<StaffEntity>> _staffFuture;

  StaffEntity? _selectedStaff;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(now.year, 1, 1);
    _endDate = DateTime(now.year, 12, 31);
    _staffFuture = _loadStaff();
  }

  Future<List<StaffEntity>> _loadStaff() async {
    final staff = await sl<StaffRepository>().getStaff();

    staff.sort(
      (first, second) => first.fullName
          .toLowerCase()
          .compareTo(second.fullName.toLowerCase()),
    );

    return staff;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _loadHistory() {
    final selectedStaff = _selectedStaff;

    if (selectedStaff == null) {
      return;
    }

    context.read<StaffLeaveBloc>().add(
          LoadStaffLeaveHistoryEvent(
            staffId: selectedStaff.id,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      helpText: 'Select history start date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });

    _loadHistory();
  }

  Future<void> _pickEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(
        DateTime.now().year + 2,
        12,
        31,
      ),
      helpText: 'Select history end date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
    });

    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Leave History'),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Refresh',
            onPressed:
                _selectedStaff == null ? null : _loadHistory,
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth >= 1200
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
                        18,
                      ),
                      child: _HistoryFilters(
                        staffFuture: _staffFuture,
                        selectedStaff: _selectedStaff,
                        startDateLabel:
                            _formatDate(_startDate),
                        endDateLabel: _formatDate(_endDate),
                        onStaffChanged: (staff) {
                          setState(() {
                            _selectedStaff = staff;
                          });

                          _loadHistory();
                        },
                        onPickStartDate: _pickStartDate,
                        onPickEndDate: _pickEndDate,
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<
                          StaffLeaveBloc,
                          StaffLeaveState>(
                        builder: (context, state) {
                          if (_selectedStaff == null) {
                            return const _SelectStaffView();
                          }

                          if (state is StaffLeaveLoading) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (state is StaffLeaveError) {
                            return _HistoryError(
                              message: state.message,
                              onRetry: _loadHistory,
                            );
                          }

                          if (state is StaffLeaveLoaded) {
                            return _HistoryContent(
                              leaves: state.leaves,
                              horizontalPadding:
                                  horizontalPadding,
                            );
                          }

                          return const _SelectStaffView();
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters({
    required this.staffFuture,
    required this.selectedStaff,
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onStaffChanged,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  final Future<List<StaffEntity>> staffFuture;
  final StaffEntity? selectedStaff;
  final String startDateLabel;
  final String endDateLabel;
  final ValueChanged<StaffEntity?> onStaffChanged;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;

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
            const spacing = 14.0;
            final columns =
                constraints.maxWidth >= 850 ? 3 : 1;
            final fieldWidth =
                (constraints.maxWidth -
                    spacing * (columns - 1)) /
                columns;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Leave History Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select staff member and date range.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child:
                          FutureBuilder<List<StaffEntity>>(
                        future: staffFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Staff Member',
                                border: OutlineInputBorder(),
                              ),
                              child:
                                  LinearProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return const InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Staff Member',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                'Unable to load staff',
                              ),
                            );
                          }

                          return DropdownButtonFormField<
                              StaffEntity>(
                            initialValue: selectedStaff,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Staff Member',
                              prefixIcon: Icon(
                                Icons.person_search_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: (snapshot.data ??
                                    const <StaffEntity>[])
                                .map((staffMember) {
                              return DropdownMenuItem(
                                value: staffMember,
                                child: Text(
                                  '${staffMember.fullName} '
                                  '(${staffMember.staffId})',
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
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
                        onPressed: onPickStartDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'From: $startDateLabel',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: onPickEndDate,
                        icon: const Icon(
                          Icons.event_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'To: $endDateLabel',
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

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.leaves,
    required this.horizontalPadding,
  });

  final List<StaffLeaveEntity> leaves;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final approved = leaves
        .where((leave) => leave.isApproved)
        .toList();
    final rejected = leaves
        .where((leave) => leave.isRejected)
        .toList();
    final pending = leaves
        .where((leave) => leave.isPending)
        .toList();

    final approvedDays = approved.fold<double>(
      0,
      (total, leave) => total + leave.totalDays,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        32,
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 14.0;
            final columns =
                constraints.maxWidth >= 900 ? 4 : 2;
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
                  child: StaffLeaveSummaryCard(
                    title: 'Leave Requests',
                    value: leaves.length.toString(),
                    icon: Icons.event_note_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffLeaveSummaryCard(
                    title: 'Approved',
                    value: approved.length.toString(),
                    subtitle:
                        '${approvedDays.toStringAsFixed(
                      approvedDays ==
                              approvedDays.roundToDouble()
                          ? 0
                          : 1,
                    )} day(s)',
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
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
          const _EmptyHistory()
        else
          ...leaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaffLeaveListItem(
                leave: leave,
              ),
            ),
          ),
      ],
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a staff member to view leave history.',
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

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
              Icons.event_available_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No leave history found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No leave requests exist for the selected period.',
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

class _HistoryError extends StatelessWidget {
  const _HistoryError({
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
              'Unable to load leave history',
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
    );
  }
}