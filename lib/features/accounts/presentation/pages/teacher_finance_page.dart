import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/teacher_finance_account_entity.dart';
import '../../domain/entities/teacher_finance_transaction_entity.dart';
import '../../domain/repositories/teacher_finance_repository.dart';

class TeacherFinancePage extends StatefulWidget {
  const TeacherFinancePage({super.key});

  @override
  State<TeacherFinancePage> createState() => _TeacherFinancePageState();
}

class _TeacherFinancePageState extends State<TeacherFinancePage> {
  final TeacherFinanceRepository _repository = sl<TeacherFinanceRepository>();

  List<TeacherFinanceAccountEntity> _accounts = const [];
  bool _loading = true;
  String? _errorMessage;
  TeacherFinanceStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _repository.getAccounts(status: _statusFilter);

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advances & Loans'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Advance / Loan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<TeacherFinanceStatus?>(
                    initialValue: _statusFilter,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem<TeacherFinanceStatus?>(
                        value: null,
                        child: Text('All'),
                      ),
                      DropdownMenuItem<TeacherFinanceStatus?>(
                        value: TeacherFinanceStatus.active,
                        child: Text('Active'),
                      ),
                      DropdownMenuItem<TeacherFinanceStatus?>(
                        value: TeacherFinanceStatus.closed,
                        child: Text('Closed'),
                      ),
                      DropdownMenuItem<TeacherFinanceStatus?>(
                        value: TeacherFinanceStatus.cancelled,
                        child: Text('Cancelled'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _statusFilter = value);
                      _load();
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_accounts.isEmpty) {
      return const Center(child: Text('No advance or loan accounts found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: _accounts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final account = _accounts[index];

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                account.financeType == TeacherFinanceType.advance
                    ? Icons.payments_outlined
                    : Icons.account_balance_outlined,
              ),
            ),
            title: Text(account.employeeName),
            subtitle: Text(
              '${_typeLabel(account.financeType)} • '
              '${_statusLabel(account.status)}\n'
              'Approved: Rs. ${account.principalAmount} • '
              'Recovered: Rs. ${account.recoveredAmount} • '
              'Balance: Rs. ${account.outstandingAmount}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                _handleAction(account: account, action: value);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'ledger',
                  child: Text('View Ledger'),
                ),
                if (account.status == TeacherFinanceStatus.active)
                  const PopupMenuItem(
                    value: 'recover',
                    child: Text('Manual Recovery'),
                  ),
                if (account.status == TeacherFinanceStatus.active &&
                    account.recoveredAmount == 0)
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel Account'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateDialog() async {
    final teachers = await sl<TeacherRepository>().getTeachers();

    if (!mounted) return;

    final activeTeachers = teachers.where((item) => item.isActive).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    if (activeTeachers.isEmpty) {
      _message('No active teachers found.');
      return;
    }

    TeacherFinanceType type = TeacherFinanceType.advance;
    dynamic selectedTeacher;

    final amountController = TextEditingController();
    final recoveryController = TextEditingController();
    final notesController = TextEditingController();

    DateTime recoveryStart = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Advance / Loan'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<dynamic>(
                        initialValue: selectedTeacher,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Teacher',
                          border: OutlineInputBorder(),
                        ),
                        items: activeTeachers
                            .map(
                              (teacher) => DropdownMenuItem<dynamic>(
                                value: teacher,
                                child: Text(
                                  '${teacher.fullName} '
                                  '(${teacher.employeeId})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedTeacher = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TeacherFinanceType>(
                        initialValue: type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TeacherFinanceType.advance,
                            child: Text('Advance'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.loan,
                            child: Text('Loan'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              type = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Approved Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: recoveryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Monthly Recovery',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recovery Start Month'),
                        subtitle: Text(
                          '${recoveryStart.month.toString().padLeft(2, '0')}'
                          '-${recoveryStart.year}',
                        ),
                        trailing: const Icon(Icons.calendar_month),
                        onTap: () async {
                          final value = await showDatePicker(
                            context: dialogContext,
                            initialDate: recoveryStart,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );

                          if (value != null) {
                            setDialogState(() {
                              recoveryStart = DateTime(value.year, value.month);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedTeacher == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Approve'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final amount = int.tryParse(amountController.text.trim()) ?? 0;

      final monthlyRecovery = int.tryParse(recoveryController.text.trim()) ?? 0;

      final user = sl<GetCurrentUserUseCase>()();
      final now = DateTime.now();

      try {
        await _repository.createAccount(
          TeacherFinanceAccountEntity(
            id: _repository.generateAccountId(),
            employeeId: selectedTeacher.employeeId,
            employeeName: selectedTeacher.fullName,
            financeType: type,
            principalAmount: amount,
            monthlyRecoveryAmount: monthlyRecovery,
            recoveredAmount: 0,
            outstandingAmount: amount,
            issueDate: now,
            recoveryStartMonth: recoveryStart,
            recoveryMode: TeacherFinanceRecoveryMode.monthly,
            status: TeacherFinanceStatus.active,
            approvedBy: user?.uid ?? '',
            notes: notesController.text.trim(),
            createdAt: now,
            updatedAt: now,
          ),
        );

        if (!mounted) return;

        _message('${_typeLabel(type)} approved successfully.');

        await _load();
      } catch (error) {
        if (!mounted) return;

        _message(error.toString());
      }
    }

    amountController.dispose();
    recoveryController.dispose();
    notesController.dispose();
  }

  Future<void> _handleAction({
    required TeacherFinanceAccountEntity account,
    required String action,
  }) async {
    if (action == 'ledger') {
      await _showLedger(account);
      return;
    }

    if (action == 'recover') {
      await _showRecoveryDialog(account);
      return;
    }

    if (action == 'cancel') {
      await _showCancelDialog(account);
    }
  }

  Future<void> _showLedger(TeacherFinanceAccountEntity account) async {
    final transactions = await _repository.getTransactions(
      accountId: account.id,
    );

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('${account.employeeName} Ledger'),
          content: SizedBox(
            width: 650,
            height: 420,
            child: transactions.isEmpty
                ? const Center(child: Text('No transactions found.'))
                : ListView.separated(
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = transactions[index];

                      return ListTile(
                        leading: Icon(_transactionIcon(item.transactionType)),
                        title: Text(_transactionLabel(item.transactionType)),
                        subtitle: Text(
                          '${_date(item.transactionDate)}'
                          '${item.notes.isEmpty ? '' : '\n${item.notes}'}',
                        ),
                        trailing: Text(
                          'Rs. ${item.amount}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRecoveryDialog(TeacherFinanceAccountEntity account) async {
    final amountController = TextEditingController(
      text: account.monthlyRecoveryAmount.toString(),
    );

    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Manual Recovery - ${account.employeeName}'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Outstanding: Rs. ${account.outstandingAmount}'),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save Recovery'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final user = sl<GetCurrentUserUseCase>()();

      try {
        await _repository.applyRecovery(
          accountId: account.id,
          amount: int.tryParse(amountController.text.trim()) ?? 0,
          transactionType: TeacherFinanceTransactionType.manualRecovery,
          actorId: user?.uid ?? '',
          referenceNumber: referenceController.text.trim(),
          notes: notesController.text.trim(),
        );

        if (!mounted) return;

        _message('Recovery saved successfully.');

        await _load();
      } catch (error) {
        if (!mounted) return;

        _message(error.toString());
      }
    }

    amountController.dispose();
    referenceController.dispose();
    notesController.dispose();
  }

  Future<void> _showCancelDialog(TeacherFinanceAccountEntity account) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Advance / Loan'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Cancellation Reason',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Back'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cancel Account'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final user = sl<GetCurrentUserUseCase>()();

      try {
        await _repository.cancelAccount(
          accountId: account.id,
          actorId: user?.uid ?? '',
          reason: reasonController.text.trim(),
        );

        if (!mounted) return;

        _message('Account cancelled.');

        await _load();
      } catch (error) {
        if (!mounted) return;

        _message(error.toString());
      }
    }

    reasonController.dispose();
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  String _typeLabel(TeacherFinanceType value) {
    return switch (value) {
      TeacherFinanceType.advance => 'Advance',
      TeacherFinanceType.loan => 'Loan',
      TeacherFinanceType.salaryAdjustment => 'Salary Adjustment',
      TeacherFinanceType.bonus => 'Bonus',
      TeacherFinanceType.penalty => 'Penalty',
      TeacherFinanceType.allowance => 'Allowance',
      TeacherFinanceType.otherDeduction => 'Other Deduction',
      TeacherFinanceType.otherPayment => 'Other Payment',
    };
  }

  String _statusLabel(TeacherFinanceStatus value) {
    return switch (value) {
      TeacherFinanceStatus.active => 'Active',
      TeacherFinanceStatus.closed => 'Closed',
      TeacherFinanceStatus.cancelled => 'Cancelled',
    };
  }

  String _transactionLabel(TeacherFinanceTransactionType value) {
    return switch (value) {
      TeacherFinanceTransactionType.disbursement => 'Disbursement',
      TeacherFinanceTransactionType.payrollRecovery => 'Payroll Recovery',
      TeacherFinanceTransactionType.manualRecovery => 'Manual Recovery',
      TeacherFinanceTransactionType.adjustment => 'Adjustment',
      TeacherFinanceTransactionType.cancellation => 'Cancellation',
      TeacherFinanceTransactionType.bonus => 'Bonus',
      TeacherFinanceTransactionType.allowance => 'Allowance',
      TeacherFinanceTransactionType.penalty => 'Penalty',
      TeacherFinanceTransactionType.otherDeduction => 'Other Deduction',
      TeacherFinanceTransactionType.otherPayment => 'Other Payment',
      TeacherFinanceTransactionType.salaryAdjustment => 'Salary Adjustment',
    };
  }

  IconData _transactionIcon(TeacherFinanceTransactionType value) {
    return switch (value) {
      TeacherFinanceTransactionType.disbursement =>
        Icons.account_balance_wallet,
      TeacherFinanceTransactionType.payrollRecovery => Icons.payments,
      TeacherFinanceTransactionType.manualRecovery => Icons.point_of_sale,
      TeacherFinanceTransactionType.adjustment => Icons.tune,
      TeacherFinanceTransactionType.cancellation => Icons.cancel,
      TeacherFinanceTransactionType.bonus => Icons.card_giftcard,
      TeacherFinanceTransactionType.allowance => Icons.add_circle,
      TeacherFinanceTransactionType.penalty => Icons.gpp_bad,
      TeacherFinanceTransactionType.otherDeduction => Icons.remove_circle,
      TeacherFinanceTransactionType.otherPayment => Icons.attach_money,
      TeacherFinanceTransactionType.salaryAdjustment => Icons.calculate,
    };
  }

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }
}
