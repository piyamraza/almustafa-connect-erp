import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/monthly_profit_loss_entity.dart';

class MonthlyProfitLossModel extends MonthlyProfitLossEntity {
  const MonthlyProfitLossModel({
    required super.id,
    required super.month,
    required super.totalFeeIncome,
    required super.totalOtherIncome,
    required super.totalIncome,
    required super.totalSalaryExpense,
    required super.totalOtherExpense,
    required super.totalExpenses,
    required super.netProfitLoss,
    required super.generatedAt,
    required super.generatedBy,
  });

  factory MonthlyProfitLossModel.fromEntity(MonthlyProfitLossEntity entity) {
    return MonthlyProfitLossModel(
      id: entity.id,
      month: entity.month,
      totalFeeIncome: entity.totalFeeIncome,
      totalOtherIncome: entity.totalOtherIncome,
      totalIncome: entity.totalIncome,
      totalSalaryExpense: entity.totalSalaryExpense,
      totalOtherExpense: entity.totalOtherExpense,
      totalExpenses: entity.totalExpenses,
      netProfitLoss: entity.netProfitLoss,
      generatedAt: entity.generatedAt,
      generatedBy: entity.generatedBy,
    );
  }

  factory MonthlyProfitLossModel.fromMap(Map<String, dynamic> map) {
    return MonthlyProfitLossModel(
      id: map['id'] as String? ?? '',
      month: _date(map['month']),
      totalFeeIncome: _int(map['totalFeeIncome']),
      totalOtherIncome: _int(map['totalOtherIncome']),
      totalIncome: _int(map['totalIncome']),
      totalSalaryExpense: _int(map['totalSalaryExpense']),
      totalOtherExpense: _int(map['totalOtherExpense']),
      totalExpenses: _int(map['totalExpenses']),
      netProfitLoss: _int(map['netProfitLoss']),
      generatedAt: _date(map['generatedAt']),
      generatedBy: map['generatedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month.toIso8601String(),
      'totalFeeIncome': totalFeeIncome,
      'totalOtherIncome': totalOtherIncome,
      'totalIncome': totalIncome,
      'totalSalaryExpense': totalSalaryExpense,
      'totalOtherExpense': totalOtherExpense,
      'totalExpenses': totalExpenses,
      'netProfitLoss': netProfitLoss,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
      'schemaVersion': 1,
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
