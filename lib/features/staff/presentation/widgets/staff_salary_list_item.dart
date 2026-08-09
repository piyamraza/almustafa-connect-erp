import 'package:flutter/material.dart';

import '../../domain/entities/staff_salary_entity.dart';

class StaffSalaryListItem extends StatelessWidget {
  const StaffSalaryListItem({
    required this.salary,
    required this.onTap,
    super.key,
  });

  final StaffSalaryEntity salary;
  final VoidCallback onTap;

  String _formatCurrency(double value) {
    final amount = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);

    return 'Rs. $amount';
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPaid = salary.isPaid;
    final statusColor =
        isPaid ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;

              final staffInformation = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: theme
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          salary.staffName.trim().isEmpty
                              ? 'Unnamed Staff Member'
                              : salary.staffName.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${salary.staffCode} | '
                          '${salary.designation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMonth(salary.salaryMonth),
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final salaryInformation = Column(
                crossAxisAlignment: isCompact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(salary.netSalary),
                    style:
                        theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Chip(
                    avatar: Icon(
                      isPaid
                          ? Icons.check_circle_outline
                          : Icons.pending_outlined,
                      size: 18,
                      color: statusColor,
                    ),
                    label: Text(
                      isPaid ? 'Paid' : 'Unpaid',
                    ),
                    side: BorderSide.none,
                    backgroundColor:
                        statusColor.withValues(alpha: 0.12),
                    labelStyle: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    staffInformation,
                    const SizedBox(height: 16),
                    salaryInformation,
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Basic: ${_formatCurrency(salary.basicSalary)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: staffInformation,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _AmountLabel(
                          label: 'Basic',
                          value: _formatCurrency(
                            salary.basicSalary,
                          ),
                        ),
                        _AmountLabel(
                          label: 'Allowance',
                          value: _formatCurrency(
                            salary.allowance,
                          ),
                        ),
                        _AmountLabel(
                          label: 'Deduction',
                          value: _formatCurrency(
                            salary.deduction +
                                salary.attendanceDeduction,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  salaryInformation,
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
