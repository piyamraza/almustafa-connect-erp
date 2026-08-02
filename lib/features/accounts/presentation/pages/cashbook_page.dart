import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/cashbook_entry_entity.dart';
import '../bloc/cashbook_bloc.dart';
import '../bloc/cashbook_event.dart';
import '../bloc/cashbook_state.dart';

class CashbookPage extends StatelessWidget {
  const CashbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CashbookBloc>()..add(const LoadCashbook()),
      child: const _CashbookView(),
    );
  }
}

class _CashbookView extends StatefulWidget {
  const _CashbookView();

  @override
  State<_CashbookView> createState() => _CashbookViewState();
}

class _CashbookViewState extends State<_CashbookView> {
  CashbookEntryType? _typeFilter;
  String? _paymentMethodFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbook'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<CashbookBloc, CashbookState>(
        listener: (context, state) {
          if (state is! CashbookLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is CashbookInitial || state is CashbookLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CashbookFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as CashbookLoaded;
          final methods =
              data.entries
                  .map((entry) => entry.paymentMethod)
                  .where((method) => method.trim().isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();

          final filtered = data.entries.where((entry) {
            final typeMatches =
                _typeFilter == null || entry.entryType == _typeFilter;
            final methodMatches =
                _paymentMethodFilter == null ||
                entry.paymentMethod == _paymentMethodFilter;
            final fromMatches =
                _fromDate == null || !entry.entryDate.isBefore(_fromDate!);
            final toBoundary = _toDate == null
                ? null
                : DateTime(_toDate!.year, _toDate!.month, _toDate!.day + 1);
            final toMatches =
                toBoundary == null || entry.entryDate.isBefore(toBoundary);

            return typeMatches && methodMatches && fromMatches && toMatches;
          }).toList();

          var runningBalance = 0;

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: data.isProcessing
                          ? null
                          : () {
                              final user = sl<GetCurrentUserUseCase>()();
                              context.read<CashbookBloc>().add(
                                SyncCashbookRequested(actorId: user?.uid ?? ''),
                              );
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Cashbook'),
                    ),
                    _SummaryChip(
                      label: 'Income',
                      value: data.totalIncome,
                      icon: Icons.south_west,
                    ),
                    _SummaryChip(
                      label: 'Expense',
                      value: data.totalExpense,
                      icon: Icons.north_east,
                    ),
                    _SummaryChip(
                      label: 'Balance',
                      value: data.closingBalance,
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<CashbookEntryType?>(
                        initialValue: _typeFilter,
                        decoration: const InputDecoration(
                          labelText: 'Entry Type',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...CashbookEntryType.values.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_label(item.name)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _typeFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<String?>(
                        initialValue: _paymentMethodFilter,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Methods'),
                          ),
                          ...methods.map(
                            (method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _paymentMethodFilter = value),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickFromDate(context),
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                        _fromDate == null
                            ? 'From Date'
                            : _formatDate(_fromDate!),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickToDate(context),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _toDate == null ? 'To Date' : _formatDate(_toDate!),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _typeFilter = null;
                          _paymentMethodFilter = null;
                          _fromDate = null;
                          _toDate = null;
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No cashbook entries found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          runningBalance +=
                              entry.entryType == CashbookEntryType.income
                              ? entry.amount
                              : -entry.amount;

                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(
                                entry.entryType == CashbookEntryType.income
                                    ? Icons.south_west
                                    : Icons.north_east,
                              ),
                            ),
                            title: Text(entry.description),
                            subtitle: Text(
                              '${_formatDate(entry.entryDate)} • '
                              '${entry.paymentMethod.isEmpty ? 'Unspecified' : entry.paymentMethod} • '
                              '${entry.sourceType}',
                            ),
                            trailing: SizedBox(
                              width: 210,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    entry.entryType == CashbookEntryType.income
                                        ? '+ Rs. ${entry.amount}'
                                        : '- Rs. ${entry.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Text(
                                    'Bal. $runningBalance',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _fromDate = picked);
    }
  }

  Future<void> _pickToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }

  static String _label(String value) {
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: Rs. $value'),
    );
  }
}
