import 'package:equatable/equatable.dart';

import '../../domain/entities/cashbook_entry_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/income_entry_entity.dart';
import '../../domain/entities/monthly_profit_loss_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => const [];
}

class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

class AccountsLoaded extends AccountsState {
  const AccountsLoaded({
    required this.expenses,
    required this.incomeEntries,
    required this.payrollRecords,
    required this.profitLoss,
    required this.cashbookEntries,
  });

  final List<ExpenseEntity> expenses;
  final List<IncomeEntryEntity> incomeEntries;
  final List<PayrollRecordEntity> payrollRecords;
  final List<MonthlyProfitLossEntity> profitLoss;
  final List<CashbookEntryEntity> cashbookEntries;

  @override
  List<Object?> get props => [
    expenses,
    incomeEntries,
    payrollRecords,
    profitLoss,
    cashbookEntries,
  ];
}

class AccountsFailure extends AccountsState {
  const AccountsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
