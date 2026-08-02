import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../bloc/profit_loss_bloc.dart';
import '../bloc/profit_loss_event.dart';
import '../bloc/profit_loss_state.dart';

class ProfitLossPage extends StatelessWidget {
  const ProfitLossPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfitLossBloc>()..add(const LoadProfitLoss()),
      child: const _ProfitLossView(),
    );
  }
}

class _ProfitLossView extends StatefulWidget {
  const _ProfitLossView();

  @override
  State<_ProfitLossView> createState() => _ProfitLossViewState();
}

class _ProfitLossViewState extends State<_ProfitLossView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Profit & Loss'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<ProfitLossBloc, ProfitLossState>(
        listener: (context, state) {
          if (state is! ProfitLossLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is ProfitLossInitial || state is ProfitLossLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfitLossFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as ProfitLossLoaded;
          final selected = _findSelected(data.snapshots);

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
                    OutlinedButton.icon(
                      onPressed: () => _pickMonth(context),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        '${_selectedMonth.month.toString().padLeft(2, '0')}-'
                        '${_selectedMonth.year}',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: data.isProcessing
                          ? null
                          : () {
                              final user = sl<GetCurrentUserUseCase>()();
                              context.read<ProfitLossBloc>().add(
                                GenerateProfitLossRequested(
                                  month: _selectedMonth,
                                  actorId: user?.uid ?? '',
                                ),
                              );
                            },
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Generate / Refresh'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selected == null
                    ? const Center(
                        child: Text(
                          'No profit and loss snapshot exists '
                          'for the selected month.',
                        ),
                      )
                    : _ProfitLossDetails(snapshot: selected),
              ),
            ],
          );
        },
      ),
    );
  }

  MonthlyProfitLossEntity? _findSelected(
    List<MonthlyProfitLossEntity> snapshots,
  ) {
    for (final item in snapshots) {
      if (item.month.year == _selectedMonth.year &&
          item.month.month == _selectedMonth.month) {
        return item;
      }
    }
    return null;
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any date in the required month',
    );

    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }
}

class _ProfitLossDetails extends StatelessWidget {
  const _ProfitLossDetails({required this.snapshot});

  final MonthlyProfitLossEntity snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = <({String label, int value, bool total})>[
      (label: 'Fee Income', value: snapshot.totalFeeIncome, total: false),
      (label: 'Other Income', value: snapshot.totalOtherIncome, total: false),
      (label: 'Total Income', value: snapshot.totalIncome, total: true),
      (
        label: 'Salary Expense',
        value: snapshot.totalSalaryExpense,
        total: false,
      ),
      (label: 'Other Expense', value: snapshot.totalOtherExpense, total: false),
      (label: 'Total Expenses', value: snapshot.totalExpenses, total: true),
      (
        label: snapshot.netProfitLoss >= 0 ? 'Net Profit' : 'Net Loss',
        value: snapshot.netProfitLoss.abs(),
        total: true,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (final row in rows) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      row.label,
                      style: TextStyle(
                        fontWeight: row.total
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    trailing: Text(
                      'Rs. ${row.value}',
                      style: TextStyle(
                        fontWeight: row.total
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (row.total) const Divider(),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Generated: ${snapshot.generatedAt}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
