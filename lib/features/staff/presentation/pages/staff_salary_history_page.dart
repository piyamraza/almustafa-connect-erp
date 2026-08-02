import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_salary_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_salary_bloc.dart';
import '../bloc/staff_salary_event.dart';
import '../bloc/staff_salary_state.dart';
import '../widgets/staff_salary_list_item.dart';
import '../widgets/staff_salary_summary_card.dart';
import 'staff_salary_details_page.dart';

class StaffSalaryHistoryPage extends StatelessWidget {
  const StaffSalaryHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffSalaryBloc>(
      create: (_) => sl<StaffSalaryBloc>(),
      child: const _StaffSalaryHistoryView(),
    );
  }
}

class _StaffSalaryHistoryView extends StatefulWidget {
  const _StaffSalaryHistoryView();

  @override
  State<_StaffSalaryHistoryView> createState() =>
      _StaffSalaryHistoryViewState();
}

class _StaffSalaryHistoryViewState
    extends State<_StaffSalaryHistoryView> {
  late final Future<List<StaffEntity>> _staffFuture;

  StaffEntity? _selectedStaff;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _startDate = DateTime(
      now.year - 1,
      now.month,
      1,
    );
    _endDate = DateTime(
      now.year,
      now.month,
      1,
    );
    _staffFuture = sl<StaffRepository>().getStaff();
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatCurrency(double value) {
    final amount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return 'Rs. $amount';
  }

  void _loadHistory() {
    final selectedStaff = _selectedStaff;

    if (selectedStaff == null) {
      return;
    }

    context.read<StaffSalaryBloc>().add(
          LoadStaffSalaryHistoryEvent(
            staffId: selectedStaff.id,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  Future<void> _pickStartMonth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      helpText: 'Select start month',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        1,
      );
    });

    _loadHistory();
  }

  Future<void> _pickEndMonth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
      helpText: 'Select end month',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        1,
      );
    });

    _loadHistory();
  }

  Future<void> _openDetails(
    StaffSalaryEntity salary,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StaffSalaryDetailsPage(
          salary: salary,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Salary History'),
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
                        startMonth:
                            _formatMonth(_startDate),
                        endMonth: _formatMonth(_endDate),
                        onStaffChanged: (staff) {
                          setState(() {
                            _selectedStaff = staff;
                          });
                          _loadHistory();
                        },
                        onPickStartMonth: _pickStartMonth,
                        onPickEndMonth: _pickEndMonth,
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<
                          StaffSalaryBloc,
                          StaffSalaryState>(
                        builder: (context, state) {
                          if (_selectedStaff == null) {
                            return const _SelectStaffView();
                          }

                          if (state is StaffSalaryLoading) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (state is StaffSalaryError) {
                            return _HistoryErrorView(
                              message: state.message,
                              onRetry: _loadHistory,
                            );
                          }

                          if (state is StaffSalaryLoaded) {
                            return _HistoryContent(
                              salaries: state.salaries,
                              horizontalPadding:
                                  horizontalPadding,
                              formatCurrency:
                                  _formatCurrency,
                              onOpenDetails: _openDetails,
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
    required this.startMonth,
    required this.endMonth,
    required this.onStaffChanged,
    required this.onPickStartMonth,
    required this.onPickEndMonth,
  });

  final Future<List<StaffEntity>> staffFuture;
  final StaffEntity? selectedStaff;
  final String startMonth;
  final String endMonth;
  final ValueChanged<StaffEntity?> onStaffChanged;
  final VoidCallback onPickStartMonth;
  final VoidCallback onPickEndMonth;

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
                  'Salary History Filters',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Select staff member and salary period.',
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
                              child: LinearProgressIndicator(),
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

                          final staff = List<StaffEntity>.from(
                            snapshot.data ??
                                const <StaffEntity>[],
                          )..sort(
                              (first, second) =>
                                  first.fullName
                                      .toLowerCase()
                                      .compareTo(
                                        second.fullName
                                            .toLowerCase(),
                                      ),
                            );

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
                            items: staff.map((staffMember) {
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
                        onPressed: onPickStartMonth,
                        icon: const Icon(
                          Icons.calendar_month_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'From: $startMonth',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: OutlinedButton.icon(
                        onPressed: onPickEndMonth,
                        icon: const Icon(
                          Icons.event_outlined,
                        ),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 17,
                          ),
                          child: Text(
                            'To: $endMonth',
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
    required this.salaries,
    required this.horizontalPadding,
    required this.formatCurrency,
    required this.onOpenDetails,
  });

  final List<StaffSalaryEntity> salaries;
  final double horizontalPadding;
  final String Function(double value) formatCurrency;
  final ValueChanged<StaffSalaryEntity> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final paidSalaries = salaries
        .where((salary) => salary.isPaid)
        .toList();
    final unpaidSalaries = salaries
        .where((salary) => !salary.isPaid)
        .toList();

    final paidAmount = paidSalaries.fold<double>(
      0,
      (total, salary) => total + salary.netSalary,
    );
    final outstandingAmount = unpaidSalaries.fold<double>(
      0,
      (total, salary) => total + salary.netSalary,
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
                  child: StaffSalarySummaryCard(
                    title: 'Salary Records',
                    value: salaries.length.toString(),
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffSalarySummaryCard(
                    title: 'Paid Records',
                    value:
                        paidSalaries.length.toString(),
                    icon: Icons.check_circle_outline,
                    iconColor: Colors.green,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffSalarySummaryCard(
                    title: 'Paid Amount',
                    value: formatCurrency(paidAmount),
                    icon: Icons.payments_outlined,
                    iconColor: Colors.blue,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: StaffSalarySummaryCard(
                    title: 'Outstanding',
                    value:
                        formatCurrency(outstandingAmount),
                    icon: Icons.pending_actions_outlined,
                    iconColor: Colors.orange,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        if (salaries.isEmpty)
          const _EmptyHistoryView()
        else
          ...salaries.map(
            (salary) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StaffSalaryListItem(
                salary: salary,
                onTap: () => onOpenDetails(salary),
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
              'Select a staff member to view salary history.',
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
              Icons.receipt_long_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No salary history found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no salary records for the selected period.',
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
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load salary history',
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
    );
  }
}