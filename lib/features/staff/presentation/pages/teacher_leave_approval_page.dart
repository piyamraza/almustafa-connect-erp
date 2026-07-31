import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../teacher_leave/teacher_leave_helpers.dart';
import '../widgets/teacher_leave_list_item.dart';

class TeacherLeaveApprovalPage extends StatelessWidget {
  const TeacherLeaveApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) =>
          sl<StaffLeaveBloc>()..add(const LoadPendingStaffLeavesEvent()),
      child: const _TeacherLeaveApprovalView(),
    );
  }
}

class _TeacherLeaveApprovalView extends StatelessWidget {
  const _TeacherLeaveApprovalView();

  Future<void> _showDecisionDialog({
    required BuildContext context,
    required StaffLeaveEntity leave,
    required StaffLeaveStatus status,
  }) async {
    final bloc = context.read<StaffLeaveBloc>();
    final remarksController = TextEditingController();
    final reviewedByController = TextEditingController(text: 'Admin');

    final result = await showDialog<_DecisionData>(
      context: context,
      builder: (dialogContext) {
        final approving = status == StaffLeaveStatus.approved;

        return AlertDialog(
          title: Text(
            approving ? 'Approve Teacher Leave' : 'Reject Teacher Leave',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${leave.staffName} • '
                  '${teacherLeaveTypeLabel(leave.leaveType)} • '
                  '${teacherLeaveDaysLabel(leave.totalDays)} day(s)',
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: reviewedByController,
                  decoration: const InputDecoration(
                    labelText: 'Reviewed By',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: remarksController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: approving
                        ? 'Approval Remarks'
                        : 'Rejection Remarks',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reviewedBy = reviewedByController.text.trim();

                if (reviewedBy.isEmpty) {
                  return;
                }

                Navigator.of(dialogContext).pop(
                  _DecisionData(
                    reviewedBy: reviewedBy,
                    remarks: remarksController.text.trim(),
                  ),
                );
              },
              child: Text(approving ? 'Approve' : 'Reject'),
            ),
          ],
        );
      },
    );

    remarksController.dispose();
    reviewedByController.dispose();

    if (result == null) {
      return;
    }

    bloc.add(
      UpdateStaffLeaveStatusEvent(
        leave: leave,
        status: status,
        approvalRemarks: result.remarks,
        approvedBy: result.reviewedBy,
      ),
    );
  }

  void _handleState(BuildContext context, StaffLeaveState state) {
    if (state is StaffLeaveError) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    if (state is StaffLeaveLoaded && state.successMessage != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Teacher Leave Approvals'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                context.read<StaffLeaveBloc>().add(
                  const LoadPendingStaffLeavesEvent(),
                );
              },
              icon: const Icon(Icons.refresh_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: BlocBuilder<StaffLeaveBloc, StaffLeaveState>(
          builder: (context, state) {
            if (state is StaffLeaveInitial || state is StaffLeaveLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is StaffLeaveError) {
              return _ApprovalMessageView(
                icon: Icons.error_outline,
                title: 'Unable to load approvals',
                message: state.message,
              );
            }

            if (state is StaffLeaveLoaded) {
              final leaves = state.leaves.where(isTeacherLeave).toList();

              if (leaves.isEmpty) {
                return const _ApprovalMessageView(
                  icon: Icons.approval_outlined,
                  title: 'No pending approvals',
                  message: 'There are no pending teacher leave requests.',
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: leaves.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: 12);
                    },
                    itemBuilder: (context, index) {
                      final leave = leaves[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TeacherLeaveListItem(leave: leave),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  _showDecisionDialog(
                                    context: context,
                                    leave: leave,
                                    status: StaffLeaveStatus.rejected,
                                  );
                                },
                                icon: const Icon(Icons.close_outlined),
                                label: const Text('Reject'),
                              ),
                              FilledButton.icon(
                                onPressed: () {
                                  _showDecisionDialog(
                                    context: context,
                                    leave: leave,
                                    status: StaffLeaveStatus.approved,
                                  );
                                },
                                icon: const Icon(Icons.check_outlined),
                                label: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _DecisionData {
  const _DecisionData({required this.reviewedBy, required this.remarks});

  final String reviewedBy;
  final String remarks;
}

class _ApprovalMessageView extends StatelessWidget {
  const _ApprovalMessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 68, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
