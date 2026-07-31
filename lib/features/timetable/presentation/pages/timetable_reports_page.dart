import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/teacher_workload_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/entities/timetable_report_entity.dart';
import '../bloc/timetable_report_bloc.dart';
import '../bloc/timetable_report_event.dart';
import '../bloc/timetable_report_state.dart';

class TimetableReportsPage extends StatelessWidget {
  const TimetableReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimetableReportBloc>(
      create: (_) => sl<TimetableReportBloc>(),
      child: const _TimetableReportsView(),
    );
  }
}

class _TimetableReportsView extends StatefulWidget {
  const _TimetableReportsView();

  @override
  State<_TimetableReportsView> createState() => _TimetableReportsViewState();
}

class _TimetableReportsViewState extends State<_TimetableReportsView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<TeacherEntity> _teachers = const [];

  TimetableReportType _reportType = TimetableReportType.classTimetable;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedTeacherId;
  bool _referenceLoading = true;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReferenceData();
      }
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final values = await Future.wait<Object?>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<TeacherRepository>().getTeachers(),
      ]);

      if (!mounted) {
        return;
      }

      final classes =
          (values[0] as List<AcademicClassEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort((first, second) => first.name.compareTo(second.name));
      final sections =
          (values[1] as List<SectionEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort((first, second) => first.name.compareTo(second.name));
      final teachers =
          (values[2] as List<TeacherEntity>)
              .where((value) => value.isActive)
              .toList()
            ..sort(
              (first, second) => first.fullName.compareTo(second.fullName),
            );

      final classId = classes.isEmpty ? null : classes.first.id;
      final classSections = sections
          .where((value) => value.classId == classId)
          .toList(growable: false);

      setState(() {
        _classes = classes;
        _sections = sections;
        _teachers = teachers;
        _selectedClassId = classId;
        _selectedSectionId = classSections.isEmpty
            ? null
            : classSections.first.id;
        _selectedTeacherId = teachers.isEmpty ? null : teachers.first.id;
        _referenceLoading = false;
      });
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

  List<SectionEntity> get _availableSections {
    final values = _sections
        .where((section) => section.classId == _selectedClassId)
        .toList();
    values.sort((first, second) => first.name.compareTo(second.name));
    return values;
  }

  AcademicClassEntity? get _selectedClass {
    for (final value in _classes) {
      if (value.id == _selectedClassId) {
        return value;
      }
    }
    return null;
  }

  SectionEntity? get _selectedSection {
    for (final value in _sections) {
      if (value.id == _selectedSectionId) {
        return value;
      }
    }
    return null;
  }

  TeacherEntity? get _selectedTeacher {
    for (final value in _teachers) {
      if (value.id == _selectedTeacherId) {
        return value;
      }
    }
    return null;
  }

  void _selectReportType(TimetableReportType? type) {
    if (type == null) {
      return;
    }
    setState(() {
      _reportType = type;
    });
  }

  void _selectClass(String? classId) {
    if (classId == null) {
      return;
    }

    final sections = _sections
        .where((section) => section.classId == classId)
        .toList(growable: false);

    setState(() {
      _selectedClassId = classId;
      _selectedSectionId = sections.isEmpty ? null : sections.first.id;
    });
  }

  void _generateReport() {
    final branchId = _branchController.text.trim();
    final academicSession = _sessionController.text.trim();

    if (branchId.isEmpty || academicSession.isEmpty) {
      _showMessage('Branch and academic session are required.');
      return;
    }

    if (_reportType == TimetableReportType.classTimetable &&
        (_selectedClass == null || _selectedSection == null)) {
      _showMessage('Select a class and section first.');
      return;
    }

    if (_reportType == TimetableReportType.teacherTimetable &&
        _selectedTeacher == null) {
      _showMessage('Select a teacher first.');
      return;
    }

    final request = TimetableReportRequestEntity(
      branchId: branchId,
      academicSession: academicSession,
      type: _reportType,
      classId: _reportType == TimetableReportType.classTimetable
          ? _selectedClass?.id
          : null,
      className: _reportType == TimetableReportType.classTimetable
          ? _selectedClass?.name
          : null,
      sectionId: _reportType == TimetableReportType.classTimetable
          ? _selectedSection?.id
          : null,
      sectionName: _reportType == TimetableReportType.classTimetable
          ? _selectedSection?.name
          : null,
      teacherId: _reportType == TimetableReportType.teacherTimetable
          ? _selectedTeacher?.id
          : null,
      teacherName: _reportType == TimetableReportType.teacherTimetable
          ? _selectedTeacher?.fullName
          : null,
    );

    context.read<TimetableReportBloc>().add(
      GenerateTimetableReportEvent(request),
    );
  }

  void _export(TimetableReportExportAction action) {
    context.read<TimetableReportBloc>().add(ExportTimetableReportEvent(action));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Reports')),
      body: SafeArea(
        child: BlocConsumer<TimetableReportBloc, TimetableReportState>(
          listener: (context, state) {
            if (state is TimetableReportLoaded &&
                state.successMessage != null) {
              _showMessage(state.successMessage!);
            } else if (state is TimetableReportError) {
              _showMessage(state.message);
            }
          },
          builder: (context, state) {
            final report = state.report;
            final isBusy =
                _referenceLoading ||
                state is TimetableReportLoading ||
                state is TimetableReportExporting;

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
                            'Timetable Reports',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preview, print and export class timetables, '
                            'teacher schedules and workload reports.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          _buildFilters(isBusy),
                          const SizedBox(height: 18),
                          if (_referenceError != null)
                            _MessageCard(
                              icon: Icons.error_outline,
                              message: _referenceError!,
                              color: Theme.of(context).colorScheme.error,
                            )
                          else ...[
                            _buildActions(report, isBusy),
                            const SizedBox(height: 18),
                            if (report == null)
                              const _MessageCard(
                                icon: Icons.summarize_outlined,
                                message:
                                    'Choose a report type and generate a '
                                    'preview.',
                                color: Color(0xFF546E7A),
                              )
                            else
                              _buildPreview(report),
                          ],
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 14,
          runSpacing: 14,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 170,
              child: TextFormField(
                controller: _branchController,
                decoration: const InputDecoration(
                  labelText: 'Branch ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 185,
              child: TextFormField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'Academic Session',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 235,
              child: DropdownButtonFormField<TimetableReportType>(
                initialValue: _reportType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Report Type',
                  border: OutlineInputBorder(),
                ),
                items: TimetableReportType.values
                    .map(
                      (type) => DropdownMenuItem<TimetableReportType>(
                        value: type,
                        child: Text(_reportTypeLabel(type)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: isBusy ? null : _selectReportType,
              ),
            ),
            if (_reportType == TimetableReportType.classTimetable) ...[
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('report_class_$_selectedClassId'),
                  initialValue: _selectedClassId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: _classes
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value.id,
                          child: Text(
                            value.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isBusy ? null : _selectClass,
                ),
              ),
              SizedBox(
                width: 165,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('report_section_$_selectedSectionId'),
                  initialValue: _selectedSectionId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                  ),
                  items: _availableSections
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value.id,
                          child: Text(
                            value.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isBusy
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSectionId = value;
                          });
                        },
                ),
              ),
            ],
            if (_reportType == TimetableReportType.teacherTimetable)
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('report_teacher_$_selectedTeacherId'),
                  initialValue: _selectedTeacherId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Teacher',
                    border: OutlineInputBorder(),
                  ),
                  items: _teachers
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value.id,
                          child: Text(
                            value.fullName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: isBusy
                      ? null
                      : (value) {
                          setState(() {
                            _selectedTeacherId = value;
                          });
                        },
                ),
              ),
            FilledButton.icon(
              onPressed: isBusy ? null : _generateReport,
              icon: const Icon(Icons.preview_outlined),
              label: const Text('Generate Preview'),
            ),
            IconButton.filledTonal(
              onPressed: isBusy ? null : _loadReferenceData,
              tooltip: 'Refresh reference data',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(TimetableReportEntity? report, bool isBusy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.file_download_outlined),
            Text(
              'Export Options',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: report == null || isBusy
                  ? null
                  : () => _export(TimetableReportExportAction.printPdf),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print PDF'),
            ),
            OutlinedButton.icon(
              onPressed: report == null || isBusy
                  ? null
                  : () => _export(TimetableReportExportAction.sharePdf),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Share PDF'),
            ),
            OutlinedButton.icon(
              onPressed: report == null || isBusy
                  ? null
                  : () => _export(TimetableReportExportAction.exportExcel),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Export Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(TimetableReportEntity report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${report.request.reportTitle} Preview',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              _dateTime(report.generatedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (report.request.type == TimetableReportType.teacherWorkload)
          _buildWorkloadPreview(report)
        else
          _buildTimetablePreview(report),
      ],
    );
  }

  Widget _buildTimetablePreview(TimetableReportEntity report) {
    final periods = report.configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList(growable: false);
    final days = report.configuration.workingDays.toList()..sort();
    final bySlot = <String, ClassTimetableEntryEntity>{
      for (final entry in report.entries)
        '${entry.weekday}|${entry.periodId}': entry,
    };

    if (periods.isEmpty || days.isEmpty) {
      return const _MessageCard(
        icon: Icons.event_busy_outlined,
        message: 'No teaching periods or working days are configured.',
        color: Color(0xFFF57C00),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_view_week_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    report.request.reportSubject,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('${report.entries.length} assigned periods'),
              ],
            ),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 120 + (periods.length * 155),
              child: Table(
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                columnWidths: <int, TableColumnWidth>{
                  0: const FixedColumnWidth(120),
                  for (var index = 1; index <= periods.length; index++)
                    index: const FixedColumnWidth(155),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    children: [
                      _tableHeader('Day'),
                      for (final period in periods) _periodHeader(period),
                    ],
                  ),
                  for (final day in days)
                    TableRow(
                      children: [
                        _dayCell(day),
                        for (final period in periods)
                          _timetablePreviewCell(
                            report.request.type,
                            bySlot['$day|${period.id}'],
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadPreview(TimetableReportEntity report) {
    if (report.workloads.isEmpty) {
      return const _MessageCard(
        icon: Icons.person_off_outlined,
        message: 'No active teachers are available.',
        color: Color(0xFFF57C00),
      );
    }

    final totalAssigned = report.totalWorkloadPeriods;
    final average = totalAssigned / report.workloads.length;

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _SummaryCard(
              label: 'Active Teachers',
              value: report.workloads.length.toString(),
              icon: Icons.groups_outlined,
              color: const Color(0xFF3F51B5),
            ),
            _SummaryCard(
              label: 'Assigned Periods',
              value: totalAssigned.toString(),
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF00897B),
            ),
            _SummaryCard(
              label: 'Average / Teacher',
              value: average.toStringAsFixed(1),
              icon: Icons.analytics_outlined,
              color: const Color(0xFF7E57C2),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMinHeight: 62,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('Teacher')),
                DataColumn(label: Text('Designation')),
                DataColumn(label: Text('Assigned'), numeric: true),
                DataColumn(label: Text('Free'), numeric: true),
                DataColumn(label: Text('Days'), numeric: true),
                DataColumn(label: Text('Classes'), numeric: true),
                DataColumn(label: Text('Subjects'), numeric: true),
                DataColumn(label: Text('Utilization')),
                DataColumn(label: Text('Status')),
              ],
              rows: [
                for (final workload in report.workloads)
                  DataRow(
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
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Text(
                            workload.designation,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${workload.assignedPeriods}')),
                      DataCell(Text('${workload.freePeriods}')),
                      DataCell(Text('${workload.teachingDays}')),
                      DataCell(Text('${workload.classSections.length}')),
                      DataCell(Text('${workload.subjects.length}')),
                      DataCell(
                        SizedBox(
                          width: 145,
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
                              Text('${(workload.utilization * 100).round()}%'),
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
        ),
      ],
    );
  }

  Widget _tableHeader(String value) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _periodHeader(TimetablePeriodEntity period) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            period.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatMinutes(period.startMinutes)} - '
            '${_formatMinutes(period.endMinutes)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _dayCell(int weekday) {
    return Container(
      height: 78,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        _dayName(weekday),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _timetablePreviewCell(
    TimetableReportType type,
    ClassTimetableEntryEntity? entry,
  ) {
    if (entry == null) {
      final free = type == TimetableReportType.teacherTimetable;
      return Container(
        height: 78,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(7),
        child: Text(
          free ? 'Free' : 'Not Assigned',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: free
                ? const Color(0xFF00897B)
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: free ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      );
    }

    final secondary = type == TimetableReportType.classTimetable
        ? entry.teacherName
        : '${entry.className} - ${entry.sectionName}';

    return Container(
      height: 78,
      padding: const EdgeInsets.all(7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.subjectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  String _reportTypeLabel(TimetableReportType type) => switch (type) {
    TimetableReportType.classTimetable => 'Class Timetable',
    TimetableReportType.teacherTimetable => 'Teacher Timetable',
    TimetableReportType.teacherWorkload => 'Teacher Workload',
  };

  String _dayName(int weekday) => switch (weekday) {
    DateTime.monday => 'Monday',
    DateTime.tuesday => 'Tuesday',
    DateTime.wednesday => 'Wednesday',
    DateTime.thursday => 'Thursday',
    DateTime.friday => 'Friday',
    DateTime.saturday => 'Saturday',
    DateTime.sunday => 'Sunday',
    _ => 'Day',
  };

  String _formatMinutes(int value) {
    final hour = value ~/ 60;
    final minute = value % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  String _dateTime(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Invalid argument: ', '');
}

class _WorkloadChip extends StatelessWidget {
  const _WorkloadChip({required this.level});

  final TeacherWorkloadLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (level) {
      TeacherWorkloadLevel.unassigned => (
        'Unassigned',
        const Color(0xFF546E7A),
      ),
      TeacherWorkloadLevel.low => ('Low', const Color(0xFF039BE5)),
      TeacherWorkloadLevel.balanced => ('Balanced', const Color(0xFF00897B)),
      TeacherWorkloadLevel.high => ('High', const Color(0xFFF57C00)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
