import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../widgets/staff_leave_form.dart';

class AddStaffLeavePage extends StatelessWidget {
  const AddStaffLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _AddStaffLeaveView(),
    );
  }
}

class _AddStaffLeaveView extends StatefulWidget {
  const _AddStaffLeaveView();

  @override
  State<_AddStaffLeaveView> createState() =>
      _AddStaffLeaveViewState();
}

class _AddStaffLeaveViewState
    extends State<_AddStaffLeaveView> {
  late final Future<List<StaffEntity>> _staffFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _staffFuture = _loadStaff();
  }

  Future<List<StaffEntity>> _loadStaff() async {
    final staff = await sl<StaffRepository>().getStaff();

    final activeStaff = staff
        .where((staffMember) => staffMember.isActive)
        .toList();

    activeStaff.sort(
      (first, second) => first.fullName
          .toLowerCase()
          .compareTo(second.fullName.toLowerCase()),
    );

    return activeStaff;
  }

  Future<void> _saveLeave(
    StaffLeaveFormData data,
  ) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final leaveId =
        '${data.staff.id}_${now.microsecondsSinceEpoch}';

    final leave = StaffLeaveEntity(
      id: leaveId,
      staffId: data.staff.id,
      staffCode: data.staff.staffId,
      staffName: data.staff.fullName,
      designation: data.staff.designation,
      leaveType: data.leaveType,
      startDate: data.startDate,
      endDate: data.endDate,
      duration: data.duration,
      totalDays: data.totalDays,
      reason: data.reason,
      status: StaffLeaveStatus.pending,
      approvalRemarks: '',
      approvedBy: '',
      createdAt: now,
      updatedAt: now,
    );

    context.read<StaffLeaveBloc>().add(
          SaveStaffLeaveEvent(leave),
        );
  }

  void _handleState(
    BuildContext context,
    StaffLeaveState state,
  ) {
    if (state is StaffLeaveError) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.message),
            behavior: SnackBarBehavior.floating,
          ),
        );

      return;
    }

    if (state is StaffLeaveLoaded &&
        state.successMessage != null) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Staff Leave'),
        ),
        body: SafeArea(
          child: FutureBuilder<List<StaffEntity>>(
            future: _staffFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return _LoadStaffError(
                  message: snapshot.error.toString(),
                );
              }

              final staff =
                  snapshot.data ?? const <StaffEntity>[];

              if (staff.isEmpty) {
                return const _NoStaffView();
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      constraints.maxWidth >= 1000
                          ? 32.0
                          : constraints.maxWidth >= 700
                              ? 24.0
                              : 16.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1000,
                      ),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          20,
                          horizontalPadding,
                          32,
                        ),
                        children: [
                          Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(18),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'New Leave Request',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Enter staff member and leave details.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  StaffLeaveForm(
                                    staff: staff,
                                    isSaving: _isSaving,
                                    onSubmit: _saveLeave,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LoadStaffError extends StatelessWidget {
  const _LoadStaffError({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load staff',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStaffView extends StatelessWidget {
  const _NoStaffView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.group_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active staff found',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add or activate a staff member before creating leave.',
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