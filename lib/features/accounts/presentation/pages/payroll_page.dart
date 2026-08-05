import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../authentication/domain/usecases/get_current_user_usecase.dart';
import '../../../staff/domain/repositories/staff_repository.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';
import '../bloc/payroll_state.dart';

class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PayrollBloc>()..add(const LoadPayroll()),
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
            final text = state.error ?? state.message;
            if (text != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(text)));
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
          final records = data.records
              .where(
                (item) =>
                    item.payrollMonth.year == _selectedMonth.year &&
                    item.payrollMonth.month == _selectedMonth.month,
              )
              .toList();

          return Column(
            children: [
              if (data.isProcessing) const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _showProfileDialog(context),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Salary Profile'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickMonth(context),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        '${_selectedMonth.month.toString().padLeft(2, '0')}-${_selectedMonth.year}',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: data.profiles.where((p) => p.isActive).isEmpty
                          ? null
                          : () {
                              final user = sl<GetCurrentUserUseCase>()();
                              context.read<PayrollBloc>().add(
                                GeneratePayrollRequested(
                                  month: _selectedMonth,
                                  actorId: user?.uid ?? '',
                                ),
                              );
                            },
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Generate Payroll'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          'No payroll records for the selected month.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(record.employeeName),
                              subtitle: Text(
                                '${record.paymentStatus.name.toUpperCase()} • '
                                'Gross Rs. ${record.grossSalary}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Rs. ${record.netSalary}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        _handleAction(context, record, value),
                                    itemBuilder: (_) => [
                                      if (record.paymentStatus ==
                                          PayrollPaymentStatus.generated)
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Adjust Salary'),
                                        ),
                                      if (record.paymentStatus ==
                                          PayrollPaymentStatus.generated)
                                        const PopupMenuItem(
                                          value: 'approve',
                                          child: Text('Approve'),
                                        ),
                                      if (record.paymentStatus ==
                                          PayrollPaymentStatus.approved)
                                        const PopupMenuItem(
                                          value: 'pay',
                                          child: Text('Mark Paid'),
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

  Future<void> _pickMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select any date in the payroll month',
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  Future<void> _showProfileDialog(BuildContext context) async {
    final List<_PayrollEmployeeOption> teachers;
    final List<_PayrollEmployeeOption> staff;

    try {
      final teacherRecords = await sl<TeacherRepository>().getTeachers();
      final staffRecords = await sl<StaffRepository>().getStaff();
      teachers =
          teacherRecords
              .where((item) => item.isActive)
              .map(
                (item) => _PayrollEmployeeOption(
                  id: item.id,
                  employeeId: item.employeeId,
                  name: item.fullName,
                ),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
      staff =
          staffRecords
              .where((item) => item.isActive)
              .map(
                (item) => _PayrollEmployeeOption(
                  id: item.id,
                  employeeId: item.staffId,
                  name: item.fullName,
                ),
              )
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load employees: $error')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final basic = TextEditingController();
    final allowances = TextEditingController(text: '0');
    final deductions = TextEditingController(text: '0');
    var employeeType = PayrollEmployeeType.teacher;
    _PayrollEmployeeOption? selectedEmployee;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Salary Profile'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<PayrollEmployeeType>(
                    initialValue: employeeType,
                    decoration: const InputDecoration(
                      labelText: 'Employee Type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: PayrollEmployeeType.teacher,
                        child: Text('Teacher'),
                      ),
                      DropdownMenuItem(
                        value: PayrollEmployeeType.administrativeStaff,
                        child: Text('Staff'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          employeeType = value;
                          selectedEmployee = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_PayrollEmployeeOption>(
                    key: ValueKey(employeeType),
                    initialValue: selectedEmployee,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: employeeType == PayrollEmployeeType.teacher
                          ? 'Select Teacher'
                          : 'Select Staff',
                    ),
                    items:
                        (employeeType == PayrollEmployeeType.teacher
                                ? teachers
                                : staff)
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  '${item.name} (${item.employeeId})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => selectedEmployee = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: basic,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Basic Salary',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: allowances,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fixed Allowances',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deductions,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fixed Deductions',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedEmployee == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();
      final employee = selectedEmployee!;
      context.read<PayrollBloc>().add(
        SavePayrollProfileRequested(
          PayrollProfileEntity(
            id: employee.id,
            employeeId: employee.employeeId,
            employeeName: employee.name,
            employeeType: employeeType,
            basicSalary: int.tryParse(basic.text.trim()) ?? 0,
            fixedAllowances: int.tryParse(allowances.text.trim()) ?? 0,
            fixedDeductions: int.tryParse(deductions.text.trim()) ?? 0,
            effectiveFrom: now,
            isActive: true,
            createdAt: now,
            updatedAt: now,
          ),
        ),
      );
    }

    basic.dispose();
    allowances.dispose();
    deductions.dispose();
  }

  Future<void> _handleAction(
    BuildContext context,
    PayrollRecordEntity record,
    String action,
  ) async {
    final user = sl<GetCurrentUserUseCase>()();
    if (action == 'approve') {
      context.read<PayrollBloc>().add(
        UpdatePayrollStatusRequested(
          payrollId: record.id,
          status: PayrollPaymentStatus.approved,
          actorId: user?.uid ?? '',
        ),
      );
      return;
    }
    if (action == 'pay') {
      final method = TextEditingController(text: 'Cash');
      final reference = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mark Salary Paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: method,
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reference,
                decoration: const InputDecoration(
                  labelText: 'Reference Number',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        context.read<PayrollBloc>().add(
          UpdatePayrollStatusRequested(
            payrollId: record.id,
            status: PayrollPaymentStatus.paid,
            actorId: user?.uid ?? '',
            paymentMethod: method.text.trim(),
            referenceNumber: reference.text.trim(),
          ),
        );
      }
      method.dispose();
      reference.dispose();
      return;
    }
    if (action == 'edit') {
      final bonus = TextEditingController(text: record.bonus.toString());
      final absence = TextEditingController(
        text: record.absenceDeduction.toString(),
      );
      final advance = TextEditingController(
        text: record.advanceDeduction.toString(),
      );
      final loan = TextEditingController(text: record.loanDeduction.toString());
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Adjust Salary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bonus,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bonus'),
              ),
              TextField(
                controller: absence,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Absence Deduction',
                ),
              ),
              TextField(
                controller: advance,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Advance Deduction',
                ),
              ),
              TextField(
                controller: loan,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Loan Deduction'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        final bonusValue = int.tryParse(bonus.text) ?? 0;
        final absenceValue = int.tryParse(absence.text) ?? 0;
        final advanceValue = int.tryParse(advance.text) ?? 0;
        final loanValue = int.tryParse(loan.text) ?? 0;
        final gross = record.basicSalary + record.allowances + bonusValue;
        final totalDeductions =
            record.deductions + absenceValue + advanceValue + loanValue;
        context.read<PayrollBloc>().add(
          SavePayrollRecordRequested(
            PayrollRecordEntity(
              id: record.id,
              employeeId: record.employeeId,
              employeeName: record.employeeName,
              payrollMonth: record.payrollMonth,
              basicSalary: record.basicSalary,
              allowances: record.allowances,
              deductions: record.deductions,
              absenceDeduction: absenceValue,
              advanceDeduction: advanceValue,
              loanDeduction: loanValue,
              bonus: bonusValue,
              grossSalary: gross,
              netSalary: gross - totalDeductions,
              paymentStatus: record.paymentStatus,
              paymentDate: record.paymentDate,
              paymentMethod: record.paymentMethod,
              referenceNumber: record.referenceNumber,
              remarks: record.remarks,
              generatedBy: record.generatedBy,
              approvedBy: record.approvedBy,
              approvedAt: record.approvedAt,
              paidBy: record.paidBy,
              createdAt: record.createdAt,
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
      bonus.dispose();
      absence.dispose();
      advance.dispose();
      loan.dispose();
    }
  }
}

class _PayrollEmployeeOption {
  const _PayrollEmployeeOption({
    required this.id,
    required this.employeeId,
    required this.name,
  });

  final String id;
  final String employeeId;
  final String name;
}
