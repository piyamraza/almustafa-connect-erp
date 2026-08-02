import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../bloc/income_bloc.dart';
import '../bloc/income_event.dart';
import '../bloc/income_state.dart';

class IncomePage extends StatelessWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<IncomeBloc>()..add(const LoadIncomeEntries()),
      child: const _IncomeView(),
    );
  }
}

class _IncomeView extends StatefulWidget {
  const _IncomeView();

  @override
  State<_IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<_IncomeView> {
  IncomeType? _typeFilter;
  IncomeEntryStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showIncomeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Income'),
      ),
      body: BlocConsumer<IncomeBloc, IncomeState>(
        listener: (context, state) {
          if (state is! IncomeLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is IncomeInitial || state is IncomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is IncomeFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as IncomeLoaded;
          final entries = data.entries.where((entry) {
            final typeMatches =
                _typeFilter == null || entry.incomeType == _typeFilter;
            final statusMatches =
                _statusFilter == null || entry.status == _statusFilter;
            return typeMatches && statusMatches;
          }).toList();

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
                              context.read<IncomeBloc>().add(
                                SyncFeeIncomeRequested(
                                  actorId: user?.uid ?? '',
                                ),
                              );
                            },
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Fee Income'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.account_balance_wallet_outlined),
                      label: Text('Active Income: Rs. ${data.activeTotal}'),
                    ),
                    SizedBox(
                      width: 210,
                      child: DropdownButtonFormField<IncomeType?>(
                        initialValue: _typeFilter,
                        decoration: const InputDecoration(
                          labelText: 'Income Type',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...IncomeType.values.map(
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
                      width: 190,
                      child: DropdownButtonFormField<IncomeEntryStatus?>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...IncomeEntryStatus.values.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_label(item.name)),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No income entries found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(
                                  entry.sourceType ==
                                          IncomeSourceType.feePayment
                                      ? Icons.school_outlined
                                      : Icons.add_card_outlined,
                                ),
                              ),
                              title: Text(entry.description),
                              subtitle: Text(
                                '${_label(entry.incomeType.name)} • '
                                '${entry.studentName.isEmpty ? 'General income' : entry.studentName} • '
                                '${_label(entry.status.name)}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Rs. ${entry.amount}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      decoration: entry.isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  if (entry.isActive &&
                                      entry.sourceType !=
                                          IncomeSourceType.feePayment)
                                    IconButton(
                                      tooltip: 'Reverse',
                                      onPressed: () =>
                                          _showReverseDialog(context, entry),
                                      icon: const Icon(Icons.undo),
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

  Future<void> _showIncomeDialog(BuildContext context) async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final paymentMethodController = TextEditingController(text: 'Cash');
    final referenceController = TextEditingController();
    var incomeType = IncomeType.other;
    var incomeDate = DateTime.now();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Manual Income'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<IncomeType>(
                    initialValue: incomeType,
                    decoration: const InputDecoration(labelText: 'Income Type'),
                    items: IncomeType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_label(item.name)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => incomeType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paymentMethodController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Income Date'),
                    subtitle: Text(
                      '${incomeDate.day}-${incomeDate.month}-${incomeDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: incomeDate,
                      );
                      if (picked != null) {
                        setDialogState(() => incomeDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();
      context.read<IncomeBloc>().add(
        SaveIncomeEntryRequested(
          IncomeEntryEntity(
            id: 'manual_income_${now.microsecondsSinceEpoch}',
            incomeType: incomeType,
            amount: int.tryParse(amountController.text.trim()) ?? 0,
            incomeDate: incomeDate,
            description: descriptionController.text.trim(),
            paymentMethod: paymentMethodController.text.trim(),
            referenceNumber: referenceController.text.trim(),
            studentId: '',
            studentName: '',
            feePaymentId: '',
            enteredBy: user?.uid ?? '',
            createdAt: now,
            updatedAt: now,
            sourceType: IncomeSourceType.manual,
            sourceId: '',
            status: IncomeEntryStatus.active,
          ),
        ),
      );
    }

    amountController.dispose();
    descriptionController.dispose();
    paymentMethodController.dispose();
    referenceController.dispose();
  }

  Future<void> _showReverseDialog(
    BuildContext context,
    IncomeEntryEntity entry,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reverse Income Entry'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason for reversal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reverse'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<IncomeBloc>().add(
        ReverseIncomeEntryRequested(
          incomeEntryId: entry.id,
          reason: reasonController.text.trim(),
        ),
      );
    }
    reasonController.dispose();
  }

  static String _label(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
