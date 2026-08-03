import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/store_reports_bloc.dart';
import '../bloc/store_reports_event.dart';
import '../bloc/store_reports_state.dart';

class StoreReportsPage extends StatelessWidget {
  const StoreReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StoreReportsBloc>()..add(const LoadStoreReports()),
      child: const _StoreReportsView(),
    );
  }
}

class _StoreReportsView extends StatelessWidget {
  const _StoreReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Store Reports'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<StoreReportsBloc, StoreReportsState>(
        builder: (context, state) {
          if (state is StoreReportsInitial || state is StoreReportsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StoreReportsFailure) {
            return Center(child: Text(state.message));
          }

          final report = (state as StoreReportsLoaded).report;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Total Sales',
                    value: 'Rs. ${report.totalSales.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Total Purchases',
                    value: 'Rs. ${report.totalPurchases.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Profit',
                    value: 'Rs. ${report.totalProfit.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Stock Value',
                    value: 'Rs. ${report.stockValue.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Student Receivable',
                    value: 'Rs. ${report.studentReceivable.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Supplier Payable',
                    value: 'Rs. ${report.supplierPayable.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Low Stock Items',
                    value: '${report.lowStockCount}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Stock Movement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.itemMovements.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.itemName),
                    subtitle: Text(
                      'Opening ${item.openingStock} - '
                      'Purchased ${item.purchasedQuantity} - '
                      'Sold ${item.soldQuantity} - '
                      'Balance ${item.currentStock}',
                    ),
                    trailing: Text(
                      'Profit Rs. ${item.profitAmount.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Student Outstanding Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.studentBalances
                  .where((value) => value.outstandingAmount > 0)
                  .map(
                    (value) => Card(
                      child: ListTile(
                        title: Text(value.name),
                        subtitle: Text(value.reference),
                        trailing: Text(
                          'Due Rs. ${value.outstandingAmount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 22),
              Text(
                'Supplier Outstanding Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.supplierBalances
                  .where((value) => value.outstandingAmount > 0)
                  .map(
                    (value) => Card(
                      child: ListTile(
                        title: Text(value.name),
                        trailing: Text(
                          'Due Rs. ${value.outstandingAmount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
