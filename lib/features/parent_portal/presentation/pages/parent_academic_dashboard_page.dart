import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_academic_dashboard_entity.dart';
import '../../domain/entities/parent_academic_item_entity.dart';
import '../bloc/parent_academic_bloc.dart';

class ParentAcademicDashboardPage extends StatelessWidget {
  const ParentAcademicDashboardPage({
    super.key,
    required this.student,
    this.academicSession = '2026-2027',
  });

  final StudentEntity student;
  final String academicSession;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentAcademicBloc>()
        ..add(
          LoadParentAcademicDashboard(
            student: student,
            academicSession: academicSession,
          ),
        ),
      child: _View(student: student, academicSession: academicSession),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.student, required this.academicSession});

  final StudentEntity student;
  final String academicSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${student.fullName} - Academic Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<ParentAcademicBloc>().add(
                LoadParentAcademicDashboard(
                  student: student,
                  academicSession: academicSession,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ParentAcademicBloc, ParentAcademicState>(
        builder: (context, state) {
          return switch (state) {
            ParentAcademicInitial() || ParentAcademicLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ParentAcademicError(:final message) => Center(child: Text(message)),
            ParentAcademicLoaded(:final dashboard) => _DashboardContent(
              student: student,
              dashboard: dashboard,
            ),
          };
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.student, required this.dashboard});

  final StudentEntity student;
  final ParentAcademicDashboardEntity dashboard;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryCard(
                  label: 'Attendance',
                  value:
                      '${dashboard.attendancePercentage.toStringAsFixed(1)}%',
                  icon: Icons.fact_check_outlined,
                ),
                _SummaryCard(
                  label: 'Pending Homework',
                  value: '${dashboard.pendingHomeworkCount}',
                  icon: Icons.menu_book_outlined,
                ),
                _SummaryCard(
                  label: 'Submitted Homework',
                  value: '${dashboard.submittedHomeworkCount}',
                  icon: Icons.assignment_turned_in_outlined,
                ),
                _SummaryCard(
                  label: 'Upcoming Exams',
                  value: '${dashboard.upcomingExamCount}',
                  icon: Icons.calendar_month_outlined,
                ),
                _SummaryCard(
                  label: 'Latest Result',
                  value: dashboard.latestResultPercentage == null
                      ? 'N/A'
                      : '${dashboard.latestResultPercentage!.toStringAsFixed(1)}%',
                  icon: Icons.grade_outlined,
                ),
              ],
            ),
          ),
          const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Attendance'),
              Tab(text: 'Timetable'),
              Tab(text: 'Homework'),
              Tab(text: 'Date Sheet'),
              Tab(text: 'Results'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ItemsList(
                  items: dashboard.attendanceItems,
                  emptyMessage: 'No attendance records found.',
                ),
                _ItemsList(
                  items: dashboard.timetableItems,
                  emptyMessage: 'No timetable entries found.',
                ),
                _ItemsList(
                  items: dashboard.homeworkItems,
                  emptyMessage: 'No homework records found.',
                ),
                _ItemsList(
                  items: dashboard.dateSheetItems,
                  emptyMessage: 'No date sheet records found.',
                ),
                _ItemsList(
                  items: dashboard.resultItems,
                  emptyMessage: 'No published results found.',
                ),
              ],
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
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(label),
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

class _ItemsList extends StatelessWidget {
  const _ItemsList({required this.items, required this.emptyMessage});

  final List<ParentAcademicItemEntity> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        return Card(
          child: ExpansionTile(
            leading: CircleAvatar(child: Icon(_icon(item.module))),
            title: Text(item.title),
            subtitle: Text(item.subtitle),
            trailing: Chip(label: Text(item.status)),
            children: [
              if (item.date != null)
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('Date'),
                  trailing: Text(_date(item.date!)),
                ),
              for (final entry in item.details.entries)
                if (entry.value.isNotEmpty)
                  ListTile(
                    title: Text(_label(entry.key)),
                    subtitle: Text(entry.value),
                  ),
            ],
          ),
        );
      },
    );
  }

  static IconData _icon(ParentAcademicModule module) => switch (module) {
    ParentAcademicModule.attendance => Icons.fact_check_outlined,
    ParentAcademicModule.timetable => Icons.schedule_outlined,
    ParentAcademicModule.homework => Icons.menu_book_outlined,
    ParentAcademicModule.dateSheet => Icons.calendar_month_outlined,
    ParentAcademicModule.results => Icons.grade_outlined,
  };

  static String _label(String value) {
    final spaced = value.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return spaced.isEmpty
        ? value
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
