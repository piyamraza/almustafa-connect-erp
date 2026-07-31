import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/academic_year_config_entity.dart';
import '../../domain/repositories/academic_year_config_repository.dart';
import '../bloc/academic_year_wizard_bloc.dart';

class AcademicYearWizardPage extends StatelessWidget {
  const AcademicYearWizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AcademicYearWizardBloc>(
      create: (_) => sl<AcademicYearWizardBloc>(),
      child: const _AcademicYearWizardView(),
    );
  }
}

class _AcademicYearWizardView extends StatefulWidget {
  const _AcademicYearWizardView();

  @override
  State<_AcademicYearWizardView> createState() =>
      _AcademicYearWizardViewState();
}

class _AcademicYearWizardViewState extends State<_AcademicYearWizardView> {
  final _formKey = GlobalKey<FormState>();
  final _sessionController = TextEditingController(text: '2026-2027');
  final _feeGenerationController = TextEditingController(text: '1');
  final _feeDueController = TextEditingController(text: '10');
  final _beforeController = TextEditingController(text: '3');
  final _afterController = TextEditingController(text: '2');

  DateTime _startDate = DateTime(2026, 4, 1);
  DateTime _endDate = DateTime(2027, 3, 31);
  final Set<int> _workingWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  };
  final Set<int> _homeworkWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  };
  final List<AcademicDateRangeEntity> _vacations = [];
  final List<AcademicDateRangeEntity> _examWindows = [];
  bool _homeworkOnHolidays = false;
  bool _homeworkInVacations = false;
  bool _zeroPeriodAllowed = false;
  bool _saturdayTimetableAllowed = true;
  bool _isActive = true;
  String? _configId;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    context.read<AcademicYearWizardBloc>().add(
      LoadAcademicYearConfig(_sessionController.text.trim()),
    );
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _feeGenerationController.dispose();
    _feeDueController.dispose();
    _beforeController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  void _applyConfig(AcademicYearConfigEntity config) {
    setState(() {
      _configId = config.id;
      _createdAt = config.createdAt;
      _sessionController.text = config.academicSession;
      _startDate = config.startDate;
      _endDate = config.endDate;
      _workingWeekdays
        ..clear()
        ..addAll(config.workingWeekdays);
      _homeworkWeekdays
        ..clear()
        ..addAll(config.homeworkAllowedWeekdays);
      _vacations
        ..clear()
        ..addAll(config.vacations);
      _examWindows
        ..clear()
        ..addAll(config.examWindows);
      _feeGenerationController.text = '${config.feeGenerationDay}';
      _feeDueController.text = '${config.feeDueDay}';
      _beforeController.text = '${config.feeReminderBeforeDays}';
      _afterController.text = '${config.feeReminderAfterDays}';
      _homeworkOnHolidays = config.homeworkAllowedOnHolidays;
      _homeworkInVacations = config.homeworkAllowedInVacations;
      _zeroPeriodAllowed = config.zeroPeriodAllowed;
      _saturdayTimetableAllowed = config.saturdayTimetableAllowed;
      _isActive = config.isActive;
    });
  }

  Future<void> _pickSessionDate(bool start) async {
    final value = await showDatePicker(
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

  Future<void> _addRange({required bool exam}) async {
    final result = await showDialog<AcademicDateRangeEntity>(
      context: context,
      builder: (_) => _DateRangeDialog(
        title: exam ? 'Add Exam Window' : 'Add Vacation',
        defaultTitle: exam ? 'Exam Window' : 'Vacation',
        sessionStart: _startDate,
        sessionEnd: _endDate,
      ),
    );
    if (result == null) return;
    setState(() {
      (exam ? _examWindows : _vacations).add(result);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    final repository = sl<AcademicYearConfigRepository>();

    context.read<AcademicYearWizardBloc>().add(
      SaveAcademicYearConfig(
        AcademicYearConfigEntity(
          id: _configId ?? repository.generateId(),
          academicSession: _sessionController.text.trim(),
          startDate: _startDate,
          endDate: _endDate,
          workingWeekdays: _workingWeekdays,
          vacations: _vacations,
          examWindows: _examWindows,
          feeGenerationDay: int.parse(_feeGenerationController.text.trim()),
          feeDueDay: int.parse(_feeDueController.text.trim()),
          feeReminderBeforeDays: int.parse(_beforeController.text.trim()),
          feeReminderAfterDays: int.parse(_afterController.text.trim()),
          homeworkAllowedWeekdays: _homeworkWeekdays,
          homeworkAllowedOnHolidays: _homeworkOnHolidays,
          homeworkAllowedInVacations: _homeworkInVacations,
          zeroPeriodAllowed: _zeroPeriodAllowed,
          saturdayTimetableAllowed: _saturdayTimetableAllowed,
          isActive: _isActive,
          createdAt: _createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );
  }

  AcademicYearConfigEntity get _previewConfig {
    final now = DateTime.now();
    return AcademicYearConfigEntity(
      id: _configId ?? 'preview',
      academicSession: _sessionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      workingWeekdays: _workingWeekdays,
      vacations: _vacations,
      examWindows: _examWindows,
      feeGenerationDay: int.tryParse(_feeGenerationController.text.trim()) ?? 1,
      feeDueDay: int.tryParse(_feeDueController.text.trim()) ?? 10,
      feeReminderBeforeDays: int.tryParse(_beforeController.text.trim()) ?? 3,
      feeReminderAfterDays: int.tryParse(_afterController.text.trim()) ?? 2,
      homeworkAllowedWeekdays: _homeworkWeekdays,
      homeworkAllowedOnHolidays: _homeworkOnHolidays,
      homeworkAllowedInVacations: _homeworkInVacations,
      zeroPeriodAllowed: _zeroPeriodAllowed,
      saturdayTimetableAllowed: _saturdayTimetableAllowed,
      isActive: _isActive,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Academic Year Wizard')),
      body: SafeArea(
        child: BlocConsumer<AcademicYearWizardBloc, AcademicYearWizardState>(
          listener: (context, state) {
            if (state is AcademicYearWizardLoaded) {
              if (state.config != null) _applyConfig(state.config!);
              if (state.message != null) _show(state.message!);
            } else if (state is AcademicYearWizardError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = state is AcademicYearWizardLoading;
            final preview = _previewConfig;

            return Stack(
              children: [
                Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _section(
                        '1. Academic Session',
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 210,
                              child: TextFormField(
                                controller: _sessionController,
                                decoration: const InputDecoration(
                                  labelText: 'Session',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Session is required'
                                    : null,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _pickSessionDate(true),
                              icon: const Icon(Icons.date_range),
                              label: Text('Start: ${_date(_startDate)}'),
                            ),
                            OutlinedButton.icon(
                              onPressed: busy
                                  ? null
                                  : () => _pickSessionDate(false),
                              icon: const Icon(Icons.event),
                              label: Text('End: ${_date(_endDate)}'),
                            ),
                            SizedBox(
                              width: 180,
                              child: SwitchListTile(
                                title: const Text('Active Session'),
                                value: _isActive,
                                onChanged: busy
                                    ? null
                                    : (value) =>
                                          setState(() => _isActive = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _section(
                        '2. Weekly Working Days',
                        _weekdaySelector(_workingWeekdays),
                      ),
                      _section(
                        '3. Vacations',
                        _rangeEditor(
                          values: _vacations,
                          onAdd: () => _addRange(exam: false),
                        ),
                      ),
                      _section(
                        '4. Exam Windows',
                        _rangeEditor(
                          values: _examWindows,
                          onAdd: () => _addRange(exam: true),
                        ),
                      ),
                      _section(
                        '5. Fee Schedule',
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _numberField(
                              'Generation Day',
                              _feeGenerationController,
                              1,
                              28,
                            ),
                            _numberField('Due Day', _feeDueController, 1, 28),
                            _numberField(
                              'Reminder Before',
                              _beforeController,
                              0,
                              30,
                            ),
                            _numberField(
                              'Reminder After',
                              _afterController,
                              0,
                              30,
                            ),
                          ],
                        ),
                      ),
                      _section(
                        '6. Homework Rules',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _weekdaySelector(_homeworkWeekdays),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Homework allowed on holidays'),
                              value: _homeworkOnHolidays,
                              onChanged: busy
                                  ? null
                                  : (value) => setState(
                                      () => _homeworkOnHolidays = value,
                                    ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Homework allowed in vacations',
                              ),
                              value: _homeworkInVacations,
                              onChanged: busy
                                  ? null
                                  : (value) => setState(
                                      () => _homeworkInVacations = value,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      _section(
                        '7. Timetable Rules',
                        Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Zero Period Allowed'),
                              value: _zeroPeriodAllowed,
                              onChanged: busy
                                  ? null
                                  : (value) => setState(
                                      () => _zeroPeriodAllowed = value,
                                    ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Saturday Timetable Allowed'),
                              value: _saturdayTimetableAllowed,
                              onChanged: busy
                                  ? null
                                  : (value) => setState(
                                      () => _saturdayTimetableAllowed = value,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      _section(
                        '8. Automatic Calculations',
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _metric('Calendar Days', preview.totalCalendarDays),
                            _metric('Working Days', preview.totalWorkingDays),
                            _metric('Vacation Days', preview.vacationDays),
                            _metric('Exam Days', preview.examDays),
                            _metric(
                              'Teaching Days',
                              preview.availableTeachingDays,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: busy ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save Academic Year'),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
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

  Widget _section(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _weekdaySelector(Set<int> values) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (
          var weekday = DateTime.monday;
          weekday <= DateTime.sunday;
          weekday++
        )
          FilterChip(
            label: Text(_weekday(weekday)),
            selected: values.contains(weekday),
            onSelected: (selected) {
              setState(() {
                selected ? values.add(weekday) : values.remove(weekday);
              });
            },
          ),
      ],
    );
  }

  Widget _rangeEditor({
    required List<AcademicDateRangeEntity> values,
    required VoidCallback onAdd,
  }) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: 8),
        if (values.isEmpty)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('No date ranges configured.'),
          )
        else
          for (final range in values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(range.title),
              subtitle: Text(
                '${_date(range.startDate)} - ${_date(range.endDate)}',
              ),
              trailing: IconButton(
                onPressed: () => setState(() => values.remove(range)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
      ],
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    int min,
    int max,
  ) {
    return SizedBox(
      width: 180,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          final number = int.tryParse(value?.trim() ?? '');
          if (number == null || number < min || number > max) {
            return 'Use $min to $max';
          }
          return null;
        },
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Chip(label: Text('$label: $value'));
  }

  static String _weekday(int weekday) => const {
    DateTime.monday: 'Monday',
    DateTime.tuesday: 'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday: 'Thursday',
    DateTime.friday: 'Friday',
    DateTime.saturday: 'Saturday',
    DateTime.sunday: 'Sunday',
  }[weekday]!;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _DateRangeDialog extends StatefulWidget {
  const _DateRangeDialog({
    required this.title,
    required this.defaultTitle,
    required this.sessionStart,
    required this.sessionEnd,
  });

  final String title;
  final String defaultTitle;
  final DateTime sessionStart;
  final DateTime sessionEnd;

  @override
  State<_DateRangeDialog> createState() => _DateRangeDialogState();
}

class _DateRangeDialogState extends State<_DateRangeDialog> {
  late TextEditingController _titleController;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.defaultTitle);
    _startDate = widget.sessionStart;
    _endDate = widget.sessionStart;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: widget.sessionStart,
      lastDate: widget.sessionEnd,
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pick(true),
              icon: const Icon(Icons.date_range),
              label: Text(
                'Start: ${_AcademicYearWizardViewState._date(_startDate)}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pick(false),
              icon: const Icon(Icons.event),
              label: Text(
                'End: ${_AcademicYearWizardViewState._date(_endDate)}',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty || _endDate.isBefore(_startDate)) return;
            Navigator.pop(
              context,
              AcademicDateRangeEntity(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                title: title,
                startDate: _startDate,
                endDate: _endDate,
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
