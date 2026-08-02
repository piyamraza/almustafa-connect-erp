import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_salary_entity.dart';
import '../bloc/staff_salary_bloc.dart';
import '../bloc/staff_salary_event.dart';
import '../bloc/staff_salary_state.dart';
import '../widgets/staff_salary_adjustment_form.dart';
import 'staff_salary_slip_page.dart';

class StaffSalaryDetailsPage extends StatelessWidget {
  const StaffSalaryDetailsPage({
    required this.salary,
    super.key,
  });

  final StaffSalaryEntity salary;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffSalaryBloc>(
      create: (_) => sl<StaffSalaryBloc>(),
      child: _StaffSalaryDetailsView(
        initialSalary: salary,
      ),
    );
  }
}

class _StaffSalaryDetailsView extends StatefulWidget {
  const _StaffSalaryDetailsView({
    required this.initialSalary,
  });

  final StaffSalaryEntity initialSalary;

  @override
  State<_StaffSalaryDetailsView> createState() =>
      _StaffSalaryDetailsViewState();
}

class _StaffSalaryDetailsViewState
    extends State<_StaffSalaryDetailsView> {
  late StaffSalaryEntity _salary;
  late StaffSalaryPaymentStatus _paymentStatus;
  StaffSalaryPaymentMethod? _paymentMethod;
  DateTime? _paymentDate;

  late final TextEditingController
      _paymentReferenceController;

  bool _isSavingAdjustments = false;
  bool _isUpdatingPayment = false;

  @override
  void initState() {
    super.initState();

    _salary = widget.initialSalary;
    _paymentStatus = _salary.paymentStatus;
    _paymentMethod = _salary.paymentMethod;
    _paymentDate = _salary.paymentDate;
    _paymentReferenceController = TextEditingController(
      text: _salary.paymentReference,
    );
  }

  @override
  void dispose() {
    _paymentReferenceController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final amount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return 'Rs. $amount';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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

  String _paymentMethodLabel(
    StaffSalaryPaymentMethod method,
  ) {
    switch (method) {
      case StaffSalaryPaymentMethod.cash:
        return 'Cash';
      case StaffSalaryPaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case StaffSalaryPaymentMethod.easypaisa:
        return 'Easypaisa';
      case StaffSalaryPaymentMethod.jazzCash:
        return 'JazzCash';
      case StaffSalaryPaymentMethod.cheque:
        return 'Cheque';
      case StaffSalaryPaymentMethod.other:
        return 'Other';
    }
  }

  Future<void> _saveAdjustments(
    StaffSalaryAdjustmentData data,
  ) async {
    if (_isSavingAdjustments) {
      return;
    }

    setState(() {
      _isSavingAdjustments = true;
    });

    final grossSalary =
        _salary.basicSalary + data.allowance;
    final calculatedNetSalary = grossSalary -
        data.deduction -
        data.attendanceDeduction;
    final netSalary =
        calculatedNetSalary < 0 ? 0.0 : calculatedNetSalary;

    final updatedSalary = _salary.copyWith(
      allowance: data.allowance,
      deduction: data.deduction,
      attendanceDeduction: data.attendanceDeduction,
      grossSalary: grossSalary,
      netSalary: netSalary,
      remarks: data.remarks,
      updatedAt: DateTime.now(),
    );

    context.read<StaffSalaryBloc>().add(
          SaveStaffSalaryAdjustmentsEvent(
            updatedSalary,
          ),
        );
  }

  Future<void> _pickPaymentDate() async {
    final selectedDate = await showManualDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: _salary.salaryMonth,
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
      helpText: 'Select payment date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _paymentDate = selectedDate;
    });
  }

  void _updatePaymentStatus() {
    if (_isUpdatingPayment) {
      return;
    }

    if (_paymentStatus ==
        StaffSalaryPaymentStatus.paid) {
      if (_paymentDate == null) {
        _showMessage('Please select payment date.');
        return;
      }

      if (_paymentMethod == null) {
        _showMessage('Please select payment method.');
        return;
      }
    }

    setState(() {
      _isUpdatingPayment = true;
    });

    context.read<StaffSalaryBloc>().add(
          UpdateStaffSalaryPaymentStatusEvent(
            salaryId: _salary.id,
            salaryMonth: _salary.salaryMonth,
            paymentStatus: _paymentStatus,
            paymentDate: _paymentStatus ==
                    StaffSalaryPaymentStatus.paid
                ? _paymentDate
                : null,
            paymentMethod: _paymentStatus ==
                    StaffSalaryPaymentStatus.paid
                ? _paymentMethod
                : null,
            paymentReference:
                _paymentReferenceController.text.trim(),
          ),
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _handleState(
    BuildContext context,
    StaffSalaryState state,
  ) {
    if (state is StaffSalaryError) {
      setState(() {
        _isSavingAdjustments = false;
        _isUpdatingPayment = false;
      });

      _showMessage(state.message);
      return;
    }

    if (state is StaffSalaryLoaded &&
        state.successMessage != null) {
      StaffSalaryEntity? updatedSalary;

      for (final salary in state.salaries) {
        if (salary.id == _salary.id) {
          updatedSalary = salary;
          break;
        }
      }

      setState(() {
        if (updatedSalary != null) {
          _salary = updatedSalary;
          _paymentStatus = updatedSalary.paymentStatus;
          _paymentMethod = updatedSalary.paymentMethod;
          _paymentDate = updatedSalary.paymentDate;
          _paymentReferenceController.text =
              updatedSalary.paymentReference;
        }

        _isSavingAdjustments = false;
        _isUpdatingPayment = false;
      });

      _showMessage(state.successMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffSalaryBloc, StaffSalaryState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Salary Details'),
          actions: [const DashboardNavigationButton(),
            IconButton(
              tooltip: 'Print Salary Slip',
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => StaffSalarySlipPage(
                      salary: _salary,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.print_outlined,
              ),
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
                    maxWidth: 1100,
                  ),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      32,
                    ),
                    children: [
                      _SalaryHeader(
                        salary: _salary,
                        monthLabel:
                            _formatMonth(_salary.salaryMonth),
                        netSalary:
                            _formatCurrency(_salary.netSalary),
                      ),
                      const SizedBox(height: 18),
                      _SalaryBreakdown(
                        salary: _salary,
                        formatCurrency: _formatCurrency,
                      ),
                      const SizedBox(height: 18),
                      _AttendanceSummary(
                        salary: _salary,
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Salary Adjustments',
                        subtitle:
                            'Update allowance, deductions and remarks.',
                        child: StaffSalaryAdjustmentForm(
                          key: ValueKey(
                            '${_salary.id}_${_salary.updatedAt.millisecondsSinceEpoch}',
                          ),
                          initialAllowance: _salary.allowance,
                          initialDeduction: _salary.deduction,
                          initialAttendanceDeduction:
                              _salary.attendanceDeduction,
                          initialRemarks: _salary.remarks,
                          isSaving: _isSavingAdjustments,
                          onSubmit: _saveAdjustments,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SectionCard(
                        title: 'Payment Status',
                        subtitle:
                            'Record salary payment information.',
                        child: _PaymentForm(
                          paymentStatus: _paymentStatus,
                          paymentMethod: _paymentMethod,
                          paymentDateLabel:
                              _paymentDate == null
                                  ? 'Select payment date'
                                  : _formatDate(_paymentDate!),
                          referenceController:
                              _paymentReferenceController,
                          isSaving: _isUpdatingPayment,
                          paymentMethodLabel:
                              _paymentMethodLabel,
                          onStatusChanged: (status) {
                            setState(() {
                              _paymentStatus = status;

                              if (status ==
                                  StaffSalaryPaymentStatus
                                      .unpaid) {
                                _paymentDate = null;
                                _paymentMethod = null;
                              }
                            });
                          },
                          onMethodChanged: (method) {
                            setState(() {
                              _paymentMethod = method;
                            });
                          },
                          onPickDate: _pickPaymentDate,
                          onSubmit: _updatePaymentStatus,
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

class _SalaryHeader extends StatelessWidget {
  const _SalaryHeader({
    required this.salary,
    required this.monthLabel,
    required this.netSalary,
  });

  final StaffSalaryEntity salary;
  final String monthLabel;
  final String netSalary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        salary.isPaid ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;

            final information = Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 34,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        salary.staffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${salary.staffCode} â€¢ '
                        '${salary.designation}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        monthLabel,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(
                          color: theme
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final amount = Column(
              crossAxisAlignment: isCompact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Text(
                  'Net Salary',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  netSalary,
                  style:
                      theme.textTheme.headlineSmall?.copyWith(
                    color: theme
                        .colorScheme
                        .onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Chip(
                  label: Text(
                    salary.isPaid ? 'Paid' : 'Unpaid',
                  ),
                  side: BorderSide.none,
                  backgroundColor:
                      statusColor.withValues(alpha: 0.14),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 18),
                  amount,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                amount,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SalaryBreakdown extends StatelessWidget {
  const _SalaryBreakdown({
    required this.salary,
    required this.formatCurrency,
  });

  final StaffSalaryEntity salary;
  final String Function(double value) formatCurrency;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Salary Breakdown',
      subtitle:
          'Complete calculation for this salary record.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final columns = constraints.maxWidth >= 850
              ? 3
              : constraints.maxWidth >= 500
                  ? 2
                  : 1;
          final itemWidth =
              (constraints.maxWidth -
                  spacing * (columns - 1)) /
              columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _AmountTile(
                width: itemWidth,
                label: 'Basic Salary',
                value: formatCurrency(
                  salary.basicSalary,
                ),
                icon: Icons.account_balance_wallet_outlined,
              ),
              _AmountTile(
                width: itemWidth,
                label: 'Allowance',
                value: formatCurrency(
                  salary.allowance,
                ),
                icon: Icons.add_circle_outline,
                iconColor: Colors.green,
              ),
              _AmountTile(
                width: itemWidth,
                label: 'Gross Salary',
                value: formatCurrency(
                  salary.grossSalary,
                ),
                icon: Icons.calculate_outlined,
              ),
              _AmountTile(
                width: itemWidth,
                label: 'Other Deduction',
                value: formatCurrency(
                  salary.deduction,
                ),
                icon: Icons.remove_circle_outline,
                iconColor: Colors.red,
              ),
              _AmountTile(
                width: itemWidth,
                label: 'Attendance Deduction',
                value: formatCurrency(
                  salary.attendanceDeduction,
                ),
                icon: Icons.event_busy_outlined,
                iconColor: Colors.orange,
              ),
              _AmountTile(
                width: itemWidth,
                label: 'Net Salary',
                value: formatCurrency(
                  salary.netSalary,
                ),
                icon: Icons.payments_outlined,
                iconColor:
                    Theme.of(context).colorScheme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({
    required this.salary,
  });

  final StaffSalaryEntity salary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Attendance Summary',
      subtitle:
          '${salary.totalMarkedDays} attendance record'
          '${salary.totalMarkedDays == 1 ? '' : 's'}',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final columns = constraints.maxWidth >= 700
              ? 4
              : constraints.maxWidth >= 400
                  ? 2
                  : 1;
          final itemWidth =
              (constraints.maxWidth -
                  spacing * (columns - 1)) /
              columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _StatusTile(
                width: itemWidth,
                label: 'Present',
                value: salary.presentDays,
                color: Colors.green,
              ),
              _StatusTile(
                width: itemWidth,
                label: 'Absent',
                value: salary.absentDays,
                color: Colors.red,
              ),
              _StatusTile(
                width: itemWidth,
                label: 'Late',
                value: salary.lateDays,
                color: Colors.blue,
              ),
              _StatusTile(
                width: itemWidth,
                label: 'Leave',
                value: salary.leaveDays,
                color: Colors.orange,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaymentForm extends StatelessWidget {
  const _PaymentForm({
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentDateLabel,
    required this.referenceController,
    required this.isSaving,
    required this.paymentMethodLabel,
    required this.onStatusChanged,
    required this.onMethodChanged,
    required this.onPickDate,
    required this.onSubmit,
  });

  final StaffSalaryPaymentStatus paymentStatus;
  final StaffSalaryPaymentMethod? paymentMethod;
  final String paymentDateLabel;
  final TextEditingController referenceController;
  final bool isSaving;
  final String Function(StaffSalaryPaymentMethod method)
      paymentMethodLabel;
  final ValueChanged<StaffSalaryPaymentStatus>
      onStatusChanged;
  final ValueChanged<StaffSalaryPaymentMethod?>
      onMethodChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isPaid =
        paymentStatus == StaffSalaryPaymentStatus.paid;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final useTwoColumns = constraints.maxWidth >= 700;
        final fieldWidth = useTwoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<
                      StaffSalaryPaymentStatus>(
                    initialValue: paymentStatus,
                    decoration: const InputDecoration(
                      labelText: 'Payment Status',
                      prefixIcon:
                          Icon(Icons.task_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        StaffSalaryPaymentStatus.values.map(
                      (status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(
                            status ==
                                    StaffSalaryPaymentStatus
                                        .paid
                                ? 'Paid'
                                : 'Unpaid',
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: isSaving
                        ? null
                        : (status) {
                            if (status != null) {
                              onStatusChanged(status);
                            }
                          },
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<
                      StaffSalaryPaymentMethod>(
                    initialValue: paymentMethod,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon:
                          Icon(Icons.account_balance_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items:
                        StaffSalaryPaymentMethod.values.map(
                      (method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(
                            paymentMethodLabel(method),
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: !isPaid || isSaving
                        ? null
                        : onMethodChanged,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: OutlinedButton.icon(
                    onPressed:
                        !isPaid || isSaving
                            ? null
                            : onPickDate,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                    ),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                      ),
                      child: Text(paymentDateLabel),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: TextFormField(
                    controller: referenceController,
                    enabled: isPaid && !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Payment Reference',
                      hintText:
                          'Transaction, cheque or voucher no.',
                      prefixIcon:
                          Icon(Icons.receipt_long_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isSaving
                      ? 'Updating...'
                      : 'Update Payment',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _AmountTile extends StatelessWidget {
  const _AmountTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor =
        iconColor ?? theme.colorScheme.primary;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: effectiveColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color:
                        theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}