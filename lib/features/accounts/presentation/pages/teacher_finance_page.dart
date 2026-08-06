import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../../staff/domain/entities/staff_entity.dart';
import '../../../staff/domain/repositories/staff_repository.dart';
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
  List<TeacherFinanceTransactionEntity> _standaloneTransactions = const [];

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
      final accounts = await _repository.getAccounts(
        status: _statusFilter,
      );

      final transactions = await _repository.getTransactions(
        includeReversed: false,
      );

      final standaloneTransactions = transactions
          .where(_isStandaloneTransaction)
          .toList()
        ..sort(
          (a, b) => b.transactionDate.compareTo(a.transactionDate),
        );

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _standaloneTransactions = standaloneTransactions;
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
        title: const Text('Employee Finance'),
        actions: const [
          DashboardNavigationButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Employee Finance Entry'),
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
                      labelText: 'Account Status',
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
                      setState(() {
                        _statusFilter = value;
                      });

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
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
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

    if (_accounts.isEmpty && _standaloneTransactions.isEmpty) {
      return const Center(
        child: Text('No Employee Finance entries found.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (_accounts.isNotEmpty) ...[
          Text(
            'Advance and Loan Accounts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._accounts.map(_buildAccountCard),
        ],
        if (_accounts.isNotEmpty && _standaloneTransactions.isNotEmpty)
          const SizedBox(height: 24),
        if (_standaloneTransactions.isNotEmpty) ...[
          Text(
            'Payroll Finance Entries',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ..._standaloneTransactions.map(_buildTransactionCard),
        ],
      ],
    );
  }

  Widget _buildAccountCard(TeacherFinanceAccountEntity account) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
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
            '${_employeeTypeLabel(account.employeeType)} • '
            '${_typeLabel(account.financeType)} • '
            '${_statusLabel(account.status)}\n'
            'Amount: Rs. ${account.principalAmount} • '
            'Recovered: Rs. ${account.recoveredAmount} • '
            'Balance: Rs. ${account.outstandingAmount}',
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              _handleAction(
                account: account,
                action: value,
              );
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'ledger',
                child: Text('View Ledger'),
              ),
              if (account.status == TeacherFinanceStatus.active &&
                  account.isRecoverable)
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
      ),
    );
  }

  Widget _buildTransactionCard(
    TeacherFinanceTransactionEntity transaction,
  ) {
    final payrollMonth = transaction.payrollMonth;

    final monthText = payrollMonth == null
        ? 'No payroll month'
        : _monthYear(payrollMonth);

    final effectText = switch (transaction.payrollEffect) {
      TeacherFinancePayrollEffect.increaseSalary => 'Salary Increase',
      TeacherFinancePayrollEffect.decreaseSalary => 'Salary Deduction',
      TeacherFinancePayrollEffect.noPayrollEffect => 'No Payroll Effect',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(
              _transactionIcon(transaction.transactionType),
            ),
          ),
          title: Text(transaction.employeeName),
          subtitle: Text(
            '${_transactionLabel(transaction.transactionType)} • '
            '$effectText\n'
            'Amount: Rs. ${transaction.amount} • '
            'Payroll Month: $monthText',
          ),
          isThreeLine: true,
          trailing: transaction.isPostedToPayroll
              ? const Tooltip(
                  message: 'Posted to Payroll',
                  child: Icon(Icons.verified_outlined),
                )
              : const Tooltip(
                  message: 'Pending Payroll Posting',
                  child: Icon(Icons.schedule_outlined),
                ),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog() async {
    List<dynamic> teachers;
    List<StaffEntity> staffMembers;

    try {
      teachers = await sl<TeacherRepository>().getTeachers();
      staffMembers = await sl<StaffRepository>().getStaff();
    } catch (error) {
      if (!mounted) return;

      _message(error.toString());
      return;
    }

    if (!mounted) return;

    final activeTeachers = teachers
        .where((item) => item.isActive == true)
        .toList()
      ..sort(
        (a, b) => a.fullName.compareTo(b.fullName),
      );

    final activeStaff = staffMembers
        .where((item) => item.isActive)
        .toList()
      ..sort(
        (a, b) => a.fullName.compareTo(b.fullName),
      );

    TeacherFinanceEmployeeType employeeType =
        TeacherFinanceEmployeeType.teacher;

    TeacherFinanceType financeType = TeacherFinanceType.advance;

    TeacherFinanceRecoveryMode recoveryMode =
        TeacherFinanceRecoveryMode.monthly;

    TeacherFinancePayrollEffect salaryAdjustmentEffect =
        TeacherFinancePayrollEffect.increaseSalary;

    _EmployeeOption? selectedEmployee;

    final amountController = TextEditingController();
    final recoveryController = TextEditingController();
    final notesController = TextEditingController();

    DateTime applicableMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month,
    );

    DateTime recoveryStartMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
    );

    List<_EmployeeOption> employeesForType(
      TeacherFinanceEmployeeType value,
    ) {
      if (value == TeacherFinanceEmployeeType.teacher) {
        return activeTeachers
            .map(
              (teacher) => _EmployeeOption(
                id: teacher.employeeId,
                name: teacher.fullName,
                type: TeacherFinanceEmployeeType.teacher,
              ),
            )
            .toList();
      }

      return activeStaff
          .map(
            (staff) => _EmployeeOption(
              id: staff.staffId,
              name: staff.fullName,
              type: TeacherFinanceEmployeeType.staff,
            ),
          )
          .toList();
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final employeeOptions = employeesForType(employeeType);

            final isAdvanceOrLoan =
                financeType == TeacherFinanceType.advance ||
                financeType == TeacherFinanceType.loan;

            final isSalaryAdjustment =
                financeType == TeacherFinanceType.salaryAdjustment;

            final usesPayrollMonth = !isAdvanceOrLoan;

            final showMonthlyRecovery =
                isAdvanceOrLoan &&
                recoveryMode == TeacherFinanceRecoveryMode.monthly;

            return AlertDialog(
              title: const Text('New Employee Finance Entry'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<
                          TeacherFinanceEmployeeType>(
                        initialValue: employeeType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Employee Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: TeacherFinanceEmployeeType.teacher,
                            child: Text('Teacher'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceEmployeeType.staff,
                            child: Text('Staff'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            employeeType = value;
                            selectedEmployee = null;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_EmployeeOption>(
                        key: ValueKey(
                          '${employeeType.name}-${selectedEmployee?.id}',
                        ),
                        initialValue: selectedEmployee,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Employee',
                          helperText: employeeOptions.isEmpty
                              ? 'No active ${_employeeTypeLabel(employeeType).toLowerCase()} found'
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                        items: employeeOptions
                            .map(
                              (employee) =>
                                  DropdownMenuItem<_EmployeeOption>(
                                value: employee,
                                child: Text(
                                  '${employee.name} (${employee.id})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: employeeOptions.isEmpty
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedEmployee = value;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TeacherFinanceType>(
                        initialValue: financeType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Finance Type',
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
                          DropdownMenuItem(
                            value: TeacherFinanceType.salaryAdjustment,
                            child: Text('Salary Adjustment'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.bonus,
                            child: Text('Bonus'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.penalty,
                            child: Text('Penalty'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.allowance,
                            child: Text('Allowance'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.otherDeduction,
                            child: Text('Other Deduction'),
                          ),
                          DropdownMenuItem(
                            value: TeacherFinanceType.otherPayment,
                            child: Text('Other Payment'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            financeType = value;

                            if (financeType ==
                                    TeacherFinanceType.advance ||
                                financeType == TeacherFinanceType.loan) {
                              recoveryMode =
                                  TeacherFinanceRecoveryMode.monthly;
                            } else {
                              recoveryMode =
                                  TeacherFinanceRecoveryMode.none;
                            }

                            recoveryController.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: 'Rs. ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (isAdvanceOrLoan) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<
                            TeacherFinanceRecoveryMode>(
                          initialValue: recoveryMode,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Recovery Mode',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value:
                                  TeacherFinanceRecoveryMode.oneTime,
                              child: Text('One-Time Recovery'),
                            ),
                            DropdownMenuItem(
                              value:
                                  TeacherFinanceRecoveryMode.monthly,
                              child: Text('Monthly Recovery'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              recoveryMode = value;

                              if (value !=
                                  TeacherFinanceRecoveryMode.monthly) {
                                recoveryController.clear();
                              }
                            });
                          },
                        ),
                        if (showMonthlyRecovery) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: recoveryController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly Recovery',
                              prefixText: 'Rs. ',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _MonthPickerTile(
                          title: 'Recovery Start Month',
                          value: recoveryStartMonth,
                          onTap: () async {
                            final selected = await _pickMonth(
                              dialogContext: dialogContext,
                              initialDate: recoveryStartMonth,
                            );

                            if (selected != null) {
                              setDialogState(() {
                                recoveryStartMonth = selected;
                              });
                            }
                          },
                        ),
                      ],
                      if (usesPayrollMonth) ...[
                        const SizedBox(height: 12),
                        _MonthPickerTile(
                          title: 'Applicable Payroll Month',
                          value: applicableMonth,
                          onTap: () async {
                            final selected = await _pickMonth(
                              dialogContext: dialogContext,
                              initialDate: applicableMonth,
                            );

                            if (selected != null) {
                              setDialogState(() {
                                applicableMonth = selected;
                              });
                            }
                          },
                        ),
                      ],
                      if (isSalaryAdjustment) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<
                            TeacherFinancePayrollEffect>(
                          initialValue: salaryAdjustmentEffect,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Salary Adjustment',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: TeacherFinancePayrollEffect
                                  .increaseSalary,
                              child: Text('Increase Salary'),
                            ),
                            DropdownMenuItem(
                              value: TeacherFinancePayrollEffect
                                  .decreaseSalary,
                              child: Text('Decrease Salary'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setDialogState(() {
                              salaryAdjustmentEffect = value;
                            });
                          },
                        ),
                      ],
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
                  onPressed: selectedEmployee == null
                      ? null
                      : () {
                          final amount = int.tryParse(
                                amountController.text.trim(),
                              ) ??
                              0;

                          if (amount <= 0) {
                            _showDialogMessage(
                              dialogContext,
                              'Amount must be greater than zero.',
                            );
                            return;
                          }

                          if (showMonthlyRecovery) {
                            final monthlyRecovery = int.tryParse(
                                  recoveryController.text.trim(),
                                ) ??
                                0;

                            if (monthlyRecovery <= 0) {
                              _showDialogMessage(
                                dialogContext,
                                'Monthly recovery must be greater than zero.',
                              );
                              return;
                            }

                            if (monthlyRecovery > amount) {
                              _showDialogMessage(
                                dialogContext,
                                'Monthly recovery cannot exceed the amount.',
                              );
                              return;
                            }
                          }

                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted && selectedEmployee != null) {
      final amount = int.tryParse(
            amountController.text.trim(),
          ) ??
          0;

      final monthlyRecovery = int.tryParse(
            recoveryController.text.trim(),
          ) ??
          0;

      final user = sl<GetCurrentUserUseCase>()();
      final now = DateTime.now();

      try {
        final isAdvanceOrLoan =
            financeType == TeacherFinanceType.advance ||
            financeType == TeacherFinanceType.loan;

        if (isAdvanceOrLoan) {
          await _repository.createAccount(
            TeacherFinanceAccountEntity(
              id: _repository.generateAccountId(),
              employeeId: selectedEmployee!.id,
              employeeName: selectedEmployee!.name,
              employeeType: selectedEmployee!.type,
              financeType: financeType,
              principalAmount: amount,
              monthlyRecoveryAmount:
                  recoveryMode == TeacherFinanceRecoveryMode.monthly
                      ? monthlyRecovery
                      : 0,
              recoveredAmount: 0,
              outstandingAmount: amount,
              issueDate: now,
              recoveryStartMonth: recoveryStartMonth,
              recoveryMode: recoveryMode,
              status: TeacherFinanceStatus.active,
              approvedBy: user?.uid ?? '',
              notes: notesController.text.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
        } else {
          final transactionType =
              _financeTypeToTransactionType(financeType);

          await _repository.createStandaloneTransaction(
            TeacherFinanceTransactionEntity(
              id: _repository.generateTransactionId(),
              accountId: '',
              employeeId: selectedEmployee!.id,
              employeeName: selectedEmployee!.name,
              transactionType: transactionType,
              amount: amount,
              transactionDate: now,
              payrollId: '',
              payrollMonth: applicableMonth,
              payrollEffectOverride:
                  financeType == TeacherFinanceType.salaryAdjustment
                      ? salaryAdjustmentEffect
                      : null,
              referenceNumber: '',
              notes: _buildStandaloneNotes(
                originalNotes: notesController.text.trim(),
                employeeType: selectedEmployee!.type,
              ),
              createdBy: user?.uid ?? '',
              createdAt: now,
              isPostedToPayroll: false,
              isReversed: false,
              reversedAt: null,
              reversedBy: '',
              reversalReason: '',
            ),
          );
        }

        if (!mounted) return;

        _message(
          '${_typeLabel(financeType)} saved successfully.',
        );

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

  Future<DateTime?> _pickMonth({
    required BuildContext dialogContext,
    required DateTime initialDate,
  }) async {
    final selected = await showDatePicker(
      context: dialogContext,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select Month',
    );

    if (selected == null) {
      return null;
    }

    return DateTime(
      selected.year,
      selected.month,
    );
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

  Future<void> _showLedger(
    TeacherFinanceAccountEntity account,
  ) async {
    try {
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
                  ? const Center(
                      child: Text('No transactions found.'),
                    )
                  : ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (_, _) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = transactions[index];

                        return ListTile(
                          leading: Icon(
                            _transactionIcon(item.transactionType),
                          ),
                          title: Text(
                            _transactionLabel(item.transactionType),
                          ),
                          subtitle: Text(
                            '${_date(item.transactionDate)}'
                            '${item.notes.isEmpty ? '' : '\n${item.notes}'}',
                          ),
                          trailing: Text(
                            'Rs. ${item.amount}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
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
    } catch (error) {
      if (!mounted) return;

      _message(error.toString());
    }
  }

  Future<void> _showRecoveryDialog(
    TeacherFinanceAccountEntity account,
  ) async {
    final defaultAmount = account.recoveryMode ==
            TeacherFinanceRecoveryMode.monthly
        ? account.monthlyRecoveryAmount
        : account.outstandingAmount;

    final amountController = TextEditingController(
      text: defaultAmount.toString(),
    );

    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Manual Recovery - ${account.employeeName}',
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Outstanding: Rs. ${account.outstandingAmount}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Amount',
                    prefixText: 'Rs. ',
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
                final amount = int.tryParse(
                      amountController.text.trim(),
                    ) ??
                    0;

                if (amount <= 0) {
                  _showDialogMessage(
                    dialogContext,
                    'Recovery amount must be greater than zero.',
                  );
                  return;
                }

                if (amount > account.outstandingAmount) {
                  _showDialogMessage(
                    dialogContext,
                    'Recovery amount cannot exceed outstanding balance.',
                  );
                  return;
                }

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
          amount: int.tryParse(
                amountController.text.trim(),
              ) ??
              0,
          transactionType:
              TeacherFinanceTransactionType.manualRecovery,
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

  Future<void> _showCancelDialog(
    TeacherFinanceAccountEntity account,
  ) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Employee Finance Account'),
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
                if (reasonController.text.trim().isEmpty) {
                  _showDialogMessage(
                    dialogContext,
                    'Cancellation reason is required.',
                  );
                  return;
                }

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

  void _showDialogMessage(
    BuildContext dialogContext,
    String message,
  ) {
    ScaffoldMessenger.of(dialogContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
        ),
      );
  }

  bool _isStandaloneTransaction(
    TeacherFinanceTransactionEntity transaction,
  ) {
    return switch (transaction.transactionType) {
      TeacherFinanceTransactionType.bonus ||
      TeacherFinanceTransactionType.allowance ||
      TeacherFinanceTransactionType.penalty ||
      TeacherFinanceTransactionType.otherDeduction ||
      TeacherFinanceTransactionType.otherPayment ||
      TeacherFinanceTransactionType.salaryAdjustment => true,
      _ => false,
    };
  }

  TeacherFinanceTransactionType _financeTypeToTransactionType(
    TeacherFinanceType financeType,
  ) {
    return switch (financeType) {
      TeacherFinanceType.salaryAdjustment =>
        TeacherFinanceTransactionType.salaryAdjustment,
      TeacherFinanceType.bonus =>
        TeacherFinanceTransactionType.bonus,
      TeacherFinanceType.penalty =>
        TeacherFinanceTransactionType.penalty,
      TeacherFinanceType.allowance =>
        TeacherFinanceTransactionType.allowance,
      TeacherFinanceType.otherDeduction =>
        TeacherFinanceTransactionType.otherDeduction,
      TeacherFinanceType.otherPayment =>
        TeacherFinanceTransactionType.otherPayment,
      TeacherFinanceType.advance ||
      TeacherFinanceType.loan =>
        throw StateError(
          'Advance and Loan must be created as accounts.',
        ),
    };
  }

  String _buildStandaloneNotes({
    required String originalNotes,
    required TeacherFinanceEmployeeType employeeType,
  }) {
    final employeeTypeNote =
        'Employee Type: ${employeeType.name}';

    if (originalNotes.isEmpty) {
      return employeeTypeNote;
    }

    return '$employeeTypeNote\n$originalNotes';
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

  String _employeeTypeLabel(
    TeacherFinanceEmployeeType value,
  ) {
    return switch (value) {
      TeacherFinanceEmployeeType.teacher => 'Teacher',
      TeacherFinanceEmployeeType.staff => 'Staff',
    };
  }

  String _statusLabel(TeacherFinanceStatus value) {
    return switch (value) {
      TeacherFinanceStatus.active => 'Active',
      TeacherFinanceStatus.closed => 'Closed',
      TeacherFinanceStatus.cancelled => 'Cancelled',
    };
  }

  String _transactionLabel(
    TeacherFinanceTransactionType value,
  ) {
    return switch (value) {
      TeacherFinanceTransactionType.disbursement =>
        'Disbursement',
      TeacherFinanceTransactionType.payrollRecovery =>
        'Payroll Recovery',
      TeacherFinanceTransactionType.manualRecovery =>
        'Manual Recovery',
      TeacherFinanceTransactionType.adjustment =>
        'Adjustment',
      TeacherFinanceTransactionType.cancellation =>
        'Cancellation',
      TeacherFinanceTransactionType.bonus => 'Bonus',
      TeacherFinanceTransactionType.allowance => 'Allowance',
      TeacherFinanceTransactionType.penalty => 'Penalty',
      TeacherFinanceTransactionType.otherDeduction =>
        'Other Deduction',
      TeacherFinanceTransactionType.otherPayment =>
        'Other Payment',
      TeacherFinanceTransactionType.salaryAdjustment =>
        'Salary Adjustment',
    };
  }

  IconData _transactionIcon(
    TeacherFinanceTransactionType value,
  ) {
    return switch (value) {
      TeacherFinanceTransactionType.disbursement =>
        Icons.account_balance_wallet,
      TeacherFinanceTransactionType.payrollRecovery =>
        Icons.payments,
      TeacherFinanceTransactionType.manualRecovery =>
        Icons.point_of_sale,
      TeacherFinanceTransactionType.adjustment =>
        Icons.tune,
      TeacherFinanceTransactionType.cancellation =>
        Icons.cancel,
      TeacherFinanceTransactionType.bonus =>
        Icons.card_giftcard,
      TeacherFinanceTransactionType.allowance =>
        Icons.add_circle,
      TeacherFinanceTransactionType.penalty =>
        Icons.gpp_bad,
      TeacherFinanceTransactionType.otherDeduction =>
        Icons.remove_circle,
      TeacherFinanceTransactionType.otherPayment =>
        Icons.attach_money,
      TeacherFinanceTransactionType.salaryAdjustment =>
        Icons.calculate,
    };
  }

  String _date(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _monthYear(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');

    return '$month-${value.year}';
  }
}

class _EmployeeOption {
  const _EmployeeOption({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final TeacherFinanceEmployeeType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _EmployeeOption &&
            other.id == id &&
            other.type == type;
  }

  @override
  int get hashCode => Object.hash(id, type);
}

class _MonthPickerTile extends StatelessWidget {
  const _MonthPickerTile({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final month = value.month.toString().padLeft(2, '0');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: title,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_month),
          ),
          child: Text('$month-${value.year}'),
        ),
      ),
    );
  }
}