import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_workload_entity.dart';
import '../bloc/teacher_workload_bloc.dart';
import '../bloc/teacher_workload_event.dart';
import '../bloc/teacher_workload_state.dart';

class TeacherWorkloadPage extends StatelessWidget {
  const TeacherWorkloadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherWorkloadBloc>(
      create: (_) => sl<TeacherWorkloadBloc>(),
      child: const _TeacherWorkloadView(),
    );
  }
}

class _TeacherWorkloadView extends StatefulWidget {
  const _TeacherWorkloadView();

  @override
  State<_TeacherWorkloadView> createState() => _TeacherWorkloadViewState();
}

class _TeacherWorkloadViewState extends State<_TeacherWorkloadView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');
  final _searchController = TextEditingController();

  TeacherWorkloadLevel? _selectedLevel;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilters);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilters)
      ..dispose();
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  void _refreshFilters() {
    if (mounted) {
      setState(() {});
    }
  }

  void _load() {
    final branchId = _branchController.text.trim();
    final academicSession = _sessionController.text.trim();

    if (branchId.isEmpty || academicSession.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Branch and academic session are required.'),
          ),
        );
      return;
    }

    context.read<TeacherWorkloadBloc>().add(
      LoadTeacherWorkloadEvent(
        branchId: branchId,
        academicSession: academicSession,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Teacher Workload'),
      ),
      body: SafeArea(
        child: BlocConsumer<TeacherWorkloadBloc, TeacherWorkloadState>(
          listener: (context, state) {
            if (state is TeacherWorkloadError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final isLoading = state is TeacherWorkloadLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Workload',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Monitor assigned periods, free capacity and '
                            'weekly teaching distribution for active teachers.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilters(isLoading),
                          const SizedBox(height: 20),
                          if (state is TeacherWorkloadLoaded)
                            _buildReport(state.report)
                          else if (state is TeacherWorkloadError)
                            _MessageCard(
                              icon: Icons.error_outline,
                              message: state.message,
                              color: Theme.of(context).colorScheme.error,
                            )
                          else if (state is TeacherWorkloadInitial)
                            const _MessageCard(
                              icon: Icons.monitor_heart_outlined,
                              message:
                                  'Load the timetable to review teacher '
                                  'workload.',
                              color: Color(0xFFF57C00),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isLoading)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilters(bool isLoading) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 180,
              child: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Teacher',
                  hintText: 'Name or employee ID',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.clear),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<TeacherWorkloadLevel?>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Workload Level',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<TeacherWorkloadLevel?>(
                    value: null,
                    child: Text('All Levels'),
                  ),
                  ...TeacherWorkloadLevel.values.map(
                    (level) => DropdownMenuItem<TeacherWorkloadLevel?>(
                      value: level,
                      child: Text(_levelLabel(level)),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedLevel = value;
                  });
                },
              ),
            ),
            FilledButton.icon(
              onPressed: isLoading ? null : _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Workload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(TeacherWorkloadReportEntity report) {
    final configuration = report.configuration;
    if (configuration == null) {
      return const _MessageCard(
        icon: Icons.settings_outlined,
        message:
            'Timetable configuration was not found. Complete Timetable '
            'Configuration for this branch and session first.',
        color: Color(0xFFF57C00),
      );
    }

    if (report.workloads.isEmpty) {
      return const _MessageCard(
        icon: Icons.person_off_outlined,
        message: 'No active teachers are available.',
        color: Color(0xFFF57C00),
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final visibleWorkloads = report.workloads
        .where((workload) {
          final matchesSearch =
              query.isEmpty ||
              workload.teacherName.toLowerCase().contains(query) ||
              workload.employeeId.toLowerCase().contains(query);
          final matchesLevel =
              _selectedLevel == null || workload.level == _selectedLevel;
          return matchesSearch && matchesLevel;
        })
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _SummaryCard(
              label: 'Active Teachers',
              value: report.activeTeacherCount.toString(),
              icon: Icons.groups_outlined,
              color: const Color(0xFF3F51B5),
            ),
            _SummaryCard(
              label: 'Assigned Periods',
              value: report.totalAssignedPeriods.toString(),
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF00897B),
            ),
            _SummaryCard(
              label: 'Academic Assignments',
              value: report.totalAcademicAssignments.toString(),
              icon: Icons.assignment_ind_outlined,
              color: const Color(0xFF00695C),
            ),
            _SummaryCard(
              label: 'Average / Teacher',
              value: report.averageAssignedPeriods.toStringAsFixed(1),
              icon: Icons.analytics_outlined,
              color: const Color(0xFF7E57C2),
            ),
            _SummaryCard(
              label: 'High Workload',
              value: report.highWorkloadCount.toString(),
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFFF57C00),
            ),
            _SummaryCard(
              label: 'Unassigned',
              value: report.unassignedTeacherCount.toString(),
              icon: Icons.person_off_outlined,
              color: const Color(0xFF546E7A),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.monitor_heart_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Weekly Workload Overview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${visibleWorkloads.length} of ${report.workloads.length} teachers',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (visibleWorkloads.isEmpty)
          const _MessageCard(
            icon: Icons.search_off_outlined,
            message: 'No teachers match the selected filters.',
            color: Color(0xFF546E7A),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 850) {
                return Column(
                  children: [
                    for (final workload in visibleWorkloads) ...[
                      _TeacherWorkloadCard(
                        workload: workload,
                        onTap: () => _showDetails(report, workload),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }

              return Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 54,
                    dataRowMinHeight: 64,
                    dataRowMaxHeight: 76,
                    columns: const [
                      DataColumn(label: Text('Teacher')),
                      DataColumn(label: Text('Designation')),
                      DataColumn(label: Text('Assigned'), numeric: true),
                      DataColumn(label: Text('Subjects'), numeric: true),
                      DataColumn(label: Text('Free'), numeric: true),
                      DataColumn(label: Text('Days'), numeric: true),
                      DataColumn(label: Text('Classes'), numeric: true),
                      DataColumn(label: Text('Utilization')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: [
                      for (final workload in visibleWorkloads)
                        DataRow(
                          onSelectChanged: (_) =>
                              _showDetails(report, workload),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 190,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      workload.teacherName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      workload.employeeId,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 130,
                                child: Text(
                                  workload.designation,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(workload.assignedPeriods.toString())),
                            DataCell(
                              Text(workload.academicAssignments.toString()),
                            ),
                            DataCell(Text(workload.freePeriods.toString())),
                            DataCell(Text(workload.teachingDays.toString())),
                            DataCell(
                              Text(workload.classSections.length.toString()),
                            ),
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: workload.utilization
                                            .clamp(0.0, 1.0)
                                            .toDouble(),
                                        minHeight: 7,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${(workload.utilization * 100).round()}%',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(_WorkloadChip(level: workload.level)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        Text(
          'Workload guide: Low below 45%, Balanced 45%â€“80%, '
          'High above 80% of configured weekly teaching slots.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _showDetails(
    TeacherWorkloadReportEntity report,
    TeacherWorkloadEntity workload,
  ) async {
    final configuration = report.configuration;
    if (configuration == null) {
      return;
    }

    final days = configuration.workingDays.toList()..sort();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(workload.teacherName),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workload.employeeId} â€¢ ${workload.designation}',
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _DetailValue(
                      label: 'Assigned',
                      value: workload.assignedPeriods.toString(),
                    ),
                    _DetailValue(
                      label: 'Academic Assignments',
                      value: workload.academicAssignments.toString(),
                    ),
                    _DetailValue(
                      label: 'Free',
                      value: workload.freePeriods.toString(),
                    ),
                    _DetailValue(
                      label: 'Teaching Days',
                      value: workload.teachingDays.toString(),
                    ),
                    _DetailValue(
                      label: 'Utilization',
                      value: '${(workload.utilization * 100).round()}%',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Daily Distribution',
                  style: Theme.of(
                    dialogContext,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final day in days)
                      Chip(
                        avatar: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        label: Text(
                          '${_dayName(day)}: '
                          '${workload.assignedPeriodsByDay[day] ?? 0}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _DetailList(
                  title: 'Classes / Sections',
                  values: workload.classSections,
                  emptyMessage: 'No classes assigned.',
                ),
                const SizedBox(height: 16),
                _DetailList(
                  title: 'Subjects',
                  values: workload.subjects,
                  emptyMessage: 'No subjects assigned.',
                ),
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

  String _dayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Monday',
      DateTime.tuesday => 'Tuesday',
      DateTime.wednesday => 'Wednesday',
      DateTime.thursday => 'Thursday',
      DateTime.friday => 'Friday',
      DateTime.saturday => 'Saturday',
      DateTime.sunday => 'Sunday',
      _ => 'Day',
    };
  }

  String _levelLabel(TeacherWorkloadLevel level) {
    return switch (level) {
      TeacherWorkloadLevel.unassigned => 'Unassigned',
      TeacherWorkloadLevel.low => 'Low',
      TeacherWorkloadLevel.balanced => 'Balanced',
      TeacherWorkloadLevel.high => 'High',
    };
  }
}

class _TeacherWorkloadCard extends StatelessWidget {
  const _TeacherWorkloadCard({required this.workload, required this.onTap});

  final TeacherWorkloadEntity workload;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      workload.teacherName.isEmpty
                          ? '?'
                          : workload.teacherName[0].toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workload.teacherName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${workload.employeeId} â€¢ ${workload.designation}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _WorkloadChip(level: workload.level),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _CompactValue(
                      label: 'Assigned',
                      value: workload.assignedPeriods.toString(),
                    ),
                  ),
                  Expanded(
                    child: _CompactValue(
                      label: 'Free',
                      value: workload.freePeriods.toString(),
                    ),
                  ),
                  Expanded(
                    child: _CompactValue(
                      label: 'Days',
                      value: workload.teachingDays.toString(),
                    ),
                  ),
                  Expanded(
                    child: _CompactValue(
                      label: 'Classes',
                      value: workload.classSections.length.toString(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: workload.utilization.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(workload.utilization * 100).round()}% utilized',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkloadChip extends StatelessWidget {
  const _WorkloadChip({required this.level});

  final TeacherWorkloadLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (level) {
      TeacherWorkloadLevel.unassigned => (
        'Unassigned',
        const Color(0xFF546E7A),
        Icons.person_off_outlined,
      ),
      TeacherWorkloadLevel.low => (
        'Low',
        const Color(0xFF039BE5),
        Icons.south_east_outlined,
      ),
      TeacherWorkloadLevel.balanced => (
        'Balanced',
        const Color(0xFF00897B),
        Icons.balance_outlined,
      ),
      TeacherWorkloadLevel.high => (
        'High',
        const Color(0xFFF57C00),
        Icons.warning_amber_outlined,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactValue extends StatelessWidget {
  const _CompactValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({
    required this.title,
    required this.values,
    required this.emptyMessage,
  });

  final String title;
  final List<String> values;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          Text(
            emptyMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final value in values) Chip(label: Text(value))],
          ),
      ],
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
