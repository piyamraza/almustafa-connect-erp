import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_expenses.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc({
    required GetExpenseManagementData getData,
    required SaveExpenseCategory saveCategory,
    required SetExpenseCategoryActive setCategoryActive,
    required SaveExpense saveExpense,
    required UpdateExpenseStatus updateStatus,
  }) : _getData = getData,
       _saveCategory = saveCategory,
       _setCategoryActive = setCategoryActive,
       _saveExpense = saveExpense,
       _updateStatus = updateStatus,
       super(const ExpenseInitial()) {
    on<LoadExpenses>(_load);
    on<SaveExpenseCategoryRequested>(_saveCategoryRequested);
    on<ToggleExpenseCategoryRequested>(_toggleCategory);
    on<SaveExpenseRequested>(_saveExpenseRequested);
    on<UpdateExpenseStatusRequested>(_updateExpenseStatus);
  }

  final GetExpenseManagementData _getData;
  final SaveExpenseCategory _saveCategory;
  final SetExpenseCategoryActive _setCategoryActive;
  final SaveExpense _saveExpense;
  final UpdateExpenseStatus _updateStatus;

  Future<void> _load(LoadExpenses event, Emitter<ExpenseState> emit) async {
    emit(const ExpenseLoading());
    try {
      final data = await _getData();
      emit(ExpenseLoaded(categories: data.categories, expenses: data.expenses));
    } catch (error) {
      emit(ExpenseFailure(_message(error)));
    }
  }

  Future<void> _saveCategoryRequested(
    SaveExpenseCategoryRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state;
    if (current is! ExpenseLoaded) return;
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _saveCategory(event.category);
      await _reload(
        emit,
        successMessage: 'Expense category saved successfully.',
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _toggleCategory(
    ToggleExpenseCategoryRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state;
    if (current is! ExpenseLoaded) return;
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _setCategoryActive(
        categoryId: event.categoryId,
        isActive: event.isActive,
      );
      await _reload(
        emit,
        successMessage: 'Expense category updated successfully.',
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _saveExpenseRequested(
    SaveExpenseRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state;
    if (current is! ExpenseLoaded) return;
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _saveExpense(event.expense);
      await _reload(emit, successMessage: 'Expense saved successfully.');
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _updateExpenseStatus(
    UpdateExpenseStatusRequested event,
    Emitter<ExpenseState> emit,
  ) async {
    final current = state;
    if (current is! ExpenseLoaded) return;
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _updateStatus(
        expenseId: event.expenseId,
        status: event.status,
        actorId: event.actorId,
      );
      await _reload(
        emit,
        successMessage: 'Expense status updated successfully.',
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          error: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _reload(
    Emitter<ExpenseState> emit, {
    required String successMessage,
  }) async {
    final data = await _getData();
    emit(
      ExpenseLoaded(
        categories: data.categories,
        expenses: data.expenses,
        message: successMessage,
      ),
    );
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
