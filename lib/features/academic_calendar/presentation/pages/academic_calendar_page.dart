import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/academic_calendar_event_entity.dart';
import '../../domain/repositories/academic_calendar_repository.dart';
import '../bloc/academic_calendar_bloc.dart';
import 'academic_calendar_integration_page.dart';
import 'academic_calendar_validation_page.dart';
import 'academic_year_wizard_page.dart';

class AcademicCalendarPage extends StatelessWidget {
  const AcademicCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider<AcademicCalendarBloc>(
      create: (_) => sl<AcademicCalendarBloc>()
        ..add(
          LoadAcademicCalendar(
            academicSession: '2026-2027',
            month: DateTime(now.year, now.month),
          ),
        ),
      child: const _AcademicCalendarView(),
    );
  }
}

class _AcademicCalendarView extends StatefulWidget {
  const _AcademicCalendarView();

  @override
  State<_AcademicCalendarView> createState() => _AcademicCalendarViewState();
}

class _AcademicCalendarViewState extends State<_AcademicCalendarView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  List<AcademicClassEntity> _classes = const [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final values = await sl<AcademicStructureRepository>().getClasses();
      if (!mounted) return;
      setState(() {
        _classes = values.where((item) => item.isActive).toList()
          ..sort(compareAcademicClasses);
      });
    } catch (_) {}
  }

  void _loadMonth() {
    context.read<AcademicCalendarBloc>().add(
      LoadAcademicCalendar(
        academicSession: _sessionController.text.trim(),
        month: _month,
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _selectedDate = DateTime(_month.year, _month.month, 1);
    });
    _loadMonth();
  }

  Future<void> _editEvent(
    AcademicCalendarEventEntity? existing, {
    DateTime? initialDate,
  }) async {
    final result = await showDialog<AcademicCalendarEventEntity>(
      context: context,
      builder: (_) => _CalendarEventDialog(
        academicSession: _sessionController.text.trim(),
        classes: _classes,
        existing: existing,
        initialDate: initialDate ?? _selectedDate,
      ),
    );

    if (!mounted || result == null) return;

    context.read<AcademicCalendarBloc>().add(SaveAcademicCalendarEvent(result));
  }

  Future<void> _deleteEvent(AcademicCalendarEventEntity event) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Event'),
            content: Text('Delete "${event.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      context.read<AcademicCalendarBloc>().add(
        DeleteAcademicCalendarEvent(event.id),
      );
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Calendar'),
        actions: [
          const DashboardNavigationButton(),
          if (MediaQuery.sizeOf(context).width >= 760) ...[
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => AcademicCalendarIntegrationPage(
                      academicSession: _sessionController.text.trim(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.hub_outlined),
              label: const Text('Integrations'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => AcademicCalendarValidationPage(
                      academicSession: _sessionController.text.trim(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Validate'),
            ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AcademicYearWizardPage(),
                  ),
                );
                if (context.mounted) {
                  _loadMonth();
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Year Wizard'),
            ),
          ] else
            PopupMenuButton<int>(
              tooltip: 'Calendar tools',
              onSelected: (value) async {
                if (value == 0) {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AcademicCalendarIntegrationPage(
                        academicSession: _sessionController.text.trim(),
                      ),
                    ),
                  );
                } else if (value == 1) {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => AcademicCalendarValidationPage(
                        academicSession: _sessionController.text.trim(),
                      ),
                    ),
                  );
                } else {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const AcademicYearWizardPage(),
                    ),
                  );
                  if (context.mounted) _loadMonth();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 0, child: Text('Integrations')),
                PopupMenuItem(value: 1, child: Text('Validate')),
                PopupMenuItem(value: 2, child: Text('Year Wizard')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editEvent(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Event'),
      ),
      body: SafeArea(
        child: BlocConsumer<AcademicCalendarBloc, AcademicCalendarState>(
          listener: (context, state) {
            if (state is AcademicCalendarLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is AcademicCalendarError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = state is AcademicCalendarLoading;
            final events = state is AcademicCalendarLoaded
                ? state.events
                : const <AcademicCalendarEventEntity>[];
            final selectedEvents = events
                .where((event) => event.occursOn(_selectedDate))
                .toList();

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _toolbar(busy),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 950;
                              if (!wide) {
                                return Column(
                                  children: [
                                    _calendar(events),
                                    const SizedBox(height: 14),
                                    _eventList(selectedEvents),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: _calendar(events)),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: _eventList(selectedEvents),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (busy)
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

  Widget _toolbar(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
            IconButton(
              onPressed: busy ? null : () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_monthName(_month.month)} ${_month.year}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: busy ? null : () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
            FilledButton.tonalIcon(
              onPressed: busy ? null : _loadMonth,
              icon: const Icon(Icons.refresh),
              label: const Text('Load'),
            ),
            const Chip(label: Text('Holiday')),
            const Chip(label: Text('Exam')),
            const Chip(label: Text('Activity')),
            const Chip(label: Text('Meeting')),
          ],
        ),
      ),
    );
  }

  Widget _calendar(List<AcademicCalendarEventEntity> events) {
    final firstDay = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = firstDay.weekday - 1;
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                for (final day in [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: MediaQuery.sizeOf(context).width < 600
                    ? .78
                    : 1.15,
              ),
              itemBuilder: (context, index) {
                final day = index - leading + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(_month.year, _month.month, day);
                final dayEvents = events
                    .where((event) => event.occursOn(date))
                    .toList();
                final selected = _sameDay(date, _selectedDate);
                final today = _sameDay(date, DateTime.now());

                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  onDoubleTap: () => _editEvent(null, initialDate: date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 600 ? 2 : 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).dividerColor,
                        width: selected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: today
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: today ? Colors.white : null,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (MediaQuery.sizeOf(context).width >= 600)
                          for (final event in dayEvents.take(2))
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _eventColor(event.type).withAlpha(35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                        if (MediaQuery.sizeOf(context).width < 600 &&
                            dayEvents.isNotEmpty)
                          Wrap(
                            spacing: 2,
                            children: [
                              for (final event in dayEvents.take(3))
                                CircleAvatar(
                                  radius: 2.5,
                                  backgroundColor: _eventColor(event.type),
                                ),
                            ],
                          ),
                        if (MediaQuery.sizeOf(context).width >= 600 &&
                            dayEvents.length > 2)
                          Text(
                            '+${dayEvents.length - 2} more',
                            style: const TextStyle(fontSize: 9),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventList(List<AcademicCalendarEventEntity> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events — ${_date(_selectedDate)}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('No events on this date.')),
              )
            else
              for (final event in events)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _eventColor(event.type).withAlpha(35),
                      child: Icon(
                        _eventIcon(event.type),
                        color: _eventColor(event.type),
                      ),
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      '${_typeLabel(event.type)} • '
                      '${_audienceLabel(event.audience)}'
                      '${event.location.isEmpty ? '' : ' • ${event.location}'}',
                    ),
                    onTap: () => _editEvent(event),
                    trailing: IconButton(
                      tooltip: 'Delete',
                      onPressed: () => _deleteEvent(event),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _monthName(int month) => const [
    '',
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
  ][month];

  static String _typeLabel(AcademicCalendarEventType type) => switch (type) {
    AcademicCalendarEventType.holiday => 'Holiday',
    AcademicCalendarEventType.exam => 'Exam',
    AcademicCalendarEventType.schoolActivity => 'School Activity',
    AcademicCalendarEventType.meeting => 'Meeting',
    AcademicCalendarEventType.vacation => 'Vacation',
    AcademicCalendarEventType.deadline => 'Deadline',
    AcademicCalendarEventType.other => 'Other',
  };

  static String _audienceLabel(AcademicCalendarAudience audience) =>
      switch (audience) {
        AcademicCalendarAudience.wholeSchool => 'Whole School',
        AcademicCalendarAudience.students => 'Students',
        AcademicCalendarAudience.teachers => 'Teachers',
        AcademicCalendarAudience.parents => 'Parents',
        AcademicCalendarAudience.selectedClasses => 'Selected Classes',
      };

  static Color _eventColor(AcademicCalendarEventType type) => switch (type) {
    AcademicCalendarEventType.holiday => const Color(0xFFD32F2F),
    AcademicCalendarEventType.exam => const Color(0xFF6A1B9A),
    AcademicCalendarEventType.schoolActivity => const Color(0xFF00897B),
    AcademicCalendarEventType.meeting => const Color(0xFF1565C0),
    AcademicCalendarEventType.vacation => const Color(0xFFEF6C00),
    AcademicCalendarEventType.deadline => const Color(0xFF455A64),
    AcademicCalendarEventType.other => const Color(0xFF5D4037),
  };

  static IconData _eventIcon(AcademicCalendarEventType type) => switch (type) {
    AcademicCalendarEventType.holiday => Icons.celebration_outlined,
    AcademicCalendarEventType.exam => Icons.quiz_outlined,
    AcademicCalendarEventType.schoolActivity => Icons.event_outlined,
    AcademicCalendarEventType.meeting => Icons.groups_outlined,
    AcademicCalendarEventType.vacation => Icons.beach_access_outlined,
    AcademicCalendarEventType.deadline => Icons.flag_outlined,
    AcademicCalendarEventType.other => Icons.calendar_today_outlined,
  };
}

class _CalendarEventDialog extends StatefulWidget {
  const _CalendarEventDialog({
    required this.academicSession,
    required this.classes,
    required this.initialDate,
    this.existing,
  });

  final String academicSession;
  final List<AcademicClassEntity> classes;
  final DateTime initialDate;
  final AcademicCalendarEventEntity? existing;

  @override
  State<_CalendarEventDialog> createState() => _CalendarEventDialogState();
}

class _CalendarEventDialogState extends State<_CalendarEventDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _location;
  late AcademicCalendarEventType _type;
  late AcademicCalendarAudience _audience;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _isAllDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  late bool _isActive;
  final Set<String> _classIds = {};

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _location = TextEditingController(text: existing?.location ?? '');
    _type = existing?.type ?? AcademicCalendarEventType.schoolActivity;
    _audience = existing?.audience ?? AcademicCalendarAudience.wholeSchool;
    _startDate = existing?.startDate ?? widget.initialDate;
    _endDate = existing?.endDate ?? widget.initialDate;
    _isAllDay = existing?.isAllDay ?? true;
    _isActive = existing?.isActive ?? true;
    _classIds.addAll(existing?.classIds ?? const []);
    if (existing?.startMinutes != null) {
      _startTime = TimeOfDay(
        hour: existing!.startMinutes! ~/ 60,
        minute: existing.startMinutes! % 60,
      );
    }
    if (existing?.endMinutes != null) {
      _endTime = TimeOfDay(
        hour: existing!.endMinutes! ~/ 60,
        minute: existing.endMinutes! % 60,
      );
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final value = await showManualDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _startDate = value;
        if (_endDate.isBefore(value)) _endDate = value;
      } else {
        _endDate = value;
      }
    });
  }

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Event' : 'Edit Event'),
      content: SizedBox(
        width: 760,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 350,
                  child: TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<AcademicCalendarEventType>(
                    initialValue: _type,
                    decoration: const InputDecoration(
                      labelText: 'Event Type',
                      border: OutlineInputBorder(),
                    ),
                    items: AcademicCalendarEventType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              _AcademicCalendarViewState._typeLabel(item),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _type = value);
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<AcademicCalendarAudience>(
                    initialValue: _audience,
                    decoration: const InputDecoration(
                      labelText: 'Audience',
                      border: OutlineInputBorder(),
                    ),
                    items: AcademicCalendarAudience.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              _AcademicCalendarViewState._audienceLabel(item),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _audience = value);
                      }
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    'Start: ${_AcademicCalendarViewState._date(_startDate)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.event),
                  label: Text(
                    'End: ${_AcademicCalendarViewState._date(_endDate)}',
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('All Day Event'),
                    value: _isAllDay,
                    onChanged: (value) => setState(() => _isAllDay = value),
                  ),
                ),
                if (!_isAllDay) ...[
                  OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.schedule),
                    label: Text('Start: ${_startTime.format(context)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('End: ${_endTime.format(context)}'),
                  ),
                ],
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    controller: _location,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 720,
                  child: TextFormField(
                    controller: _description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / Instructions',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_audience == AcademicCalendarAudience.selectedClasses)
                  SizedBox(
                    width: 720,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final academicClass in widget.classes)
                          FilterChip(
                            label: Text(academicClass.name),
                            selected: _classIds.contains(academicClass.id),
                            onSelected: (selected) {
                              setState(() {
                                selected
                                    ? _classIds.add(academicClass.id)
                                    : _classIds.remove(academicClass.id);
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: 220,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Event'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_endDate.isBefore(_startDate)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('End date cannot be before start date.'),
                ),
              );
              return;
            }

            final now = DateTime.now();
            final repository = sl<AcademicCalendarRepository>();

            Navigator.pop(
              context,
              AcademicCalendarEventEntity(
                id: widget.existing?.id ?? repository.generateId(),
                title: _title.text.trim(),
                description: _description.text.trim(),
                type: _type,
                audience: _audience,
                startDate: _startDate,
                endDate: _endDate,
                isAllDay: _isAllDay,
                startMinutes: _isAllDay
                    ? null
                    : _startTime.hour * 60 + _startTime.minute,
                endMinutes: _isAllDay
                    ? null
                    : _endTime.hour * 60 + _endTime.minute,
                classIds: _audience == AcademicCalendarAudience.selectedClasses
                    ? _classIds.toList()
                    : const [],
                location: _location.text.trim(),
                academicSession: widget.academicSession,
                isActive: _isActive,
                createdAt: widget.existing?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: const Text('Save Event'),
        ),
      ],
    );
  }
}
