import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => const [];
}

class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
}

class SaveExpenseCategoryRequested extends ExpenseEvent {
  const SaveExpenseCategoryRequested(this.category);

  final ExpenseCategoryEntity category;

  @override
  List<Object?> get props => [category];
}

class ToggleExpenseCategoryRequested extends ExpenseEvent {
  const ToggleExpenseCategoryRequested({
    required this.categoryId,
    required this.isActive,
  });

  final String categoryId;
  final bool isActive;

  @override
  List<Object?> get props => [categoryId, isActive];
}

class SaveExpenseRequested extends ExpenseEvent {
  const SaveExpenseRequested(this.expense);

  final ExpenseEntity expense;

  @override
  List<Object?> get props => [expense];
}

class UpdateExpenseStatusRequested extends ExpenseEvent {
  const UpdateExpenseStatusRequested({
    required this.expenseId,
    required this.status,
    required this.actorId,
  });

  final String expenseId;
  final ExpenseStatus status;
  final String actorId;

  @override
  List<Object?> get props => [expenseId, status, actorId];
}
