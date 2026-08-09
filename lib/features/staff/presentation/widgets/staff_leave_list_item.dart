import 'package:flutter/material.dart';

import '../../domain/entities/staff_leave_entity.dart';

class StaffLeaveListItem extends StatelessWidget {
  const StaffLeaveListItem({
    required this.leave,
    super.key,
    this.onTap,
    this.trailing,
  });

  final StaffLeaveEntity leave;
  final VoidCallback? onTap;
  final Widget? trailing;

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _leaveTypeLabel(StaffLeaveType type) {
    switch (type) {
      case StaffLeaveType.casual:
        return 'Casual Leave';
      case StaffLeaveType.sick:
        return 'Sick Leave';
      case StaffLeaveType.annual:
        return 'Annual Leave';
      case StaffLeaveType.unpaid:
        return 'Unpaid Leave';
      case StaffLeaveType.other:
        return 'Other Leave';
    }
  }

  String _durationLabel(StaffLeaveDuration duration) {
    switch (duration) {
      case StaffLeaveDuration.fullDay:
        return 'Full Day';
      case StaffLeaveDuration.halfDay:
        return 'Half Day';
    }
  }

  String _statusLabel(StaffLeaveStatus status) {
    switch (status) {
      case StaffLeaveStatus.pending:
        return 'Pending';
      case StaffLeaveStatus.approved:
        return 'Approved';
      case StaffLeaveStatus.rejected:
        return 'Rejected';
      case StaffLeaveStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(StaffLeaveStatus status) {
    switch (status) {
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
    final statusColor = _statusColor(leave.status);

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
              final compact = constraints.maxWidth < 720;

              final staffInformation = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event_note_outlined,
                      color:
                          theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.staffName.trim().isEmpty
                              ? 'Unnamed Staff Member'
                              : leave.staffName.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${leave.staffCode} | '
                          '${leave.designation}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            color: theme
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _leaveTypeLabel(leave.leaveType),
                          style:
                              theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final leaveInformation = Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Text(
                    leave.startDate.year == leave.endDate.year &&
                            leave.startDate.month ==
                                leave.endDate.month &&
                            leave.startDate.day ==
                                leave.endDate.day
                        ? _formatDate(leave.startDate)
                        : '${_formatDate(leave.startDate)} - '
                            '${_formatDate(leave.endDate)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${leave.totalDays.toStringAsFixed(
                      leave.totalDays == leave.totalDays.roundToDouble()
                          ? 0
                          : 1,
                    )} day(s) | ${_durationLabel(leave.duration)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    avatar: Icon(
                      leave.isApproved
                          ? Icons.check_circle_outline
                          : leave.isRejected
                              ? Icons.cancel_outlined
                              : leave.isCancelled
                                  ? Icons.block_outlined
                                  : Icons.pending_outlined,
                      size: 18,
                      color: statusColor,
                    ),
                    label: Text(
                      _statusLabel(leave.status),
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

              if (compact) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    staffInformation,
                    const SizedBox(height: 16),
                    leaveInformation,
                    if (trailing != null) ...[
                      const SizedBox(height: 14),
                      trailing!,
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: staffInformation,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Text(
                      leave.reason.trim().isEmpty
                          ? 'No reason provided'
                          : leave.reason.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  leaveInformation,
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
