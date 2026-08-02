import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/accounts_bloc.dart';
import '../bloc/accounts_event.dart';
import '../bloc/accounts_state.dart';
import '../widgets/accounts_analytics_widgets.dart';
import 'accounts_reports_page.dart';
import 'cashbook_page.dart';
import 'expenses_page.dart';
import 'income_page.dart';
import 'payroll_page.dart';
import 'profit_loss_page.dart';

class AccountsDashboardPage extends StatelessWidget {
  const AccountsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AccountsBloc>()..add(const LoadAccountsOverview()),
      child: const _AccountsDashboardView(),
    );
  }
}

class _AccountsDashboardView extends StatelessWidget {
  const _AccountsDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Payroll'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<AccountsBloc>().add(const RefreshAccountsOverview());
            },
            icon: const Icon(Icons.refresh),
          ),
          const DashboardNavigationButton(),
        ],
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) {
          if (state is AccountsInitial || state is AccountsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AccountsFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message),
              ),
            );
          }

          final loaded = state as AccountsLoaded;
          final summary = AccountsAnalyticsSummary.fromData(
            incomeEntries: loaded.incomeEntries,
            expenses: loaded.expenses,
            payrollRecords: loaded.payrollRecords,
            profitLoss: loaded.profitLoss,
            cashbookEntries: loaded.cashbookEntries,
          );

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AccountsBloc>().add(const RefreshAccountsOverview());
              await context.read<AccountsBloc>().stream.firstWhere(
                (next) => next is AccountsLoaded || next is AccountsFailure,
              );
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        'Financial Overview',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 1100
                              ? 5
                              : constraints.maxWidth >= 700
                              ? 3
                              : constraints.maxWidth >= 430
                              ? 2
                              : 1;

                          final cards = [
                            AccountsKpiCard(
                              title: 'Total Income',
                              value: summary.totalIncome,
                              icon: Icons.trending_up,
                            ),
                            AccountsKpiCard(
                              title: 'Total Expenses',
                              value: summary.totalExpense,
                              icon: Icons.trending_down,
                            ),
                            AccountsKpiCard(
                              title: 'Cash Balance',
                              value: summary.cashBalance,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                            AccountsKpiCard(
                              title: 'Salary Expense',
                              value: summary.salaryExpense,
                              icon: Icons.payments_outlined,
                            ),
                            AccountsKpiCard(
                              title: summary.netProfitLoss >= 0
                                  ? 'Net Profit'
                                  : 'Net Loss',
                              value: summary.netProfitLoss.abs(),
                              icon: summary.netProfitLoss >= 0
                                  ? Icons.insights
                                  : Icons.show_chart,
                            ),
                          ];

                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: columns == 1
                                ? 3.1
                                : columns == 2
                                ? 1.55
                                : 1.2,
                            children: cards,
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 900;

                          if (!wide) {
                            return Column(
                              children: [
                                AccountsMonthlyTrendChart(
                                  items: summary.monthlyTrend,
                                ),
                                const SizedBox(height: 14),
                                AccountsTopExpenseCategories(
                                  items: summary.topExpenseCategories,
                                ),
                              ],
                            );
                          }

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: AccountsMonthlyTrendChart(
                                  items: summary.monthlyTrend,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: AccountsTopExpenseCategories(
                                  items: summary.topExpenseCategories,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      AccountsRecentTransactions(
                        items: summary.recentTransactions,
                      ),
                      const SizedBox(height: 26),
                      Text(
                        'Accounts Modules',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                    ]),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: _AccountsModuleGrid(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountsModuleGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final modules = <_AccountsModule>[
      const _AccountsModule(
        title: 'Expenses',
        description: 'Record and review school expenses.',
        icon: Icons.receipt_long_outlined,
        page: ExpensesPage(),
      ),
      const _AccountsModule(
        title: 'Payroll',
        description: 'Manage teacher and staff salaries.',
        icon: Icons.payments_outlined,
        page: PayrollPage(),
      ),
      const _AccountsModule(
        title: 'Income',
        description: 'Review fee and other school income.',
        icon: Icons.account_balance_wallet_outlined,
        page: IncomePage(),
      ),
      const _AccountsModule(
        title: 'Monthly Profit & Loss',
        description: 'Compare monthly income and expenses.',
        icon: Icons.insights_outlined,
        page: ProfitLossPage(),
      ),
      const _AccountsModule(
        title: 'Cashbook',
        description: 'View chronological financial transactions.',
        icon: Icons.menu_book_outlined,
        page: CashbookPage(),
      ),
      const _AccountsModule(
        title: 'Reports',
        description: 'Open financial and payroll reports.',
        icon: Icons.assessment_outlined,
        page: AccountsReportsPage(),
      ),
    ];

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 1100
            ? 3
            : width >= 650
            ? 2
            : 1;

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: columns == 1 ? 2.25 : 1.35,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final module = modules[index];

            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => module.page));
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(module.icon, size: 34),
                      const SizedBox(height: 14),
                      Text(
                        module.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(module.description),
                      const Spacer(),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }, childCount: modules.length),
        );
      },
    );
  }
}

class _AccountsModule {
  const _AccountsModule({
    required this.title,
    required this.description,
    required this.icon,
    required this.page,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget page;
}
