import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';

import '../../../../core/di/service_locator.dart';
import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_fee_summary.dart';
import '../../domain/services/parent_fee_service.dart';

class ParentFeePage extends StatefulWidget {
  const ParentFeePage({super.key, required this.student});

  final StudentEntity student;

  @override
  State<ParentFeePage> createState() => _ParentFeePageState();
}

class _ParentFeePageState extends State<ParentFeePage> {
  final ParentFeeService _service = sl<ParentFeeService>();

  ParentFeeSummary? _summary;
  bool _loading = true;
  String? _errorMessage;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final value = await _service.loadStudentFeeSummary(
        studentId: widget.student.id,
        academicSession: '2026-2027',
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

  List<MonthlyFeeDueEntity> get _filteredDues {
    final dues = _summary?.dues ?? const <MonthlyFeeDueEntity>[];

    return dues
        .where((due) {
          return switch (_statusFilter) {
            'paid' => due.status == MonthlyFeeDueStatus.paid,
            'partial' => due.status == MonthlyFeeDueStatus.partiallyPaid,
            'unpaid' => due.status == MonthlyFeeDueStatus.unpaid,
            'overdue' =>
              due.status != MonthlyFeeDueStatus.paid &&
                  due.status != MonthlyFeeDueStatus.cancelled &&
                  due.dueDate.isBefore(DateTime.now()),
            _ => true,
          };
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.student.fullName} Fee Status'),
        actions: const [DashboardNavigationButton()],
      ),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
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
    final dues = _filteredDues;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _FeeAmountSummary(summary: summary),
        const SizedBox(height: 16),
        _FeeStatusSummary(summary: summary),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _statusFilter,
          decoration: const InputDecoration(
            labelText: 'Filter Fee Months',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Months')),
            DropdownMenuItem(value: 'paid', child: Text('Paid')),
            DropdownMenuItem(value: 'partial', child: Text('Partially Paid')),
            DropdownMenuItem(value: 'unpaid', child: Text('Unpaid')),
            DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
          ],
          onChanged: (value) {
            setState(() => _statusFilter = value ?? 'all');
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Monthly Fee History',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (dues.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No fee records match the selected filter.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...dues.map(
            (due) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MonthlyFeeCard(due: due),
            ),
          ),
      ],
    );
  }
}

class _FeeAmountSummary extends StatelessWidget {
  const _FeeAmountSummary({required this.summary});

  final ParentFeeSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Payable', summary.totalPayable, Icons.receipt_long_outlined),
      ('Total Paid', summary.totalPaid, Icons.check_circle_outline),
      ('Outstanding', summary.totalOutstanding, Icons.warning_amber_outlined),
      (
        'Advance Adjusted',
        summary.totalAdvanceAdjusted,
        Icons.savings_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 500
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.3 : 1.9,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(item.$3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _money(item.$2),
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

class _FeeStatusSummary extends StatelessWidget {
  const _FeeStatusSummary({required this.summary});

  final ParentFeeSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Paid Months', summary.paidMonths),
      ('Partial Months', summary.partiallyPaidMonths),
      ('Unpaid Months', summary.unpaidMonths),
      ('Overdue Months', summary.overdueMonths),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => Chip(label: Text('${item.$1}: ${item.$2}')))
          .toList(growable: false),
    );
  }
}

class _MonthlyFeeCard extends StatelessWidget {
  const _MonthlyFeeCard({required this.due});

  final MonthlyFeeDueEntity due;

  @override
  Widget build(BuildContext context) {
    final overdue =
        due.status != MonthlyFeeDueStatus.paid &&
        due.status != MonthlyFeeDueStatus.cancelled &&
        due.dueDate.isBefore(DateTime.now());

    final status = _statusLabel(due.status);

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Text(_monthShort(due.month))),
        title: Text(
          '${_monthName(due.month)} ${due.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Due ${_date(due.dueDate)} | '
          'Outstanding ${_money(due.outstandingAmount)}',
        ),
        trailing: Chip(
          avatar: Icon(
            overdue ? Icons.warning_amber_outlined : _statusIcon(due.status),
            size: 18,
          ),
          label: Text(overdue ? 'OVERDUE' : status),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _FeeLine(label: 'Tuition Fee', value: due.tuitionFee),
          _FeeLine(label: 'Transport Fee', value: due.transportFee),
          _FeeLine(label: 'Other Charges', value: due.otherMonthlyCharges),
          _FeeLine(label: 'Previous Arrears', value: due.previousArrears),
          _FeeLine(label: 'Discount', value: -due.discountAmount),
          _FeeLine(label: 'Scholarship', value: -due.scholarshipAmount),
          _FeeLine(
            label: 'Sibling Discount',
            value: -due.siblingDiscountAmount,
          ),
          _FeeLine(label: 'Advance Adjustment', value: -due.advanceAdjustment),
          const Divider(),
          _FeeLine(label: 'Net Payable', value: due.netPayable, bold: true),
          _FeeLine(label: 'Paid Amount', value: due.paidAmount, bold: true),
          _FeeLine(
            label: 'Outstanding',
            value: due.outstandingAmount,
            bold: true,
          ),
        ],
      ),
    );
  }

  static String _statusLabel(MonthlyFeeDueStatus status) {
    return switch (status) {
      MonthlyFeeDueStatus.paid => 'PAID',
      MonthlyFeeDueStatus.partiallyPaid => 'PARTIAL',
      MonthlyFeeDueStatus.unpaid => 'UNPAID',
      MonthlyFeeDueStatus.cancelled => 'CANCELLED',
    };
  }

  static IconData _statusIcon(MonthlyFeeDueStatus status) {
    return switch (status) {
      MonthlyFeeDueStatus.paid => Icons.check_circle_outline,
      MonthlyFeeDueStatus.partiallyPaid => Icons.timelapse_outlined,
      MonthlyFeeDueStatus.unpaid => Icons.cancel_outlined,
      MonthlyFeeDueStatus.cancelled => Icons.block_outlined,
    };
  }
}

class _FeeLine extends StatelessWidget {
  const _FeeLine({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(_money(value), style: style),
        ],
      ),
    );
  }
}

String _money(double value) {
  final sign = value < 0 ? '-' : '';
  return '${sign}Rs. ${value.abs().toStringAsFixed(0)}';
}

String _date(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _monthName(int month) {
  const names = [
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

  return names[month - 1];
}

String _monthShort(int month) {
  return _monthName(month).substring(0, 3);
}
