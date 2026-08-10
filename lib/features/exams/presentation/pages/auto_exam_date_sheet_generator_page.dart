import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_calendar/domain/entities/academic_calendar_event_entity.dart';
import '../../../academic_calendar/domain/repositories/academic_calendar_repository.dart';
import '../../domain/entities/exam_date_sheet_generation_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../bloc/exam_date_sheet_generator_bloc.dart';
import 'manual_exam_date_sheet_builder_page.dart';

class AutoExamDateSheetGeneratorPage extends StatelessWidget {
  const AutoExamDateSheetGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamDateSheetGeneratorBloc>(
      create: (_) => sl<ExamDateSheetGeneratorBloc>(),
      child: const _AutoExamDateSheetGeneratorView(),
    );
  }
}

class _AutoExamDateSheetGeneratorView extends StatefulWidget {
  const _AutoExamDateSheetGeneratorView();

  @override
  State<_AutoExamDateSheetGeneratorView> createState() =>
      _AutoExamDateSheetGeneratorViewState();
}

class _AutoExamDateSheetGeneratorViewState
    extends State<_AutoExamDateSheetGeneratorView> {
  List<ExamEntity> _exams = const [];
  String? _examId;
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<int> _allowedWeekdays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  };
  final List<DateTime> _holidays = [];
  List<DateTime> _calendarHolidays = const [];
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  final _durationController = TextEditingController(text: '120');
  bool _loadingReferences = true;
  bool _loadingCalendarHolidays = false;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadExams() async {
    try {
      final allExams = await sl<ExamRepository>().getExams();
      final exams = allExams.where((exam) => exam.isActive).toList();
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _examId = exams.isEmpty ? null : exams.first.id;
        final exam = _selectedExam;
        _startDate = exam?.startDate ?? exam?.examDate;
        _endDate = exam?.endDate ?? exam?.examDate;
        _loadingReferences = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReferences = false;
        _referenceError = _message(error);
      });
    }
  }

  ExamEntity? get _selectedExam {
    for (final exam in _exams) {
      if (exam.id == _examId) return exam;
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final exam = _selectedExam;
    if (exam == null) return;
    final first = exam.startDate ?? exam.examDate;
    final last = exam.endDate ?? exam.examDate;
    final value = await showManualDatePicker(
      context: context,
      initialDate: _startDate ?? first,
      firstDate: first,
      lastDate: last,
    );
    if (value != null) setState(() => _startDate = value);
  }

  Future<void> _pickEndDate() async {
    final exam = _selectedExam;
    if (exam == null) return;
    final first = exam.startDate ?? exam.examDate;
    final last = exam.endDate ?? exam.examDate;
    final value = await showManualDatePicker(
      context: context,
      initialDate: _endDate ?? last,
      firstDate: first,
      lastDate: last,
    );
    if (value != null) setState(() => _endDate = value);
  }

  Future<void> _addHoliday() async {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) return;
    final value = await showManualDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: end,
    );
    if (value != null && !_holidays.any((item) => _sameDate(item, value))) {
      setState(() => _holidays.add(value));
    }
  }

  Future<void> _pickStartTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (value != null) setState(() => _startTime = value);
  }

  Future<void> _generate() async {
    final exam = _selectedExam;
    final start = _startDate;
    final end = _endDate;
    final duration = int.tryParse(_durationController.text.trim());

    if (exam == null || start == null || end == null) {
      _show('Select an exam and date range.');
      return;
    }
    if (end.isBefore(start)) {
      _show('End date cannot be before start date.');
      return;
    }
    if (_allowedWeekdays.isEmpty) {
      _show('Select at least one exam day.');
      return;
    }
    if (duration == null || duration <= 0) {
      _show('Enter a valid paper duration.');
      return;
    }

    setState(() => _loadingCalendarHolidays = true);
    List<DateTime> calendarHolidays;
    try {
      calendarHolidays = await _loadCalendarHolidays(
        academicSession: exam.academicSession,
        startDate: start,
        endDate: end,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingCalendarHolidays = false);
      _show(
        'Academic Calendar holidays could not be loaded: ${_message(error)}',
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _calendarHolidays = calendarHolidays;
      _loadingCalendarHolidays = false;
    });

    final excludedDates = <DateTime>[];
    for (final date in [..._holidays, ...calendarHolidays]) {
      if (!excludedDates.any((existing) => _sameDate(existing, date))) {
        excludedDates.add(date);
      }
    }

    context.read<ExamDateSheetGeneratorBloc>().add(
      GenerateExamDateSheetOptionsEvent(
        exam: exam,
        request: ExamDateSheetGenerationRequest(
          examId: exam.id,
          examName: exam.name,
          academicSession: exam.academicSession,
          startDate: start,
          endDate: end,
          allowedWeekdays: _allowedWeekdays.toList()..sort(),
          holidays: excludedDates,
          startMinutes: _startTime.hour * 60 + _startTime.minute,
          paperDurationMinutes: duration,
          includeAllActiveClasses: true,
        ),
      ),
    );
  }

  Future<List<DateTime>> _loadCalendarHolidays({
    required String academicSession,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final events = await sl<AcademicCalendarRepository>().getEvents(
      academicSession: academicSession,
      startDate: startDate,
      endDate: endDate,
      isActive: true,
    );
    final dates = <DateTime>[];
    for (final event in events) {
      final blocksStudents =
          event.audience == AcademicCalendarAudience.wholeSchool ||
          event.audience == AcademicCalendarAudience.students ||
          event.audience == AcademicCalendarAudience.selectedClasses;
      final isHoliday =
          event.type == AcademicCalendarEventType.holiday ||
          event.type == AcademicCalendarEventType.vacation;
      if (!blocksStudents || !isHoliday) continue;

      var date = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final eventEnd = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );
      while (!date.isAfter(eventEnd)) {
        if (!date.isBefore(startDate) && !date.isAfter(endDate)) {
          dates.add(date);
        }
        date = date.add(const Duration(days: 1));
      }
    }
    dates.sort();
    return dates;
  }

  Future<void> _openSavedForEditing(ExamDateSheetGeneratorSaved state) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ManualExamDateSheetBuilderPage(existing: state.dateSheet),
      ),
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
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Auto Date Sheet Generator'),
      ),
      body: SafeArea(
        child: BlocConsumer<ExamDateSheetGeneratorBloc, ExamDateSheetGeneratorState>(
          listener: (context, state) {
            if (state is ExamDateSheetGeneratorError) {
              _show(state.message);
            } else if (state is ExamDateSheetGeneratorSaved) {
              _show('Generated option saved as draft.');
              _openSavedForEditing(state);
            }
          },
          builder: (context, state) {
            final busy =
                _loadingReferences ||
                _loadingCalendarHolidays ||
                state is ExamDateSheetGeneratorLoading;

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
                            'Intelligent Auto Date Sheet Generator',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Generate and compare Balanced, Maximum Gap and '
                            'Compact schedules.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 22),
                          if (_referenceError != null)
                            _MessageCard(_referenceError!)
                          else
                            _buildConfiguration(busy),
                          const SizedBox(height: 18),
                          if (state is ExamDateSheetGeneratorLoaded)
                            _buildOptions(state.options)
                          else if (!busy)
                            const _MessageCard(
                              'Configure the generator and create three options.',
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

  Widget _buildConfiguration(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    initialValue: _examId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exam',
                      border: OutlineInputBorder(),
                    ),
                    items: _exams
                        .map(
                          (exam) => DropdownMenuItem(
                            value: exam.id,
                            child: Text(exam.name),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (value) {
                            setState(() {
                              _examId = value;
                              final exam = _selectedExam;
                              _startDate = exam?.startDate ?? exam?.examDate;
                              _endDate = exam?.endDate ?? exam?.examDate;
                              _holidays.clear();
                              _calendarHolidays = const [];
                            });
                          },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickStartDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    'Start: ${_startDate == null ? '-' : _date(_startDate!)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickEndDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    'End: ${_endDate == null ? '-' : _date(_endDate!)}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickStartTime,
                  icon: const Icon(Icons.schedule),
                  label: Text('Start: ${_startTime.format(context)}'),
                ),
                SizedBox(
                  width: 190,
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: busy ? null : _generate,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate 3 Options'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Allowed Exam Days',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                  FilterChip(
                    label: Text(_dayName(day)),
                    selected: _allowedWeekdays.contains(day),
                    onSelected: busy
                        ? null
                        : (selected) {
                            setState(() {
                              selected
                                  ? _allowedWeekdays.add(day)
                                  : _allowedWeekdays.remove(day);
                            });
                          },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : _addHoliday,
                  icon: const Icon(Icons.event_busy_outlined),
                  label: const Text('Add Holiday'),
                ),
                for (final holiday in _holidays)
                  InputChip(
                    label: Text(_date(holiday)),
                    onDeleted: busy
                        ? null
                        : () => setState(() => _holidays.remove(holiday)),
                  ),
                for (final holiday in _calendarHolidays)
                  Chip(
                    avatar: const Icon(Icons.event_busy_outlined, size: 18),
                    label: Text('Calendar: ${_date(holiday)}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(List<ExamDateSheetGeneratedOption> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Options',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1150
                ? 3
                : constraints.maxWidth >= 720
                ? 2
                : 1;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columns == 1 ? 1.55 : 1.05,
              ),
              itemBuilder: (context, index) {
                final option = options[index];
                final recommended = index == 0 && option.isValid;
                return _OptionCard(
                  option: option,
                  recommended: recommended,
                  onPreview: () => _showPreview(option),
                  onSave: () {
                    final exam = _selectedExam;
                    if (exam == null) return;
                    context.read<ExamDateSheetGeneratorBloc>().add(
                      SaveGeneratedDateSheetOption(exam: exam, option: option),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showPreview(ExamDateSheetGeneratedOption option) async {
    final matrix = _buildDateSheetMatrix(option);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(option.label),
        content: SizedBox(
          width: 1200,
          height: 580,
          child: _AutoDateSheetPreviewTable(matrix: matrix),
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

  _DateSheetMatrix _buildDateSheetMatrix(ExamDateSheetGeneratedOption option) {
    final columnsByKey = <String, _DateSheetColumn>{};
    final sectionsPerClass = <String, Set<String>>{};
    final subjects = <String, List<String>>{};
    final datesByKey = <String, DateTime>{};

    for (final paper in option.papers) {
      final columnKey = '${paper.classId}|${paper.sectionId}';
      final dateKey = _dateKey(paper.examDate);
      columnsByKey[columnKey] = _DateSheetColumn(
        key: columnKey,
        classId: paper.classId,
        className: paper.className,
        sectionName: paper.sectionName,
      );
      sectionsPerClass
          .putIfAbsent(paper.classId, () => <String>{})
          .add(paper.sectionId);
      datesByKey[dateKey] = paper.examDate;
      subjects
          .putIfAbsent('$dateKey|$columnKey', () => <String>[])
          .add('${paper.subjectName}\n${paper.teacherName}');
    }

    final columns = columnsByKey.values.toList()
      ..sort((first, second) {
        final classComparison = compareAcademicClassNames(
          first.className,
          second.className,
        );
        return classComparison != 0
            ? classComparison
            : first.sectionName.toLowerCase().compareTo(
                second.sectionName.toLowerCase(),
              );
      });
    for (final column in columns) {
      column.showSection = (sectionsPerClass[column.classId]?.length ?? 0) > 1;
    }
    final dates = datesByKey.values.toList()..sort();
    return _DateSheetMatrix(columns: columns, dates: dates, subjects: subjects);
  }

  static String _dateKey(DateTime value) =>
      '${value.year}-${value.month}-${value.day}';

  static bool _sameDate(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _dayName(int day) => switch (day) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => 'Day',
  };

  static String _fullDayName(int day) => switch (day) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.recommended,
    required this.onPreview,
    required this.onSave,
  });

  final ExamDateSheetGeneratedOption option;
  final bool recommended;
  final VoidCallback onPreview;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final color = option.isValid
        ? const Color(0xFF00897B)
        : Theme.of(context).colorScheme.error;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(25),
                  child: Icon(Icons.auto_awesome, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (recommended) const Chip(label: Text('RECOMMENDED')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${option.score}/100',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(option.validation.rating),
            const SizedBox(height: 12),
            Text('${option.papers.length} papers'),
            Text(
              '${_AutoExamDateSheetGeneratorViewState._date(option.startDate)}'
              ' -> '
              '${_AutoExamDateSheetGeneratorViewState._date(option.endDate)}',
            ),
            Text(
              'Average gap: ${option.averageGapDays.toStringAsFixed(1)} days',
            ),
            Text('${option.validation.errors.length} conflicts'),
            Text('${option.validation.warnings.length} warnings'),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text('Preview'),
                ),
                FilledButton.icon(
                  onPressed: option.isValid ? onSave : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _DateSheetColumn {
  _DateSheetColumn({
    required this.key,
    required this.classId,
    required this.className,
    required this.sectionName,
  });

  final String key;
  final String classId;
  final String className;
  final String sectionName;
  bool showSection = false;

  String get label => showSection && sectionName.trim().isNotEmpty
      ? 'Class $className - $sectionName'
      : 'Class $className';
}

class _DateSheetMatrix {
  const _DateSheetMatrix({
    required this.columns,
    required this.dates,
    required this.subjects,
  });

  final List<_DateSheetColumn> columns;
  final List<DateTime> dates;
  final Map<String, List<String>> subjects;

  String subjectsFor(DateTime date, _DateSheetColumn column) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    final values = subjects['$dateKey|${column.key}'];
    return values == null || values.isEmpty ? '-' : values.join('\n');
  }
}

class _AutoDateSheetPreviewTable extends StatefulWidget {
  const _AutoDateSheetPreviewTable({required this.matrix});

  final _DateSheetMatrix matrix;

  @override
  State<_AutoDateSheetPreviewTable> createState() =>
      _AutoDateSheetPreviewTableState();
}

class _AutoDateSheetPreviewTableState
    extends State<_AutoDateSheetPreviewTable> {
  static const double _dateWidth = 112;
  static const double _classWidth = 112;

  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matrix = widget.matrix;
    final width = _dateWidth + matrix.columns.length * _classWidth;

    return LayoutBuilder(
      builder: (context, constraints) => Scrollbar(
        controller: _horizontalController,
        thumbVisibility: true,
        trackVisibility: true,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Column(
              children: [
                Container(
                  height: 44,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Row(
                    children: [
                      _box(
                        context,
                        width: _dateWidth,
                        child: const Text(
                          'Date',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      for (final column in matrix.columns)
                        _box(
                          context,
                          width: _classWidth,
                          child: Text(
                            column.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: matrix.dates.length,
                    itemBuilder: (context, index) {
                      final date = matrix.dates[index];
                      return SizedBox(
                        height: 56,
                        child: Row(
                          children: [
                            _box(
                              context,
                              width: _dateWidth,
                              child: Text(
                                '${_AutoExamDateSheetGeneratorViewState._date(date)}\n'
                                '${_AutoExamDateSheetGeneratorViewState._fullDayName(date.weekday)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            for (final column in matrix.columns)
                              _box(
                                context,
                                width: _classWidth,
                                child: Text(
                                  matrix.subjectsFor(date, column),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _box(
    BuildContext context, {
    required double width,
    required Widget child,
  }) => Container(
    width: width,
    height: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(color: Theme.of(context).dividerColor),
        bottom: BorderSide(color: Theme.of(context).dividerColor),
      ),
    ),
    child: child,
  );
}
