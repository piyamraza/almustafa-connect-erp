import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';

class ParentFeePortalPage extends StatefulWidget {
  const ParentFeePortalPage({
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    super.key,
  });

  final String studentId;
  final String studentName;
  final String admissionNo;

  @override
  State<ParentFeePortalPage> createState() => _ParentFeePortalPageState();
}

class _ParentFeePortalPageState extends State<ParentFeePortalPage> {
  List<MonthlyFeeDueEntity> _dues = const [];
  List<FeePaymentEntity> _payments = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object?>([
        sl<MonthlyFeeDueRepository>().getMonthlyDues(
          studentId: widget.studentId,
        ),
        sl<FeePaymentRepository>().getPayments(studentId: widget.studentId),
      ]);

      if (!mounted) return;

      setState(() {
        _dues = values[0] as List<MonthlyFeeDueEntity>;
        _payments = values[1] as List<FeePaymentEntity>;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  double get _outstanding =>
      _dues.fold<double>(0, (sum, item) => sum + item.outstandingAmount);

  MonthlyFeeDueEntity? get _currentDue {
    final now = DateTime.now();
    for (final due in _dues) {
      if (due.month == now.month && due.year == now.year) {
        return due;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Status')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.admissionNo),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Chip(
                                label: Text(
                                  'Outstanding: Rs. ${_outstanding.toStringAsFixed(0)}',
                                ),
                              ),
                              if (_currentDue != null)
                                Chip(
                                  label: Text(
                                    'Current Month: ${_currentDue!.status.name.toUpperCase()}',
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Monthly Fee Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final due in _dues)
                    Card(
                      child: ListTile(
                        title: Text('${_month(due.month)} ${due.year}'),
                        subtitle: Text(
                          'Due ${_date(due.dueDate)} • '
                          'Paid Rs. ${due.paidAmount.toStringAsFixed(0)} • '
                          'Outstanding Rs. ${due.outstandingAmount.toStringAsFixed(0)}',
                        ),
                        trailing: Chip(
                          label: Text(due.status.name.toUpperCase()),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text(
                    'Payment History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_payments.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('No payment history available.'),
                      ),
                    )
                  else
                    for (final payment in _payments)
                      Card(
                        child: ListTile(
                          title: Text(payment.receiptNumber),
                          subtitle: Text(
                            '${_date(payment.paymentDate)} • '
                            '${_method(payment.method)}',
                          ),
                          trailing: Text(
                            'Rs. ${payment.totalPaid.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }

  static String _method(FeePaymentMethod method) => switch (method) {
    FeePaymentMethod.cash => 'Cash',
    FeePaymentMethod.bankTransfer => 'Bank Transfer',
    FeePaymentMethod.easypaisa => 'Easypaisa',
    FeePaymentMethod.jazzCash => 'JazzCash',
  };

  static String _month(int month) => const [
    '',
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
  ][month];

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
