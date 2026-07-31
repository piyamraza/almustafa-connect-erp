import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_leave_bloc.dart';
import '../bloc/staff_leave_event.dart';
import '../bloc/staff_leave_state.dart';
import '../teacher_leave/teacher_leave_helpers.dart';
import '../widgets/teacher_leave_list_item.dart';

class TeacherLeaveHistoryPage extends StatelessWidget {
  const TeacherLeaveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffLeaveBloc>(
      create: (_) => sl<StaffLeaveBloc>(),
      child: const _TeacherLeaveHistoryView(),
    );
  }
}

class _TeacherLeaveHistoryView extends StatefulWidget {
  const _TeacherLeaveHistoryView();

  @override
  State<_TeacherLeaveHistoryView> createState() =>
      _TeacherLeaveHistoryViewState();
}

class _TeacherLeaveHistoryViewState extends State<_TeacherLeaveHistoryView> {
  late final Future<List<StaffEntity>> _teachersFuture;
  StaffEntity? _selectedTeacher;
  late int _selectedYear;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _selectedYear = DateTime.now().year;
    _teachersFuture = _loadTeachers();
  }

  Future<List<StaffEntity>> _loadTeachers() async {
    final staff = await sl<StaffRepository>().getStaff();

    final teachers =
        staff
            .where((member) => isTeacherDesignation(member.designation))
            .toList()
          ..sort(
            (first, second) => first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            ),
          );

    return teachers;
  }

  void _loadHistory() {
    final teacher = _selectedTeacher;

    if (teacher == null) {
      return;
    }

    context.read<StaffLeaveBloc>().add(
      LoadStaffLeaveHistoryEvent(
        staffId: teacher.id,
        startDate: DateTime(_selectedYear, 1, 1),
        endDate: DateTime(_selectedYear, 12, 31),
      ),
    );
  }

  void _showPreviousYear() {
    setState(() {
      _selectedYear--;
    });

    _loadHistory();
  }

  void _showNextYear() {
    if (_selectedYear >= DateTime.now().year) {
      return;
    }

    setState(() {
      _selectedYear++;
    });

    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Leave History')),
      body: SafeArea(
        child: FutureBuilder<List<StaffEntity>>(
          future: _teachersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _HistoryMessageView(
                title: 'Unable to load teachers',
                message: snapshot.error.toString(),
              );
            }

            final teachers = snapshot.data ?? const <StaffEntity>[];

            if (teachers.isEmpty) {
              return const _HistoryMessageView(
                title: 'No teachers found',
                message: 'No teacher records are available.',
              );
            }

            if (!_initialized) {
              _initialized = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }

                setState(() {
                  _selectedTeacher = teachers.first;
                });

                _loadHistory();
              });
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 700;

                              final teacherField =
                                  DropdownButtonFormField<StaffEntity>(
                                    initialValue: _selectedTeacher,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Teacher',
                                      prefixIcon: Icon(Icons.school_outlined),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: teachers
                                        .map(
                                          (teacher) => DropdownMenuItem(
                                            value: teacher,
                                            child: Text(
                                              teacher.fullName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }

                                      setState(() {
                                        _selectedTeacher = value;
                                      });

                                      _loadHistory();
                                    },
                                  );

                              final yearControls = Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.outlined(
                                    onPressed: _showPreviousYear,
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      _selectedYear.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  IconButton.outlined(
                                    onPressed:
                                        _selectedYear < DateTime.now().year
                                        ? _showNextYear
                                        : null,
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                    ),
                                  ),
                                ],
                              );

                              if (compact) {
                                return Column(
                                  children: [
                                    teacherField,
                                    const SizedBox(height: 14),
                                    yearControls,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: teacherField),
                                  const SizedBox(width: 20),
                                  yearControls,
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: BlocBuilder<StaffLeaveBloc, StaffLeaveState>(
                    builder: (context, state) {
                      if (_selectedTeacher == null ||
                          state is StaffLeaveInitial ||
                          state is StaffLeaveLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is StaffLeaveError) {
                        return _HistoryMessageView(
                          title: 'Unable to load history',
                          message: state.message,
                        );
                      }

                      if (state is StaffLeaveLoaded) {
                        final leaves = state.leaves
                            .where(isTeacherLeave)
                            .toList();

                        if (leaves.isEmpty) {
                          return const _HistoryMessageView(
                            title: 'No leave history found',
                            message:
                                'No teacher leave records were found for this year.',
                          );
                        }

                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1100),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                              itemCount: leaves.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 12);
                              },
                              itemBuilder: (context, index) {
                                return TeacherLeaveListItem(
                                  leave: leaves[index],
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HistoryMessageView extends StatelessWidget {
  const _HistoryMessageView({required this.title, required this.message});

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
            Icon(
              Icons.history_outlined,
              size: 68,
              color: theme.colorScheme.onSurfaceVariant,
            ),
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
