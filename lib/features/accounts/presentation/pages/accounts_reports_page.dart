import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/services/accounts_report_service.dart';
import '../bloc/accounts_reports_bloc.dart';
import '../bloc/accounts_reports_event.dart';
import '../bloc/accounts_reports_state.dart';

class AccountsReportsPage extends StatelessWidget {
  const AccountsReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountsReportsBloc>(),
      child: const _AccountsReportsView(),
    );
  }
}

class _AccountsReportsView extends StatefulWidget {
  const _AccountsReportsView();

  @override
  State<_AccountsReportsView> createState() => _AccountsReportsViewState();
}

class _AccountsReportsViewState extends State<_AccountsReportsView> {
  AccountsReportType _reportType = AccountsReportType.profitLoss;

  DateTime _fromDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  DateTime _toDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts Reports'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<AccountsReportsBloc, AccountsReportsState>(
        listener: (context, state) {
          if (state is AccountsReportsSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }

          if (state is AccountsReportsFailure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final exporting = state is AccountsReportsExporting;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Financial Reports',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Select a report and date range, then '
                          'generate a PDF or Excel file.',
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<AccountsReportType>(
                          initialValue: _reportType,
                          decoration: const InputDecoration(
                            labelText: 'Report Type',
                          ),
                          items: AccountsReportType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(_title(type)),
                                ),
                              )
                              .toList(),
                          onChanged: exporting
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _reportType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: exporting
                                    ? null
                                    : () => _pickFromDate(context),
                                icon: const Icon(Icons.date_range_outlined),
                                label: Text('From: ${_date(_fromDate)}'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: exporting
                                    ? null
                                    : () => _pickToDate(context),
                                icon: const Icon(Icons.event_outlined),
                                label: Text('To: ${_date(_toDate)}'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        if (exporting) const LinearProgressIndicator(),
                        if (exporting) const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: exporting
                                    ? null
                                    : () => _exportPdf(context),
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('Generate PDF'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                onPressed: exporting
                                    ? null
                                    : () => _exportExcel(context),
                                icon: const Icon(Icons.table_view_outlined),
                                label: const Text('Generate Excel'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final value = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (value != null) {
      setState(() {
        _fromDate = value;
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final value = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: _fromDate,
      lastDate: DateTime(2100),
    );

    if (value != null) {
      setState(() => _toDate = value);
    }
  }

  void _exportPdf(BuildContext context) {
    context.read<AccountsReportsBloc>().add(
      ExportAccountsPdfRequested(
        reportType: _reportType,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  void _exportExcel(BuildContext context) {
    context.read<AccountsReportsBloc>().add(
      ExportAccountsExcelRequested(
        reportType: _reportType,
        fromDate: _fromDate,
        toDate: _toDate,
      ),
    );
  }

  static String _date(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.year}';
  }

  static String _title(AccountsReportType type) {
    switch (type) {
      case AccountsReportType.profitLoss:
        return 'Profit and Loss';
      case AccountsReportType.income:
        return 'Income';
      case AccountsReportType.expenses:
        return 'Expenses';
      case AccountsReportType.payroll:
        return 'Payroll';
      case AccountsReportType.cashbook:
        return 'Cashbook';
    }
  }
}
