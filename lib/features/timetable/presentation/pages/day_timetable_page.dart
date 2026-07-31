import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/day_timetable_bloc.dart';
import '../bloc/day_timetable_event.dart';
import '../bloc/day_timetable_state.dart';

class DayTimetablePage extends StatelessWidget {
  const DayTimetablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DayTimetableBloc>(
      create: (_) => sl<DayTimetableBloc>(),
      child: const _DayTimetableView(),
    );
  }
}

class _DayTimetableView extends StatefulWidget {
  const _DayTimetableView();

  @override
  State<_DayTimetableView> createState() => _DayTimetableViewState();
}

class _DayTimetableViewState extends State<_DayTimetableView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  TimetableConfigurationEntity? _configuration;
  List<ClassTimetableEntryEntity> _cachedEntries = const [];
  int? _selectedWeekday;
  String? _referenceError;
  bool _referenceLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadConfiguration();
      }
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final branchId = _branchController.text.trim();
    final academicSession = _sessionController.text.trim();
    if (branchId.isEmpty || academicSession.isEmpty) {
      setState(() {
        _referenceLoading = false;
        _referenceError = 'Branch and academic session are required.';
      });
      return;
    }

    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final configuration = await sl<TimetableRepository>().getConfiguration(
        branchId: branchId,
        academicSession: academicSession,
      );
      if (!mounted) {
        return;
      }

      final workingDays = configuration?.workingDays.toList() ?? <int>[];
      workingDays.sort();
      final weekday = workingDays.isEmpty ? null : workingDays.first;

      setState(() {
        _configuration = configuration;
        _selectedWeekday = weekday;
        _cachedEntries = const [];
        _referenceLoading = false;
      });

      if (configuration != null && weekday != null) {
        _loadDay();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _referenceLoading = false;
        _referenceError = _message(error);
      });
    }
  }

  void _selectWeekday(int? weekday) {
    if (weekday == null) {
      return;
    }
    setState(() {
      _selectedWeekday = weekday;
      _cachedEntries = const [];
    });
    _loadDay();
  }

  void _loadDay() {
    final weekday = _selectedWeekday;
    if (_configuration == null || weekday == null) {
      return;
    }

    context.read<DayTimetableBloc>().add(
      LoadDayTimetableEvent(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        weekday: weekday,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day-wise Timetable')),
      body: SafeArea(
        child: BlocConsumer<DayTimetableBloc, DayTimetableState>(
          listener: (context, state) {
            if (state is DayTimetableLoaded) {
              _cachedEntries = state.entries;
            } else if (state is DayTimetableError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final entries = state is DayTimetableLoaded
                ? state.entries
                : _cachedEntries;
            final isBusy = _referenceLoading || state is DayTimetableLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1450),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day-wise Timetable',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Review every class, subject and teacher assigned '
                            'for a selected working day.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilters(isBusy),
                          const SizedBox(height: 20),
                          if (_referenceError != null)
                            _MessageCard(
                              icon: Icons.error_outline,
                              message: _referenceError!,
                              color: Theme.of(context).colorScheme.error,
                            )
                          else if (!_referenceLoading)
                            _buildContent(entries),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isBusy)
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

  Widget _buildFilters(bool isBusy) {
    final days = _configuration?.workingDays.toList() ?? <int>[];
    days.sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 190,
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
              width: 220,
              child: DropdownButtonFormField<int>(
                key: ValueKey('weekday_$_selectedWeekday'),
                initialValue: _selectedWeekday,
                decoration: const InputDecoration(
                  labelText: 'Working Day',
                  border: OutlineInputBorder(),
                ),
                items: days
                    .map(
                      (day) => DropdownMenuItem<int>(
                        value: day,
                        child: Text(_dayName(day)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : _selectWeekday,
              ),
            ),
            FilledButton.icon(
              onPressed: isBusy ? null : _loadConfiguration,
              icon: const Icon(Icons.refresh),
              label: const Text('Load Timetable'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<ClassTimetableEntryEntity> entries) {
    final configuration = _configuration;
    if (configuration == null) {
      return const _MessageCard(
        icon: Icons.settings_outlined,
        message:
            'Timetable configuration was not found. Complete Timetable '
            'Configuration for this branch and session first.',
        color: Color(0xFFF57C00),
      );
    }
    if (_selectedWeekday == null) {
      return const _MessageCard(
        icon: Icons.event_busy_outlined,
        message: 'No working days are configured.',
        color: Color(0xFFF57C00),
      );
    }

    final periods = configuration.orderedPeriods;
    final validPeriodIds = periods.map((period) => period.id).toSet();
    final currentEntries = entries
        .where((entry) => validPeriodIds.contains(entry.periodId))
        .toList(growable: false);
    final teacherCount = currentEntries
        .map((entry) => entry.teacherId)
        .toSet()
        .length;
    final classCount = currentEntries
        .map((entry) => '${entry.classId}|${entry.sectionId}')
        .toSet()
        .length;
    final entriesByPeriod = <String, List<ClassTimetableEntryEntity>>{};
    for (final entry in currentEntries) {
      entriesByPeriod.putIfAbsent(entry.periodId, () => []).add(entry);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _SummaryCard(
              label: 'Assignments',
              value: currentEntries.length.toString(),
              icon: Icons.assignment_outlined,
              color: const Color(0xFF3F51B5),
            ),
            _SummaryCard(
              label: 'Classes / Sections',
              value: classCount.toString(),
              icon: Icons.school_outlined,
              color: const Color(0xFF00897B),
            ),
            _SummaryCard(
              label: 'Teachers',
              value: teacherCount.toString(),
              icon: Icons.groups_outlined,
              color: const Color(0xFF7E57C2),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined),
            const SizedBox(width: 10),
            Text(
              _dayName(_selectedWeekday!),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (final period in periods) ...[
          _PeriodScheduleCard(
            period: period,
            entries: entriesByPeriod[period.id] ?? const [],
          ),
          const SizedBox(height: 14),
        ],
      ],
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

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}

class _PeriodScheduleCard extends StatelessWidget {
  const _PeriodScheduleCard({required this.period, required this.entries});

  final TimetablePeriodEntity period;
  final List<ClassTimetableEntryEntity> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_formatMinutes(period.startMinutes)} - '
                        '${_formatMinutes(period.endMinutes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(_typeLabel)),
              ],
            ),
            const SizedBox(height: 16),
            if (!period.isTeaching)
              Text(
                'No class assignment is required for this period.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else if (entries.isEmpty)
              Text(
                'No classes are assigned for this period.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: entries
                    .map((entry) => _AssignmentCard(entry: entry))
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  String get _typeLabel => switch (period.type) {
    TimetablePeriodType.teaching => 'Teaching',
    TimetablePeriodType.assembly => 'Assembly',
    TimetablePeriodType.breakTime => 'Break',
  };

  IconData get _icon => switch (period.type) {
    TimetablePeriodType.teaching => Icons.menu_book_outlined,
    TimetablePeriodType.assembly => Icons.campaign_outlined,
    TimetablePeriodType.breakTime => Icons.free_breakfast_outlined,
  };

  Color get _color => switch (period.type) {
    TimetablePeriodType.teaching => const Color(0xFF3F51B5),
    TimetablePeriodType.assembly => const Color(0xFFF57C00),
    TimetablePeriodType.breakTime => const Color(0xFF00897B),
  };

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final periodName = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $periodName';
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.entry});

  final ClassTimetableEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.className} - ${entry.sectionName}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.book_outlined, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  entry.teacherName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
      width: 235,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
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
