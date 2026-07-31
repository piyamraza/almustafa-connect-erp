import 'package:flutter/material.dart';

import '../../domain/entities/staff_leave_entity.dart';
import '../teacher_leave/teacher_leave_helpers.dart';

class TeacherLeaveListItem extends StatelessWidget {
  const TeacherLeaveListItem({required this.leave, super.key});

  final StaffLeaveEntity leave;

  Color _statusColor() {
    switch (leave.status) {
      case StaffLeaveStatus.pending:
        return Colors.orange;
      case StaffLeaveStatus.approved:
        return Colors.green;
      case StaffLeaveStatus.rejected:
        return Colors.red;
      case StaffLeaveStatus.cancelled:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        leave.staffName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Chip(
                      label: Text(teacherLeaveStatusLabel(leave.status)),
                      side: BorderSide.none,
                      backgroundColor: statusColor.withValues(alpha: 0.14),
                      labelStyle: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  '${leave.staffCode} • ${leave.designation}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InformationChip(
                      icon: Icons.category_outlined,
                      label: teacherLeaveTypeLabel(leave.leaveType),
                    ),
                    _InformationChip(
                      icon: Icons.timelapse_outlined,
                      label: teacherLeaveDurationLabel(leave.duration),
                    ),
                    _InformationChip(
                      icon: Icons.calendar_month_outlined,
                      label:
                          '${teacherLeaveDateLabel(leave.startDate)}'
                          ' - '
                          '${teacherLeaveDateLabel(leave.endDate)}',
                    ),
                    _InformationChip(
                      icon: Icons.calculate_outlined,
                      label: '${teacherLeaveDaysLabel(leave.totalDays)} day(s)',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(leave.reason, style: theme.textTheme.bodyMedium),
                if (leave.approvalRemarks.trim().isNotEmpty ||
                    leave.approvedBy.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Divider(color: theme.colorScheme.outlineVariant),
                  if (leave.approvedBy.trim().isNotEmpty)
                    Text(
                      'Reviewed by: ${leave.approvedBy}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (leave.approvalRemarks.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Remarks: ${leave.approvalRemarks}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
              ],
            );

            if (compact) {
              return details;
            }

            return details;
          },
        ),
      ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
