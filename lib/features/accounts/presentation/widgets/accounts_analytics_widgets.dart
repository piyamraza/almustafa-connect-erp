import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';

class AccountsAnalyticsSummary {
  const AccountsAnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.cashBalance,
    required this.salaryExpense,
    required this.netProfitLoss,
    required this.monthlyTrend,
    required this.topExpenseCategories,
    required this.recentTransactions,
  });

  final int totalIncome;
  final int totalExpense;
  final int cashBalance;
  final int salaryExpense;
  final int netProfitLoss;
  final List<AccountsMonthlyTrendItem> monthlyTrend;
  final List<AccountsCategoryAmount> topExpenseCategories;
  final List<AccountsRecentTransaction> recentTransactions;

  factory AccountsAnalyticsSummary.fromData({
    required List<IncomeEntryEntity> incomeEntries,
    required List<ExpenseEntity> expenses,
    required List<PayrollRecordEntity> payrollRecords,
    required List<MonthlyProfitLossEntity> profitLoss,
    required List<CashbookEntryEntity> cashbookEntries,
  }) {
    final activeIncome = incomeEntries
        .where((entry) => entry.isActive)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final paidExpenses = expenses
        .where((entry) => entry.status == ExpenseStatus.paid)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final paidPayroll = payrollRecords
        .where((entry) => entry.paymentStatus == PayrollPaymentStatus.paid)
        .fold<int>(0, (sum, entry) => sum + entry.netSalary);

    final cashIncome = cashbookEntries
        .where((entry) => entry.entryType == CashbookEntryType.income)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final cashExpense = cashbookEntries
        .where((entry) => entry.entryType == CashbookEntryType.expense)
        .fold<int>(0, (sum, entry) => sum + entry.amount);

    final sortedProfitLoss = [...profitLoss]
      ..sort((a, b) => a.month.compareTo(b.month));

    final trend = sortedProfitLoss
        .skip(math.max(0, sortedProfitLoss.length - 6))
        .map(
          (item) => AccountsMonthlyTrendItem(
            month: item.month,
            income: item.totalIncome,
            expense: item.totalExpenses,
          ),
        )
        .toList();

    final categoryTotals = <String, int>{};
    for (final expense in expenses.where(
      (entry) => entry.status == ExpenseStatus.paid,
    )) {
      final name = expense.categoryName.trim().isEmpty
          ? 'Uncategorised'
          : expense.categoryName.trim();
      categoryTotals[name] = (categoryTotals[name] ?? 0) + expense.amount;
    }

    final categories =
        categoryTotals.entries
            .map(
              (entry) => AccountsCategoryAmount(
                category: entry.key,
                amount: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final transactions = <AccountsRecentTransaction>[
      ...cashbookEntries.map(
        (entry) => AccountsRecentTransaction(
          date: entry.entryDate,
          title: entry.description,
          amount: entry.amount,
          isIncome: entry.entryType == CashbookEntryType.income,
          source: entry.sourceType,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final latestProfitLoss = sortedProfitLoss.isEmpty
        ? activeIncome - paidExpenses - paidPayroll
        : sortedProfitLoss.last.netProfitLoss;

    return AccountsAnalyticsSummary(
      totalIncome: activeIncome,
      totalExpense: paidExpenses + paidPayroll,
      cashBalance: cashIncome - cashExpense,
      salaryExpense: paidPayroll,
      netProfitLoss: latestProfitLoss,
      monthlyTrend: trend,
      topExpenseCategories: categories.take(5).toList(),
      recentTransactions: transactions.take(8).toList(),
    );
  }
}

class AccountsMonthlyTrendItem {
  const AccountsMonthlyTrendItem({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;
}

class AccountsCategoryAmount {
  const AccountsCategoryAmount({required this.category, required this.amount});

  final String category;
  final int amount;
}

class AccountsRecentTransaction {
  const AccountsRecentTransaction({
    required this.date,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.source,
  });

  final DateTime date;
  final String title;
  final int amount;
  final bool isIncome;
  final String source;
}

class AccountsKpiCard extends StatelessWidget {
  const AccountsKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    super.key,
  });

  final String title;
  final int value;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(radius: 18, child: Icon(icon, size: 19)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${_money(value)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _money(int value) {
    final negative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      final remaining = digits.length - index;
      buffer.write(digits[index]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }

    return '${negative ? '-' : ''}${buffer.toString()}';
  }
}

class AccountsMonthlyTrendChart extends StatelessWidget {
  const AccountsMonthlyTrendChart({required this.items, super.key});

  final List<AccountsMonthlyTrendItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Monthly Income vs Expense',
        message: 'Generate monthly profit and loss to view trends.',
        icon: Icons.bar_chart_outlined,
      );
    }

    final maximum = items.fold<int>(
      1,
      (current, item) => math.max(current, math.max(item.income, item.expense)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Income vs Expense',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 230,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.map((item) {
                  final incomeHeight = 150 * item.income / maximum;
                  final expenseHeight = 150 * item.expense / maximum;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Bar(height: incomeHeight, label: 'I'),
                                const SizedBox(width: 5),
                                _Bar(height: expenseHeight, label: 'E'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${item.month.month.toString().padLeft(2, '0')}/'
                            '${item.month.year.toString().substring(2)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 18,
              children: [Text('I = Income'), Text('E = Expense')],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.label});

  final double height;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label == 'I' ? 'Income' : 'Expense',
      child: Container(
        width: 20,
        height: math.max(4, height),
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: label == 'I' ? 0.85 : 0.38),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }
}

class AccountsTopExpenseCategories extends StatelessWidget {
  const AccountsTopExpenseCategories({required this.items, super.key});

  final List<AccountsCategoryAmount> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Top Expense Categories',
        message: 'Paid expenses will appear here.',
        icon: Icons.pie_chart_outline,
      );
    }

    final maximum = items.fold<int>(
      1,
      (value, item) => math.max(value, item.amount),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Expense Categories',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.category)),
                        Text('Rs. ${item.amount}'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: item.amount / maximum),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountsRecentTransactions extends StatelessWidget {
  const AccountsRecentTransactions({required this.items, super.key});

  final List<AccountsRecentTransaction> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyAnalyticsCard(
        title: 'Recent Transactions',
        message: 'Sync the cashbook to view recent transactions.',
        icon: Icons.receipt_long_outlined,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Icon(
                    item.isIncome ? Icons.south_west : Icons.north_east,
                  ),
                ),
                title: Text(item.title),
                subtitle: Text('${_date(item.date)} • ${item.source}'),
                trailing: Text(
                  '${item.isIncome ? '+' : '-'} Rs. ${item.amount}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
