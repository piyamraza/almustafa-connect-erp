import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/entities/exam_date_sheet_report_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';
import '../bloc/exam_date_sheet_report_bloc.dart';

class ExamDateSheetReportsPage extends StatelessWidget {
  const ExamDateSheetReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamDateSheetReportBloc>(
      create: (_) => sl<ExamDateSheetReportBloc>(),
      child: const _ExamDateSheetReportsView(),
    );
  }
}

class _ExamDateSheetReportsView extends StatefulWidget {
  const _ExamDateSheetReportsView();

  @override
  State<_ExamDateSheetReportsView> createState() =>
      _ExamDateSheetReportsViewState();
}

class _ExamDateSheetReportsViewState extends State<_ExamDateSheetReportsView> {
  List<ExamDateSheetEntity> _dateSheets = const [];
  String? _dateSheetId;
  ExamDateSheetReportType _type = ExamDateSheetReportType.completeSchool;
  String? _classSectionKey;
  String? _teacherId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await sl<ExamDateSheetRepository>().getDateSheets();
      if (!mounted) return;

      setState(() {
        _dateSheets = values;
        _dateSheetId = values.isEmpty ? null : values.first.id;
        _syncFilters();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  ExamDateSheetEntity? get _selectedDateSheet {
    for (final item in _dateSheets) {
      if (item.id == _dateSheetId) return item;
    }
    return null;
  }

  List<_ClassSectionOption> get _classSections {
    final map = <String, _ClassSectionOption>{};
    for (final paper
        in _selectedDateSheet?.papers ?? const <ExamDateSheetPaperEntity>[]) {
      final key = '${paper.classId}|${paper.sectionId}';
      map[key] = _ClassSectionOption(
        key: key,
        classId: paper.classId,
        className: paper.className,
        sectionId: paper.sectionId,
        sectionName: paper.sectionName,
      );
    }
    final values = map.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return values;
  }

  List<_TeacherOption> get _teachers {
    final map = <String, _TeacherOption>{};
    for (final paper
        in _selectedDateSheet?.papers ?? const <ExamDateSheetPaperEntity>[]) {
      if (paper.teacherId.trim().isEmpty) continue;
      map[paper.teacherId] = _TeacherOption(
        id: paper.teacherId,
        name: paper.teacherName,
      );
    }
    final values = map.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  void _syncFilters() {
    final classes = _classSections;
    final teachers = _teachers;
    _classSectionKey = classes.isEmpty ? null : classes.first.key;
    _teacherId = teachers.isEmpty ? null : teachers.first.id;
  }

  ExamDateSheetReportRequest? _request() {
    final dateSheet = _selectedDateSheet;
    if (dateSheet == null) return null;

    final classOption = _classSections
        .where((item) => item.key == _classSectionKey)
        .firstOrNull;
    final teacher = _teachers
        .where((item) => item.id == _teacherId)
        .firstOrNull;

    if (_type == ExamDateSheetReportType.parentClassCopy &&
        classOption == null) {
      return null;
    }
    if (_type == ExamDateSheetReportType.teacherDuty && teacher == null) {
      return null;
    }

    return ExamDateSheetReportRequest(
      dateSheet: dateSheet,
      type: _type,
      classId: classOption?.classId,
      className: classOption?.className,
      sectionId: classOption?.sectionId,
      sectionName: classOption?.sectionName,
      teacherId: teacher?.id,
      teacherName: teacher?.name,
    );
  }

  void _export(ExamDateSheetReportAction action) {
    final request = _request();
    if (request == null) {
      _show('Select all required report filters.');
      return;
    }

    context.read<ExamDateSheetReportBloc>().add(
      ExportExamDateSheetReport(request: request, action: action),
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
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Date Sheet Reports')),
      body: SafeArea(
        child: BlocConsumer<ExamDateSheetReportBloc, ExamDateSheetReportState>(
          listener: (context, state) {
            if (state is ExamDateSheetReportSuccess) {
              _show(state.message);
            } else if (state is ExamDateSheetReportError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = _loading || state is ExamDateSheetReportLoading;

            if (_error != null) {
              return Center(child: Text(_error!));
            }

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date Sheet Reports',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Print and export complete school, parent class '
                            'and teacher duty copies.',
                          ),
                          const SizedBox(height: 22),
                          _filters(busy),
                          const SizedBox(height: 16),
                          _actions(busy),
                          const SizedBox(height: 18),
                          _preview(),
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

  Widget _filters(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: 330,
              child: DropdownButtonFormField<String>(
                initialValue: _dateSheetId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Date Sheet',
                  border: OutlineInputBorder(),
                ),
                items: _dateSheets
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.title),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        setState(() {
                          _dateSheetId = value;
                          _syncFilters();
                        });
                      },
              ),
            ),
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<ExamDateSheetReportType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: ExamDateSheetReportType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(_typeLabel(type)),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _type = value);
                        }
                      },
              ),
            ),
            if (_type == ExamDateSheetReportType.parentClassCopy)
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  initialValue: _classSectionKey,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Class / Section',
                    border: OutlineInputBorder(),
                  ),
                  items: _classSections
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.key,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _classSectionKey = value),
                ),
              ),
            if (_type == ExamDateSheetReportType.teacherDuty)
              SizedBox(
                width: 270,
                child: DropdownButtonFormField<String>(
                  initialValue: _teacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: _teachers
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _teacherId = value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actions(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => _export(ExamDateSheetReportAction.printPdf),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print PDF'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => _export(ExamDateSheetReportAction.sharePdf),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Share PDF'),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => _export(ExamDateSheetReportAction.exportExcel),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final request = _request();
    if (request == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Select report filters to preview papers.'),
        ),
      );
    }

    final papers = request.papers;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${request.title} — ${request.subject}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          if (papers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No papers match this report.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Day')),
                  DataColumn(label: Text('Class')),
                  DataColumn(label: Text('Section')),
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Teacher')),
                  DataColumn(label: Text('Time')),
                ],
                rows: [
                  for (final paper in papers)
                    DataRow(
                      cells: [
                        DataCell(Text(_date(paper.examDate))),
                        DataCell(Text(_day(paper.examDate.weekday))),
                        DataCell(Text(paper.className)),
                        DataCell(Text(paper.sectionName)),
                        DataCell(Text(paper.subjectName)),
                        DataCell(Text(paper.teacherName)),
                        DataCell(
                          Text(
                            '${_time(paper.startMinutes)} - '
                            '${_time(paper.endMinutes)}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _typeLabel(ExamDateSheetReportType type) => switch (type) {
    ExamDateSheetReportType.completeSchool => 'Complete School',
    ExamDateSheetReportType.parentClassCopy => 'Parent / Class Copy',
    ExamDateSheetReportType.teacherDuty => 'Teacher Duty',
  };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';

  static String _day(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => '',
  };

  static String _time(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

class _ClassSectionOption {
  const _ClassSectionOption({
    required this.key,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
  });

  final String key;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;

  String get label => '$className - $sectionName';
}

class _TeacherOption {
  const _TeacherOption({required this.id, required this.name});

  final String id;
  final String name;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
