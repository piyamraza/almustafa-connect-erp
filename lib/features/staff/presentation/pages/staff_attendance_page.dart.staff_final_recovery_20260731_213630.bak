import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../bloc/staff_attendance_bloc.dart';
import '../bloc/staff_attendance_event.dart';
import '../bloc/staff_attendance_state.dart';
import '../widgets/staff_attendance_list_item.dart';
import 'staff_attendance_history_page.dart';
import 'staff_monthly_attendance_page.dart';

class StaffAttendancePage extends StatelessWidget {
  const StaffAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StaffAttendanceBloc>(
      create: (_) => sl<StaffAttendanceBloc>()
        ..add(
          LoadStaffAttendanceByDateEvent(
            DateTime.now(),
          ),
        ),
      child: const _StaffAttendanceView(),
    );
  }
}

class _StaffAttendanceView extends StatefulWidget {
  const _StaffAttendanceView();

  @override
  State<_StaffAttendanceView> createState() => _StaffAttendanceViewState();
}

class _StaffAttendanceViewState extends State<_StaffAttendanceView> {
  late final Future<List<StaffEntity>> _staffFuture;

  final Map<String, StaffAttendanceStatus> _selectedStatuses = {};
  final Map<String, String> _remarks = {};

  DateTime _selectedDate = DateTime.now();
  String? _initializedDateKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _staffFuture = sl<StaffRepository>().getStaff();
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select attendance date',
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      _selectedStatuses.clear();
      _remarks.clear();
      _initializedDateKey = null;
    });

    context.read<StaffAttendanceBloc>().add(
          LoadStaffAttendanceByDateEvent(
            _selectedDate,
          ),
        );
  }

  void _initializeExistingRecords(
    List<StaffAttendanceEntity> records,
  ) {
    final currentDateKey = _dateKey(_selectedDate);

    if (_initializedDateKey == currentDateKey) {
      return;
    }

    _selectedStatuses.clear();
    _remarks.clear();

    for (final record in records) {
      _selectedStatuses[record.staffId] = record.status;
      _remarks[record.staffId] = record.remarks;
    }

    _initializedDateKey = currentDateKey;
  }

  Future<void> _saveAttendance(
    List<StaffEntity> activeStaff,
    List<StaffAttendanceEntity> existingRecords,
  ) async {
    if (_isSaving || activeStaff.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final existingByStaffId = {
      for (final record in existingRecords) record.staffId: record,
    };

    final now = DateTime.now();
    final attendanceDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final dateId = _dateKey(attendanceDate).replaceAll('-', '');

    final records = activeStaff.map((staff) {
      final existingRecord = existingByStaffId[staff.id];

      return StaffAttendanceEntity(
        id: existingRecord?.id ?? '${staff.id}_$dateId',
        staffId: staff.id,
        staffCode: staff.staffId,
        staffName: staff.fullName,
        designation: staff.designation,
        attendanceDate: attendanceDate,
        status: _selectedStatuses[staff.id] ??
            existingRecord?.status ??
            StaffAttendanceStatus.present,
        remarks: _remarks[staff.id] ?? existingRecord?.remarks ?? '',
        createdAt: existingRecord?.createdAt ?? now,
        updatedAt: now,
      );
    }).toList();

    context.read<StaffAttendanceBloc>().add(
          SaveStaffAttendanceEvent(
            records: records,
            date: attendanceDate,
          ),
        );
  }

  void _handleAttendanceState(
    BuildContext context,
    StaffAttendanceState state,
  ) {
    if (state is StaffAttendanceLoaded &&
        state.successMessage != null &&
        state.successMessage!.trim().isNotEmpty) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }

    if (state is StaffAttendanceError) {
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
    }
  }

  void _markAllPresent(
    List<StaffEntity> activeStaff,
  ) {
    setState(() {
      for (final staff in activeStaff) {
        _selectedStatuses[staff.id] = StaffAttendanceStatus.present;
      }
    });
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StaffAttendanceHistoryPage(),
      ),
    );
  }

  void _openMonthlyAttendance() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const StaffMonthlyAttendancePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffAttendanceBloc, StaffAttendanceState>(
      listener: _handleAttendanceState,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Staff Attendance'),
          actions: [
            IconButton(
              tooltip: 'Attendance History',
              onPressed: _openHistory,
              icon: const Icon(Icons.history_outlined),
            ),
            IconButton(
              tooltip: 'Monthly Attendance',
              onPressed: _openMonthlyAttendance,
              icon: const Icon(Icons.calendar_view_month_outlined),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<List<StaffEntity>>(
            future: _staffFuture,
            builder: (context, staffSnapshot) {
              if (staffSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (staffSnapshot.hasError) {
                return _ErrorView(
                  message: staffSnapshot.error.toString(),
                );
              }

              final activeStaff = (staffSnapshot.data ?? const <StaffEntity>[])
                  .where((staff) => staff.isActive)
                  .toList()
                ..sort(
                  (first, second) => first.fullName.toLowerCase().compareTo(
                        second.fullName.toLowerCase(),
                      ),
                );

              return BlocBuilder<StaffAttendanceBloc, StaffAttendanceState>(
                builder: (context, attendanceState) {
                  if (attendanceState is StaffAttendanceLoading &&
                      !_isSaving) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (attendanceState is StaffAttendanceError &&
                      !_isSaving) {
                    return _ErrorView(
                      message: attendanceState.message,
                      onRetry: () {
                        context.read<StaffAttendanceBloc>().add(
                              LoadStaffAttendanceByDateEvent(
                                _selectedDate,
                              ),
                            );
                      },
                    );
                  }

                  final existingRecords =
                      attendanceState is StaffAttendanceLoaded
                          ? attendanceState.records
                          : const <StaffAttendanceEntity>[];

                  _initializeExistingRecords(existingRecords);

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final horizontalPadding = constraints.maxWidth >= 1200
                          ? 32.0
                          : constraints.maxWidth >= 700
                              ? 24.0
                              : 16.0;

                      return Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              20,
                              horizontalPadding,
                              16,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 1200,
                                ),
                                child: _AttendanceHeader(
                                  selectedDate: _formatDate(_selectedDate),
                                  staffCount: activeStaff.length,
                                  isSaving: _isSaving,
                                  onPickDate: _pickDate,
                                  onMarkAllPresent: activeStaff.isEmpty
                                      ? null
                                      : () => _markAllPresent(activeStaff),
                                  onSave: activeStaff.isEmpty
                                      ? null
                                      : () {
                                          _saveAttendance(
                                            activeStaff,
                                            existingRecords,
                                          );
                                        },
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: activeStaff.isEmpty
                                ? const _EmptyStaffView()
                                : Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1200,
                                      ),
                                      child: ListView.separated(
                                        padding: EdgeInsets.fromLTRB(
                                          horizontalPadding,
                                          0,
                                          horizontalPadding,
                                          32,
                                        ),
                                        itemCount: activeStaff.length,
                                        separatorBuilder: (context, index) {
                                          return const SizedBox(height: 12);
                                        },
                                        itemBuilder: (context, index) {
                                          final staff = activeStaff[index];
                                          final existingRecord =
                                              existingRecords
                                                  .where(
                                                    (record) =>
                                                        record.staffId ==
                                                        staff.id,
                                                  )
                                                  .firstOrNull;

                                          final status =
                                              _selectedStatuses[staff.id] ??
                                                  existingRecord?.status ??
                                                  StaffAttendanceStatus.present;

                                          return StaffAttendanceListItem(
                                            key: ValueKey(
                                              '${staff.id}_${_dateKey(_selectedDate)}',
                                            ),
                                            staff: staff,
                                            status: status,
                                            remarks:
                                                _remarks[staff.id] ??
                                                    existingRecord?.remarks ??
                                                    '',
                                            isEnabled: !_isSaving,
                                            onStatusChanged: (newStatus) {
                                              setState(() {
                                                _selectedStatuses[staff.id] =
                                                    newStatus;
                                              });
                                            },
                                            onRemarksChanged: (value) {
                                              _remarks[staff.id] = value.trim();
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      );
                    },
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

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({
    required this.selectedDate,
    required this.staffCount,
    required this.isSaving,
    required this.onPickDate,
    required this.onMarkAllPresent,
    required this.onSave,
  });

  final String selectedDate;
  final int staffCount;
  final bool isSaving;
  final VoidCallback onPickDate;
  final VoidCallback? onMarkAllPresent;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;

            final information = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Staff Attendance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$staffCount active staff member'
                  '${staffCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onPickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(selectedDate),
                ),
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onMarkAllPresent,
                  icon: const Icon(Icons.done_all_outlined),
                  label: const Text('Mark All Present'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isSaving ? 'Saving...' : 'Save Attendance',
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  information,
                  const SizedBox(height: 16),
                  actions,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyStaffView extends StatelessWidget {
  const _EmptyStaffView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No active staff available',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add or activate a staff member before marking attendance.',
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load attendance',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}