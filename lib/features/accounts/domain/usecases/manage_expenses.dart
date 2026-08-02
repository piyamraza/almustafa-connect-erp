import '../entities/expense_category_entity.dart';
import '../entities/expense_entity.dart';
import '../repositories/accounts_repository.dart';

class GetExpenseManagementData {
  const GetExpenseManagementData(this._repository);

  final AccountsRepository _repository;

  Future<ExpenseManagementData> call() async {
    final responses = await Future.wait<Object>([
      _repository.getExpenseCategories(),
      _repository.getExpenses(),
    ]);
    return ExpenseManagementData(
      categories: responses[0] as List<ExpenseCategoryEntity>,
      expenses: responses[1] as List<ExpenseEntity>,
    );
  }
}

class ExpenseManagementData {
  const ExpenseManagementData({
    required this.categories,
    required this.expenses,
  });

  final List<ExpenseCategoryEntity> categories;
  final List<ExpenseEntity> expenses;
}

class SaveExpenseCategory {
  const SaveExpenseCategory(this._repository);

  final AccountsRepository _repository;

  Future<void> call(ExpenseCategoryEntity category) {
    if (category.id.trim().isEmpty) {
      throw ArgumentError('Category ID is required.');
    }
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Category name is required.');
    }
    return _repository.saveExpenseCategory(category);
  }
}

class SetExpenseCategoryActive {
  const SetExpenseCategoryActive(this._repository);

  final AccountsRepository _repository;

  Future<void> call({required String categoryId, required bool isActive}) {
    if (categoryId.trim().isEmpty) {
      throw ArgumentError('Category ID is required.');
    }
    return _repository.setExpenseCategoryActive(
      categoryId: categoryId,
      isActive: isActive,
    );
  }
}

class SaveExpense {
  const SaveExpense(this._repository);

  final AccountsRepository _repository;

  Future<void> call(ExpenseEntity expense) {
    if (expense.id.trim().isEmpty) {
      throw ArgumentError('Expense ID is required.');
    }
    if (expense.categoryId.trim().isEmpty) {
      throw ArgumentError('Expense category is required.');
    }
    if (expense.amount <= 0) {
      throw ArgumentError('Expense amount must be greater than zero.');
    }
    if (expense.description.trim().isEmpty) {
      throw ArgumentError('Expense description is required.');
    }
    return _repository.saveExpense(expense);
  }
}

class UpdateExpenseStatus {
  const UpdateExpenseStatus(this._repository);

  final AccountsRepository _repository;

  Future<void> call({
    required String expenseId,
    required ExpenseStatus status,
    required String actorId,
  }) {
    if (expenseId.trim().isEmpty) {
      throw ArgumentError('Expense ID is required.');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('Current user could not be identified.');
    }
    return _repository.updateExpenseStatus(
      expenseId: expenseId,
      status: status,
      actorId: actorId,
    );
  }
}
