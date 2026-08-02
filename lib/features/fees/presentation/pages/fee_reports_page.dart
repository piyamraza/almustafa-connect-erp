import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/fee_report_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../bloc/fee_reports_bloc.dart';
import 'additional_charge_reports_page.dart';

class FeeReportsPage extends StatelessWidget {
  const FeeReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeeReportsBloc>(
      create: (_) => sl<FeeReportsBloc>(),
      child: const _FeeReportsView(),
    );
  }
}

class _FeeReportsView extends StatefulWidget {
  const _FeeReportsView();

  @override
  State<_FeeReportsView> createState() => _FeeReportsViewState();
}

class _FeeReportsViewState extends State<_FeeReportsView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  FeeReportType _type = FeeReportType.collectionSummary;
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<FeeReportsBloc>().add(
      LoadFeeReport(
        type: _type,
        academicSession: _sessionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
  }

  Future<void> _pickDate(bool start) async {
    final value = await showManualDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (value == null) return;

    setState(() {
      if (start) {
        _startDate = value;
      } else {
        _endDate = value;
      }
    });
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Fee Reports')),
      body: SafeArea(
        child: BlocConsumer<FeeReportsBloc, FeeReportsState>(
          listener: (context, state) {
            if (state is FeeReportsLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is FeeReportsError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = state is FeeReportsLoading;
            final report = state is FeeReportsLoaded ? state.report : null;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fee Reports',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    const AdditionalChargeReportsPage(),
                              ),
                            ),
                            icon: const Icon(Icons.add_chart_outlined),
                            label: const Text('Additional Charges Reports'),
                          ),
                          const SizedBox(height: 18),
                          _filters(busy),
                          if (report != null) ...[
                            const SizedBox(height: 14),
                            _summary(report),
                            const SizedBox(height: 14),
                            _details(report),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (busy)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filters(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 270,
              child: DropdownButtonFormField<FeeReportType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: FeeReportType.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(_title(item)),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _pickDate(true),
              icon: const Icon(Icons.date_range),
              label: Text('From: ${_date(_startDate)}'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _pickDate(false),
              icon: const Icon(Icons.event),
              label: Text('To: ${_date(_endDate)}'),
            ),
            FilledButton.icon(
              onPressed: busy ? null : _load,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Load Report'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => context.read<FeeReportsBloc>().add(
                      const PrintLoadedFeeReport(),
                    ),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => context.read<FeeReportsBloc>().add(
                      const ShareLoadedFeeReport(),
                    ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Share PDF'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => context.read<FeeReportsBloc>().add(
                      const ExportLoadedFeeReportExcel(),
                    ),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(FeeReportData report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _chip('Demand', report.totalDemand),
            _chip('Collected', report.totalCollected),
            _chip('Outstanding', report.totalOutstanding),
            _chip('Discounts', report.totalDiscounts),
            _chip('Arrears', report.totalArrears),
            _chip('Advance', report.totalAdvance),
            Chip(label: Text('Paid: ${report.paidCount}')),
            Chip(label: Text('Partial: ${report.partialCount}')),
            Chip(label: Text('Unpaid: ${report.unpaidCount}')),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, double value) {
    return Chip(label: Text('$label: Rs. ${value.toStringAsFixed(0)}'));
  }

  Widget _details(FeeReportData report) {
    if (report.type == FeeReportType.collectionSummary ||
        report.type == FeeReportType.paymentMethods) {
      return _paymentsTable(report.payments);
    }

    final dues = switch (report.type) {
      FeeReportType.outstanding =>
        report.dues.where((item) => item.outstandingAmount > 0).toList(),
      FeeReportType.defaulters =>
        report.dues
            .where(
              (item) =>
                  item.outstandingAmount > 0 &&
                  item.dueDate.isBefore(DateTime.now()),
            )
            .toList(),
      FeeReportType.discounts =>
        report.dues.where((item) => item.totalDeductions > 0).toList(),
      _ => report.dues,
    };

    return _duesTable(dues);
  }

  Widget _paymentsTable(List<FeePaymentEntity> payments) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Receipt')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Admission No.')),
            DataColumn(label: Text('Method')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Advance')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            for (final payment in payments)
              DataRow(
                cells: [
                  DataCell(Text(payment.receiptNumber)),
                  DataCell(Text(_date(payment.paymentDate))),
                  DataCell(Text(payment.studentName)),
                  DataCell(Text(payment.admissionNo)),
                  DataCell(Text(_method(payment.method))),
                  DataCell(Text('Rs. ${payment.totalPaid.toStringAsFixed(0)}')),
                  DataCell(
                    Text('Rs. ${payment.advanceAmount.toStringAsFixed(0)}'),
                  ),
                  DataCell(Text(payment.status.name.toUpperCase())),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _duesTable(List<MonthlyFeeDueEntity> dues) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Admission No.')),
            DataColumn(label: Text('Month')),
            DataColumn(label: Text('Demand')),
            DataColumn(label: Text('Paid')),
            DataColumn(label: Text('Outstanding')),
            DataColumn(label: Text('Discounts')),
            DataColumn(label: Text('Arrears')),
            DataColumn(label: Text('Status')),
          ],
          rows: [
            for (final due in dues)
              DataRow(
                cells: [
                  DataCell(Text(due.studentName)),
                  DataCell(Text(due.admissionNo)),
                  DataCell(Text('${_month(due.month)} ${due.year}')),
                  DataCell(Text('Rs. ${due.netPayable.toStringAsFixed(0)}')),
                  DataCell(Text('Rs. ${due.paidAmount.toStringAsFixed(0)}')),
                  DataCell(
                    Text('Rs. ${due.outstandingAmount.toStringAsFixed(0)}'),
                  ),
                  DataCell(
                    Text('Rs. ${due.totalDeductions.toStringAsFixed(0)}'),
                  ),
                  DataCell(
                    Text('Rs. ${due.previousArrears.toStringAsFixed(0)}'),
                  ),
                  DataCell(Text(due.status.name.toUpperCase())),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static String _title(FeeReportType type) => switch (type) {
    FeeReportType.collectionSummary => 'Collection Summary',
    FeeReportType.outstanding => 'Outstanding Fee',
    FeeReportType.defaulters => 'Defaulters',
    FeeReportType.discounts => 'Discounts & Scholarships',
    FeeReportType.paymentMethods => 'Payment Methods',
    FeeReportType.demandVsCollection => 'Demand vs Collection',
  };

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
