import 'package:equatable/equatable.dart';

class MonthlyProfitLossEntity extends Equatable {
  const MonthlyProfitLossEntity({
    required this.id,
    required this.month,
    required this.totalFeeIncome,
    required this.totalOtherIncome,
    required this.totalIncome,
    required this.totalSalaryExpense,
    required this.totalOtherExpense,
    required this.totalExpenses,
    required this.netProfitLoss,
    required this.generatedAt,
    required this.generatedBy,
  });

  final String id;
  final DateTime month;
  final int totalFeeIncome;
  final int totalOtherIncome;
  final int totalIncome;
  final int totalSalaryExpense;
  final int totalOtherExpense;
  final int totalExpenses;
  final int netProfitLoss;
  final DateTime generatedAt;
  final String generatedBy;

  @override
  List<Object?> get props => [
    id,
    month,
    totalFeeIncome,
    totalOtherIncome,
    totalIncome,
    totalSalaryExpense,
    totalOtherExpense,
    totalExpenses,
    netProfitLoss,
    generatedAt,
    generatedBy,
  ];
}
