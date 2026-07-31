import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../teacher_leave/teacher_leave_helpers.dart';
import '../widgets/teacher_leave_form.dart';

class AddTeacherLeavePage extends StatelessWidget {
  const AddTeacherLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _AddTeacherLeaveView(),
    );
  }
}

class _AddTeacherLeaveView extends StatefulWidget {
  const _AddTeacherLeaveView();

  @override
  State<_AddTeacherLeaveView> createState() => _AddTeacherLeaveViewState();
}

class _AddTeacherLeaveViewState extends State<_AddTeacherLeaveView> {
  late final Future<List<TeacherEntity>> _teachersFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _teachersFuture = _loadTeachers();
  }

  Future<List<TeacherEntity>> _loadTeachers() async {
    final teachers = await sl<TeacherRepository>().getTeachers();
    final activeTeachers = teachers.where((teacher) => teacher.isActive).toList();
    activeTeachers.sort(
      (first, second) => first.fullName.toLowerCase().compareTo(
        second.fullName.toLowerCase(),
      ),
    );
    return activeTeachers;
  }

  Future<void> _saveLeave(TeacherLeaveFormData data) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final leave = StaffLeaveEntity(
      id: '${data.teacher.id}_teacher_leave_${now.microsecondsSinceEpoch}',
      staffId: data.teacher.id,
      staffCode: data.teacher.employeeId,
      staffName: data.teacher.fullName,
      designation: teacherLeaveDesignation(data.teacher.designation),
      leaveType: data.staffLeaveType,
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

    context.read<StaffLeaveBloc>().add(SaveStaffLeaveEvent(leave));
  }

  void _handleState(BuildContext context, StaffLeaveState state) {
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

    if (state is StaffLeaveLoaded && state.successMessage != null) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffLeaveBloc, StaffLeaveState>(
      listener: _handleState,
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Teacher Leave')),
        body: SafeArea(
          child: FutureBuilder<List<TeacherEntity>>(
            future: _teachersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _MessageView(
                  icon: Icons.error_outline,
                  title: 'Unable to load teachers',
                  message: snapshot.error.toString(),
                );
              }

              final teachers = snapshot.data ?? const <TeacherEntity>[];

              if (teachers.isEmpty) {
                return const _MessageView(
                  icon: Icons.school_outlined,
                  title: 'No active teachers found',
                  message: 'Add an active teacher in the Teachers module first.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth >= 1000
                      ? 32.0
                      : constraints.maxWidth >= 700
                      ? 24.0
                      : 16.0;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
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
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'New Teacher Leave Request',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Leave has no salary deduction. Unpaid Leave deducts salary.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                  TeacherLeaveForm(
                                    teachers: teachers,
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

class _MessageView extends StatelessWidget {
  const _MessageView({
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
