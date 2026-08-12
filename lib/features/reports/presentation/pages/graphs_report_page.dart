import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../exams/domain/entities/exam_entity.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/repositories/exam_repository.dart';
import '../../../exams/domain/repositories/exam_result_repository.dart';
import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../fees/domain/repositories/monthly_fee_due_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';

class GraphsReportPage extends StatefulWidget {
  const GraphsReportPage({super.key});

  @override
  State<GraphsReportPage> createState() => _GraphsReportPageState();
}

class _GraphsReportPageState extends State<GraphsReportPage> {
  late Future<_GraphsData> _future = _load();

  Future<List<T>> _safe<T>(Future<List<T>> request) async {
    try {
      return await request;
    } catch (_) {
      return <T>[];
    }
  }

  Future<_GraphsData> _load() async {
    final now = DateTime.now();
    final values = await Future.wait<Object>([
      _safe(sl<StudentRepository>().getStudents()),
      _safe(sl<AcademicStructureRepository>().getClasses()),
      _safe(sl<AttendanceRepository>().getAttendanceByDate(now)),
      _safe(
        sl<MonthlyFeeDueRepository>().getMonthlyDues(
          month: now.month,
          year: now.year,
        ),
      ),
      _safe(sl<ExamRepository>().getExams()),
    ]);
    final exams = values[4] as List<ExamEntity>;
    exams.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    List<ExamResultEntity> results = const [];
    ExamEntity? resultExam;
    for (final exam in exams) {
      final current = await _safe(
        sl<ExamResultRepository>().getResultsForExam(exam.id),
      );
      if (current.isNotEmpty) {
        results = current;
        resultExam = exam;
        break;
      }
    }
    return _GraphsData(
      students: values[0] as List<StudentEntity>,
      classes: values[1] as List<AcademicClassEntity>,
      attendance: values[2] as List<AttendanceEntity>,
      dues: values[3] as List<MonthlyFeeDueEntity>,
      results: results,
      resultExamName: resultExam?.name ?? '',
      now: now,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Graphs'),
      actions: [
        IconButton(
          tooltip: 'Refresh graphs',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const DashboardNavigationButton(),
      ],
    ),
    body: FutureBuilder<_GraphsData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final charts = [
          _ChartDefinition(
            title: 'Student Enrollment Distribution',
            subtitle: 'Active students by class',
            icon: Icons.school_outlined,
            slices: data.enrollment,
          ),
          _ChartDefinition(
            title: 'Attendance Distribution',
            subtitle: 'Today: present, absent, late and leave',
            icon: Icons.fact_check_outlined,
            slices: data.attendanceStatus,
          ),
          _ChartDefinition(
            title: 'Fee Status Distribution',
            subtitle: 'Current month fee dues',
            icon: Icons.payments_outlined,
            slices: data.feeStatus,
          ),
          _ChartDefinition(
            title: 'Student Gender Distribution',
            subtitle: 'Active student records',
            icon: Icons.groups_outlined,
            slices: data.gender,
          ),
          _ChartDefinition(
            title: 'Exam Result Distribution',
            subtitle: data.resultExamName.isEmpty
                ? 'No examination result available'
                : 'Latest available exam: ${data.resultExamName}',
            icon: Icons.grade_outlined,
            slices: data.resultGrades,
          ),
        ];
        return RefreshIndicator(
          onRefresh: _refresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 1050 ? 2 : 1;
              final gap = columns == 2 ? 16.0 : 0.0;
              final width = columns == 2
                  ? (constraints.maxWidth - 32 - gap) / 2
                  : constraints.maxWidth - 24;
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(columns == 2 ? 16 : 12),
                child: Wrap(
                  spacing: gap,
                  runSpacing: 16,
                  children: [
                    for (final chart in charts)
                      SizedBox(
                        width: width,
                        child: _PieChartCard(data: chart),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _PieChartCard extends StatelessWidget {
  const _PieChartCard({required this.data});

  final _ChartDefinition data;

  @override
  Widget build(BuildContext context) {
    final total = data.slices.fold<int>(0, (sum, item) => sum + item.value);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 19, child: Icon(data.icon, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        data.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (total == 0)
              const SizedBox(
                height: 230,
                child: Center(child: Text('No data available for this graph.')),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 430;
                  final pie = SizedBox(
                    width: narrow ? constraints.maxWidth : 220,
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 38,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(enabled: true),
                        sections: [
                          for (final slice in data.slices.where(
                            (e) => e.value > 0,
                          ))
                            PieChartSectionData(
                              value: slice.value.toDouble(),
                              color: slice.color,
                              radius: 70,
                              title: '${(slice.value * 100 / total).round()}%',
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                  final legend = _Legend(slices: data.slices, total: total);
                  return narrow
                      ? Column(
                          children: [pie, const SizedBox(height: 8), legend],
                        )
                      : Row(
                          children: [
                            pie,
                            const SizedBox(width: 16),
                            Expanded(child: legend),
                          ],
                        );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.slices, required this.total});
  final List<_Slice> slices;
  final int total;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in slices.where((value) => value.value > 0))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(item.label, overflow: TextOverflow.ellipsis),
              ),
              Text(
                '${item.value} (${(item.value * 100 / total).round()}%)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
    ],
  );
}

class _GraphsData {
  const _GraphsData({
    required this.students,
    required this.classes,
    required this.attendance,
    required this.dues,
    required this.results,
    required this.resultExamName,
    required this.now,
  });

  final List<StudentEntity> students;
  final List<AcademicClassEntity> classes;
  final List<AttendanceEntity> attendance;
  final List<MonthlyFeeDueEntity> dues;
  final List<ExamResultEntity> results;
  final String resultExamName;
  final DateTime now;

  List<StudentEntity> get activeStudents =>
      students.where((student) => student.isActive).toList();

  List<_Slice> get enrollment {
    final names = {for (final value in classes) value.id: value.name};
    final counts = <String, int>{};
    for (final student in activeStudents) {
      final label = names[student.classId] ?? student.classId.trim();
      if (label.isNotEmpty) counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _colorize(sorted);
  }

  List<_Slice> get attendanceStatus => _enumSlices(
    AttendanceStatus.values,
    attendance,
    (record) => record.status,
    const ['Present', 'Absent', 'Leave', 'Late'],
    const [
      Color(0xFF16B67A),
      Color(0xFFEF5350),
      Color(0xFFFFAD28),
      Color(0xFF42A5F5),
    ],
  );

  List<_Slice> get feeStatus {
    var paid = 0, partial = 0, unpaid = 0, overdue = 0;
    for (final due in dues.where(
      (item) => item.status != MonthlyFeeDueStatus.cancelled,
    )) {
      if (due.status == MonthlyFeeDueStatus.paid) {
        paid++;
      } else if (due.status == MonthlyFeeDueStatus.partiallyPaid) {
        partial++;
      } else if (due.dueDate.isBefore(DateTime(now.year, now.month, now.day))) {
        overdue++;
      } else {
        unpaid++;
      }
    }
    return [
      _Slice('Fully Paid', paid, const Color(0xFF16B67A)),
      _Slice('Partially Paid', partial, const Color(0xFF42A5F5)),
      _Slice('Unpaid', unpaid, const Color(0xFFFFAD28)),
      _Slice('Overdue', overdue, const Color(0xFFEF5350)),
    ];
  }

  List<_Slice> get gender {
    final counts = <String, int>{};
    for (final student in activeStudents) {
      final raw = student.gender.trim();
      final label = raw.isEmpty ? 'Not Specified' : raw;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return _colorize(counts.entries.toList());
  }

  List<_Slice> get resultGrades {
    final counts = <String, int>{};
    for (final result in results) {
      final grade = result.grade.trim();
      final label = grade.isEmpty ? (result.isPassed ? 'Pass' : 'Fail') : grade;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _colorize(sorted);
  }

  static List<_Slice> _colorize(List<MapEntry<String, int>> entries) {
    const colors = [
      Color(0xFF2F80ED),
      Color(0xFF16B67A),
      Color(0xFFFFAD28),
      Color(0xFF8B5CF6),
      Color(0xFFEF5350),
      Color(0xFF06B6D4),
      Color(0xFFEC4899),
      Color(0xFF64748B),
      Color(0xFF84CC16),
      Color(0xFFF97316),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
    ];
    return [
      for (var i = 0; i < entries.length; i++)
        _Slice(entries[i].key, entries[i].value, colors[i % colors.length]),
    ];
  }

  static List<_Slice> _enumSlices<T, E>(
    List<E> values,
    List<T> records,
    E Function(T) selector,
    List<String> labels,
    List<Color> colors,
  ) => [
    for (var i = 0; i < values.length; i++)
      _Slice(
        labels[i],
        records.where((item) => selector(item) == values[i]).length,
        colors[i],
      ),
  ];
}

class _ChartDefinition {
  const _ChartDefinition({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.slices,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_Slice> slices;
}

class _Slice {
  const _Slice(this.label, this.value, this.color);
  final String label;
  final int value;
  final Color color;
}
