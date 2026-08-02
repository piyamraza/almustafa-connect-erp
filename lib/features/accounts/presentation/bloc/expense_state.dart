import 'package:equatable/equatable.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';

sealed class ExpenseState extends Equatable {
  const ExpenseState();

  @override
  List<Object?> get props => const [];
}

class ExpenseInitial extends ExpenseState {
  const ExpenseInitial();
}

class ExpenseLoading extends ExpenseState {
  const ExpenseLoading();
}

class ExpenseLoaded extends ExpenseState {
  const ExpenseLoaded({
    required this.categories,
    required this.expenses,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<ExpenseCategoryEntity> categories;
  final List<ExpenseEntity> expenses;
  final bool isProcessing;
  final String? message;
  final String? error;

  List<ExpenseCategoryEntity> get activeCategories =>
      categories.where((item) => item.isActive).toList();

  ExpenseLoaded copyWith({
    List<ExpenseCategoryEntity>? categories,
    List<ExpenseEntity>? expenses,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return ExpenseLoaded(
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    expenses,
    isProcessing,
    message,
    error,
  ];
}

class ExpenseFailure extends ExpenseState {
  const ExpenseFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
