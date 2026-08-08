import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../../domain/entities/salary_history_entity.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';
import 'teacher_finance_page.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    final actorId = sl<GetCurrentUserUseCase>()()?.uid ?? '';
    return BlocProvider(
      create: (_) => sl<PayrollBloc>()..add(LoadPayroll(actorId: actorId)),
      child: const _PayrollView(),
    );
  }
}

class _PayrollView extends StatefulWidget {
  const _PayrollView();

  @override
  State<_PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<_PayrollView> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  String get _actorId => sl<GetCurrentUserUseCase>()()?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<PayrollBloc, PayrollState>(
        listener: (context, state) {
          if (state is PayrollLoaded) {
            final message = state.error ?? state.message;
            if (message != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(message)));
            }
          }
        },
        builder: (context, state) {
          if (state is PayrollInitial || state is PayrollLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PayrollFailure) {
            return Center(child: Text(state.message));
          }
          final data = state as PayrollLoaded;
          final records = data.records.where((record) {
            return record.payrollMonth.year == _selectedMonth.year &&
                record.payrollMonth.month == _selectedMonth.month;
          }).toList()..sort((a, b) => a.employeeName.compareTo(b.employeeName));
          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              _toolbar(context, data),
              _summary(records),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text('No payroll generated for this month.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, index) =>
                            _payrollCard(context, records[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _toolbar(BuildContext context, PayrollLoaded data) => Padding(
    padding: const EdgeInsets.all(16),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _pickMonth(context),
          icon: const Icon(Icons.calendar_month),
          label: Text(
            '${_selectedMonth.month.toString().padLeft(2, '0')}-${_selectedMonth.year}',
          ),
        ),
        FilledButton.icon(
          onPressed: data.isProcessing || data.employees.isEmpty
              ? null
              : () => context.read<PayrollBloc>().add(
                  GeneratePayrollRequested(
                    month: _selectedMonth,
                    actorId: _actorId,
                  ),
                ),
          icon: const Icon(Icons.calculate_outlined),
          label: const Text('Generate Payroll'),
        ),
        FilledButton.tonalIcon(
          onPressed: data.isProcessing
              ? null
              : () => _showIncrementDialog(context, data.employees),
          icon: const Icon(Icons.trending_up),
          label: const Text('Salary Increment'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _showHistoryDialog(context, data.salaryHistory),
          icon: const Icon(Icons.history),
          label: const Text('Salary History'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: (_) => const TeacherFinancePage()),
          ),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: const Text('Employee Finance'),
        ),
      ],
    ),
  );

  Widget _summary(List<PayrollRecordEntity> records) {
    final total = records.fold<int>(0, (sum, item) => sum + item.netSalary);
    final paid = records
        .where((item) => item.paymentStatus == PayrollPaymentStatus.paid)
        .length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _summaryCard('Employees', '${records.length}', Icons.people_outline),
          _summaryCard('Total Payroll', _money(total), Icons.payments_outlined),
          _summaryCard(
            'Generated',
            '${records.length - paid}',
            Icons.pending_actions,
          ),
          _summaryCard('Paid', '$paid', Icons.check_circle_outline),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) => SizedBox(
    width: 210,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _payrollCard(BuildContext context, PayrollRecordEntity record) {
    final paid = record.paymentStatus == PayrollPaymentStatus.paid;
    final type = record.employeeType == PayrollEmployeeType.teacher
        ? 'Teacher'
        : 'Staff';
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            record.employeeType == PayrollEmployeeType.teacher
                ? Icons.school_outlined
                : Icons.badge_outlined,
          ),
        ),
        title: Text(record.employeeName),
        subtitle: Text(
          '$type • Profile salary ${_money(record.basicSalary)} • '
          'Finance additions ${_money(record.bonus)} • '
          'Finance deductions ${_money(record.deductions + record.advanceDeduction + record.loanDeduction)}',
        ),
        trailing: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(record.netSalary),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(paid ? 'PAID' : 'GENERATED'),
              ],
            ),
            if (!paid)
              FilledButton(
                onPressed: () => context.read<PayrollBloc>().add(
                  UpdatePayrollStatusRequested(
                    payrollId: record.id,
                    status: PayrollPaymentStatus.paid,
                    actorId: _actorId,
                  ),
                ),
                child: const Text('Mark Paid'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select payroll month',
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _showIncrementDialog(
    BuildContext context,
    List<PayrollEmployeeEntity> employees,
  ) async {
    final sorted = List<PayrollEmployeeEntity>.from(employees)
      ..sort((a, b) => a.name.compareTo(b.name));
    final controllers = {
      for (final employee in sorted)
        _employeeKey(employee): TextEditingController(),
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salary Increment'),
          content: SizedBox(
            width: 900,
            height: 560,
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Enter increment amounts only for employees whose salary should change.',
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final employee = sorted[index];
                      final controller = controllers[_employeeKey(employee)]!;
                      final increment = int.tryParse(controller.text) ?? 0;
                      return ListTile(
                        leading: Icon(
                          employee.type == PayrollEmployeeType.teacher
                              ? Icons.school_outlined
                              : Icons.badge_outlined,
                        ),
                        title: Text(employee.name),
                        subtitle: Text(
                          '${employee.code} • Current ${_money(employee.monthlySalary)} • New ${_money(employee.monthlySalary + increment)}',
                        ),
                        trailing: SizedBox(
                          width: 180,
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Increment amount',
                              prefixText: 'Rs. ',
                            ),
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Apply Increments'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && context.mounted) {
      final increments = sorted
          .map((employee) {
            return SalaryIncrementRequest(
              employeeId: employee.id,
              employeeCode: employee.code,
              employeeName: employee.name,
              employeeType: employee.type,
              currentSalary: employee.monthlySalary,
              incrementAmount:
                  int.tryParse(controllers[_employeeKey(employee)]!.text) ?? 0,
            );
          })
          .where((item) => item.incrementAmount > 0)
          .toList();
      context.read<PayrollBloc>().add(
        ApplySalaryIncrementsRequested(
          increments: increments,
          actorId: _actorId,
        ),
      );
    }
    for (final controller in controllers.values) {
      controller.dispose();
    }
  }

  Future<void> _showHistoryDialog(
    BuildContext context,
    List<SalaryHistoryEntity> history,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Salary History'),
        content: SizedBox(
          width: 900,
          height: 560,
          child: history.isEmpty
              ? const Center(child: Text('No salary history available.'))
              : ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final item = history[index];
                    final type =
                        item.employeeType == PayrollEmployeeType.teacher
                        ? 'Teacher'
                        : 'Staff';
                    return ListTile(
                      leading: Icon(
                        item.changeType == 'opening'
                            ? Icons.flag_outlined
                            : Icons.trending_up,
                      ),
                      title: Text(item.employeeName),
                      subtitle: Text(
                        '$type • ${item.employeeCode} • ${_date(item.effectiveAt)}\n'
                        '${item.changeType == 'opening' ? 'Opening salary' : 'Increment ${_money(item.incrementAmount)}'}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '${_money(item.previousSalary)} → ${_money(item.newSalary)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _money(int value) => 'Rs. ${value.toString()}';
  String _employeeKey(PayrollEmployeeEntity employee) =>
      '${employee.type.name}:${employee.id}';
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}-${value.month.toString().padLeft(2, '0')}-${value.year}';
}
