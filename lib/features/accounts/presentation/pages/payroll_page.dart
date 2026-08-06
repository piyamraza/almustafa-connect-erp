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
import 'teacher_finance_page.dart';

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
                    FilledButton.tonalIcon(
                      onPressed: data.profiles.isEmpty
                          ? null
                          : () => _showSalaryProfilesDialog(
                              context,
                              data.profiles,
                            ),
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Salary Profiles'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const TeacherFinancePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Employee Finance'),
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
                                '${record.paymentStatus.name.toUpperCase()} • Gross Rs. ${record.grossSalary}\n'
                                'Advance Rs. ${record.advanceDeduction} • Loan Rs. ${record.loanDeduction} • Bonus/Additions Rs. ${record.bonus}',
                              ),
                              isThreeLine: true,
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
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: Text('View Details'),
                                      ),
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

  Future<void> _showSalaryProfilesDialog(
    BuildContext context,
    List<PayrollProfileEntity> profiles,
  ) async {
    final sortedProfiles = List<PayrollProfileEntity>.from(profiles)
      ..sort(
        (a, b) => a.employeeName.toLowerCase().compareTo(
          b.employeeName.toLowerCase(),
        ),
      );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Salary Profiles'),
          content: SizedBox(
            width: 700,
            height: 480,
            child: sortedProfiles.isEmpty
                ? const Center(child: Text('No salary profiles found.'))
                : ListView.separated(
                    itemCount: sortedProfiles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final profile = sortedProfiles[index];
                      final typeLabel =
                          profile.employeeType == PayrollEmployeeType.teacher
                          ? 'Teacher'
                          : 'Staff';

                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            profile.isActive
                                ? Icons.person_outline
                                : Icons.person_off_outlined,
                          ),
                        ),
                        title: Text(profile.employeeName),
                        subtitle: Text(
                          '$typeLabel • ${profile.employeeId}\n'
                          'Basic Rs. ${profile.basicSalary} • '
                          'Allowances Rs. ${profile.fixedAllowances} • '
                          'Deductions Rs. ${profile.fixedDeductions}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Profile Actions',
                          onSelected: (action) {
                            Navigator.of(dialogContext).pop();

                            if (action == 'edit') {
                              _showProfileDialog(
                                context,
                                existingProfile: profile,
                              );
                              return;
                            }

                            if (action == 'toggle') {
                              _confirmProfileStatusChange(context, profile);
                              return;
                            }

                            if (action == 'delete') {
                              _confirmProfileDelete(context, profile);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'toggle',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  profile.isActive
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                ),
                                title: Text(
                                  profile.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmProfileDelete(
    BuildContext context,
    PayrollProfileEntity profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Salary Profile?'),
        content: Text(
          'Delete the salary profile for ${profile.employeeName}?\n\n'
          'The profile will only be deleted if it has never been used in '
          'payroll history. Otherwise, the system will ask you to deactivate '
          'it instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PayrollBloc>().add(
        DeletePayrollProfileRequested(profile.id),
      );
    }
  }

  Future<void> _confirmProfileStatusChange(
    BuildContext context,
    PayrollProfileEntity profile,
  ) async {
    final nextStatus = !profile.isActive;
    final actionText = nextStatus ? 'Activate' : 'Deactivate';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$actionText Salary Profile?'),
        content: Text(
          nextStatus
              ? 'This profile will be included in future payroll generation.'
              : 'This profile will be excluded from future payroll generation. '
                    'Existing payroll records will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PayrollBloc>().add(
        SetPayrollProfileActiveRequested(
          profileId: profile.id,
          isActive: nextStatus,
        ),
      );
    }
  }

  Future<void> _showProfileDialog(
    BuildContext context, {
    PayrollProfileEntity? existingProfile,
  }) async {
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

    final basic = TextEditingController(
      text: existingProfile?.basicSalary.toString() ?? '',
    );
    final allowances = TextEditingController(
      text: existingProfile?.fixedAllowances.toString() ?? '0',
    );
    final deductions = TextEditingController(
      text: existingProfile?.fixedDeductions.toString() ?? '0',
    );

    var employeeType =
        existingProfile?.employeeType ?? PayrollEmployeeType.teacher;

    final availableEmployees = employeeType == PayrollEmployeeType.teacher
        ? teachers
        : staff;

    _PayrollEmployeeOption? selectedEmployee;

    if (existingProfile != null) {
      for (final employee in availableEmployees) {
        if (employee.id == existingProfile.id ||
            employee.employeeId == existingProfile.employeeId) {
          selectedEmployee = employee;
          break;
        }
      }

      selectedEmployee ??= _PayrollEmployeeOption(
        id: existingProfile.id,
        employeeId: existingProfile.employeeId,
        name: existingProfile.employeeName,
      );
    }

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existingProfile == null
                ? 'Add Salary Profile'
                : 'Edit Salary Profile',
          ),
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
                    onChanged: existingProfile != null
                        ? null
                        : (value) {
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
                    onChanged: existingProfile != null
                        ? null
                        : (value) {
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
              child: Text(existingProfile == null ? 'Save' : 'Update'),
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
            id: existingProfile?.id ?? employee.id,
            employeeId: existingProfile?.employeeId ?? employee.employeeId,
            employeeName: existingProfile?.employeeName ?? employee.name,
            employeeType: existingProfile?.employeeType ?? employeeType,
            basicSalary: int.tryParse(basic.text.trim()) ?? 0,
            fixedAllowances: int.tryParse(allowances.text.trim()) ?? 0,
            fixedDeductions: int.tryParse(deductions.text.trim()) ?? 0,
            effectiveFrom: existingProfile?.effectiveFrom ?? now,
            isActive: existingProfile?.isActive ?? true,
            createdAt: existingProfile?.createdAt ?? now,
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
    if (action == 'details') {
      await _showPayrollDetails(context, record);
      return;
    }

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
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Advance Deduction (Automatic)',
                  border: OutlineInputBorder(),
                ),
                child: Text('Rs. ${record.advanceDeduction}'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Loan Deduction (Automatic)',
                  border: OutlineInputBorder(),
                ),
                child: Text('Rs. ${record.loanDeduction}'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Advance and Loan deductions are controlled by Employee Finance and cannot be edited here.',
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
        final gross = record.basicSalary + record.allowances + bonusValue;
        final totalDeductions =
            record.deductions +
            absenceValue +
            record.advanceDeduction +
            record.loanDeduction;

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
              advanceDeduction: record.advanceDeduction,
              loanDeduction: record.loanDeduction,
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
    }
  }

  Future<void> _showPayrollDetails(
    BuildContext context,
    PayrollRecordEntity record,
  ) async {
    final totalDeductions =
        record.deductions +
        record.absenceDeduction +
        record.advanceDeduction +
        record.loanDeduction;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(record.employeeName),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Employee ID', record.employeeId),
                _detailRow(
                  'Payroll Month',
                  '${record.payrollMonth.month.toString().padLeft(2, '0')}-${record.payrollMonth.year}',
                ),
                _detailRow('Status', record.paymentStatus.name.toUpperCase()),
                const Divider(height: 28),
                _detailRow('Basic Salary', 'Rs. ${record.basicSalary}'),
                _detailRow('Fixed Allowances', 'Rs. ${record.allowances}'),
                _detailRow('Bonus / Additions', 'Rs. ${record.bonus}'),
                _detailRow(
                  'Gross Salary',
                  'Rs. ${record.grossSalary}',
                  bold: true,
                ),
                const Divider(height: 28),
                _detailRow(
                  'Fixed / Other Deductions',
                  'Rs. ${record.deductions}',
                ),
                _detailRow(
                  'Absence Deduction',
                  'Rs. ${record.absenceDeduction}',
                ),
                _detailRow(
                  'Advance Recovery',
                  'Rs. ${record.advanceDeduction}',
                ),
                _detailRow('Loan Recovery', 'Rs. ${record.loanDeduction}'),
                _detailRow(
                  'Total Deductions',
                  'Rs. $totalDeductions',
                  bold: true,
                ),
                const Divider(height: 28),
                _detailRow('Net Salary', 'Rs. ${record.netSalary}', bold: true),
                if (record.remarks.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Automatic Employee Finance Details',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(record.remarks),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 16),
          Text(value, style: style),
        ],
      ),
    );
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
