import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../bloc/expense_state.dart';

class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ExpenseBloc>()..add(const LoadExpenses()),
      child: const _ExpensesView(),
    );
  }
}

class _ExpensesView extends StatefulWidget {
  const _ExpensesView();

  @override
  State<_ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<_ExpensesView> {
  String? _categoryFilter;
  ExpenseStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          final enabled =
              state is ExpenseLoaded && state.activeCategories.isNotEmpty;
          return FloatingActionButton.extended(
            onPressed: enabled
                ? () => _showExpenseDialog(context, state)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Expense'),
          );
        },
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is! ExpenseLoaded) return;
          final text = state.error ?? state.message;
          if (text == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(text)));
        },
        builder: (context, state) {
          if (state is ExpenseInitial || state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseFailure) {
            return Center(child: Text(state.message));
          }
          final data = state as ExpenseLoaded;
          final expenses = data.expenses.where((expense) {
            final categoryMatch =
                _categoryFilter == null ||
                expense.categoryId == _categoryFilter;
            final statusMatch =
                _statusFilter == null || expense.status == _statusFilter;
            return categoryMatch && statusMatch;
          }).toList();

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _showCategoryDialog(context),
                      icon: const Icon(Icons.category_outlined),
                      label: const Text('Manage Categories'),
                    ),
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String?>(
                        value: _categoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...data.categories.map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _categoryFilter = value),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: DropdownButtonFormField<ExpenseStatus?>(
                        value: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Statuses'),
                          ),
                          ...ExpenseStatus.values.map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.name.toUpperCase()),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Text('No expenses match the selected filters.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            child: ListTile(
                              title: Text(expense.description),
                              subtitle: Text(
                                '${expense.categoryName} • '
                                '${expense.payeeName.isEmpty ? 'No payee' : expense.payeeName} • '
                                '${expense.status.name.toUpperCase()}',
                              ),
                              leading: CircleAvatar(
                                child: Text(
                                  expense.categoryName.isEmpty
                                      ? '?'
                                      : expense.categoryName[0],
                                ),
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Rs. ${expense.amount}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        _handleAction(context, expense, value),
                                    itemBuilder: (_) => [
                                      if (expense.status == ExpenseStatus.draft)
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                      if (expense.status == ExpenseStatus.draft)
                                        const PopupMenuItem(
                                          value: 'approve',
                                          child: Text('Approve'),
                                        ),
                                      if (expense.status ==
                                          ExpenseStatus.approved)
                                        const PopupMenuItem(
                                          value: 'paid',
                                          child: Text('Mark Paid'),
                                        ),
                                      if (expense.status != ExpenseStatus.paid)
                                        const PopupMenuItem(
                                          value: 'cancel',
                                          child: Text('Cancel'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showCategoryDialog(BuildContext context) async {
    final state = context.read<ExpenseBloc>().state;
    if (state is! ExpenseLoaded) return;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Expense Categories'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...state.categories.map(
                  (item) => SwitchListTile(
                    value: item.isActive,
                    title: Text(item.name),
                    subtitle: Text(item.description),
                    onChanged: (value) {
                      context.read<ExpenseBloc>().add(
                        ToggleExpenseCategoryRequested(
                          categoryId: item.id,
                          isActive: value,
                        ),
                      );
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                ),
                const Divider(),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Category Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
    if (result == true && context.mounted) {
      final now = DateTime.now();
      final id = 'expense_category_${now.microsecondsSinceEpoch}';
      context.read<ExpenseBloc>().add(
        SaveExpenseCategoryRequested(
          ExpenseCategoryEntity(
            id: id,
            name: nameController.text.trim(),
            description: descriptionController.text.trim(),
            isActive: true,
            displayOrder: state.categories.length,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }
    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _showExpenseDialog(
    BuildContext context,
    ExpenseLoaded state, {
    ExpenseEntity? existing,
  }) async {
    final descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    final amountController = TextEditingController(
      text: existing?.amount.toString() ?? '',
    );
    final payeeController = TextEditingController(
      text: existing?.payeeName ?? '',
    );
    final paymentController = TextEditingController(
      text: existing?.paymentMethod ?? 'Cash',
    );
    final referenceController = TextEditingController(
      text: existing?.referenceNumber ?? '',
    );
    final receiptController = TextEditingController(
      text: existing?.receiptUrl ?? '',
    );
    var selectedCategoryId =
        existing?.categoryId ?? state.activeCategories.first.id;
    var selectedDate = existing?.expenseDate ?? DateTime.now();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: state.activeCategories
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedCategoryId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount (Rs.)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: payeeController,
                    decoration: const InputDecoration(labelText: 'Payee Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: paymentController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: receiptController,
                    decoration: const InputDecoration(
                      labelText: 'Receipt URL (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expense Date'),
                    subtitle: Text(
                      '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}',
                    ),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: selectedDate,
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      final amount = int.tryParse(amountController.text.trim()) ?? 0;
      final category = state.activeCategories.firstWhere(
        (item) => item.id == selectedCategoryId,
      );
      final now = DateTime.now();
      final user = sl<GetCurrentUserUseCase>()();
      context.read<ExpenseBloc>().add(
        SaveExpenseRequested(
          ExpenseEntity(
            id: existing?.id ?? 'expense_${now.microsecondsSinceEpoch}',
            categoryId: category.id,
            categoryName: category.name,
            amount: amount,
            expenseDate: selectedDate,
            description: descriptionController.text.trim(),
            payeeName: payeeController.text.trim(),
            paymentMethod: paymentController.text.trim(),
            referenceNumber: referenceController.text.trim(),
            receiptUrl: receiptController.text.trim(),
            status: existing?.status ?? ExpenseStatus.draft,
            enteredBy: existing?.enteredBy ?? user?.uid ?? '',
            approvedBy: existing?.approvedBy ?? '',
            approvedAt: existing?.approvedAt,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            sourceType: ExpenseSourceType.manual,
            sourceId: existing?.sourceId ?? '',
          ),
        ),
      );
    }

    descriptionController.dispose();
    amountController.dispose();
    payeeController.dispose();
    paymentController.dispose();
    referenceController.dispose();
    receiptController.dispose();
  }

  void _handleAction(
    BuildContext context,
    ExpenseEntity expense,
    String action,
  ) {
    final state = context.read<ExpenseBloc>().state;
    if (action == 'edit' && state is ExpenseLoaded) {
      _showExpenseDialog(context, state, existing: expense);
      return;
    }
    final user = sl<GetCurrentUserUseCase>()();
    final status = switch (action) {
      'approve' => ExpenseStatus.approved,
      'paid' => ExpenseStatus.paid,
      _ => ExpenseStatus.cancelled,
    };
    context.read<ExpenseBloc>().add(
      UpdateExpenseStatusRequested(
        expenseId: expense.id,
        status: status,
        actorId: user?.uid ?? '',
      ),
    );
  }
}
