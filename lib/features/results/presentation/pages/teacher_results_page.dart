import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/teacher_subject_result_summary.dart';
import '../bloc/teacher_results_bloc.dart';
import '../bloc/teacher_results_event.dart';
import '../bloc/teacher_results_state.dart';

class TeacherResultsPage extends StatelessWidget {
  const TeacherResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TeacherResultsBloc>()..add(const LoadTeacherResults()),
      child: const _TeacherResultsView(),
    );
  }
}

class _TeacherResultsView extends StatelessWidget {
  const _TeacherResultsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Results'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<TeacherResultsBloc>()
                .add(const RefreshTeacherResults()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<TeacherResultsBloc, TeacherResultsState>(
        builder: (context, state) => switch (state) {
          TeacherResultsInitial() || TeacherResultsLoading() =>
            const Center(child: CircularProgressIndicator()),
          TeacherResultsFailure(:final message) => _TeacherResultsError(message: message),
          TeacherResultsLoaded() => _TeacherResultsContent(data: state),
        },
      ),
    );
  }
}

class _TeacherResultsContent extends StatelessWidget {
  const _TeacherResultsContent({required this.data});

  final TeacherResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final isReady = data.selectedTeacherId != null &&
        data.selectedAcademicSession != null &&
        data.selectedExamId != null;
    final summaries = isReady
        ? buildTeacherSubjectSummaries(data)
        : const <TeacherSubjectResultSummary>[];
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1450),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.isLoading) const LinearProgressIndicator(),
                if (data.isLoading) const SizedBox(height: 12),
                _TeacherResultsFilters(data: data),
                const SizedBox(height: 18),
                if (!isReady)
                  const _TeacherResultsHint()
                else if (summaries.isEmpty)
                  const _TeacherResultsEmpty()
                else ...[
                  _TeacherSummaryCards(summaries: summaries),
                  const SizedBox(height: 20),
                  Text(
                    '${data.selectedTeacher?.fullName ?? 'Teacher'} — Subject Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TeacherSubjectGrid(summaries: summaries),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeacherResultsFilters extends StatelessWidget {
  const _TeacherResultsFilters({required this.data});

  final TeacherResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TeacherResultsBloc>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width < 430 ? 230 : 320,
              child: DropdownButtonFormField<String>(
                value: data.availableTeachers
                        .any((teacher) => teacher.id == data.selectedTeacherId)
                    ? data.selectedTeacherId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Teacher',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Select teacher'),
                  ),
                  ...data.availableTeachers.map(
                    (teacher) => DropdownMenuItem<String>(
                      value: teacher.id,
                      child: Text(
                        '${teacher.fullName} (${teacher.employeeId})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => bloc.add(SelectTeacherForResults(value)),
              ),
            ),
            _StringFilter(
              label: 'Academic Session',
              value: data.selectedAcademicSession,
              items: data.availableSessions
                  .map((session) => _Option(session, session))
                  .toList(growable: false),
              onChanged: (value) =>
                  bloc.add(FilterTeacherResultsBySession(value)),
            ),
            _StringFilter(
              label: 'Exam',
              value: data.selectedExamId,
              items: data.availableExams
                  .map((exam) => _Option(exam.examId, exam.examName))
                  .toList(growable: false),
              onChanged: (value) => bloc.add(FilterTeacherResultsByExam(value)),
            ),
            const Chip(
              avatar: Icon(Icons.visibility_outlined, size: 16),
              label: Text('Published results only'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StringFilter extends StatelessWidget {
  const _StringFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<_Option> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        value: items.any((item) => item.id == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Select')),
          ...items.map(
            (item) => DropdownMenuItem<String>(
              value: item.id,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _Option {
  const _Option(this.id, this.label);

  final String id;
  final String label;
}

class _TeacherSummaryCards extends StatelessWidget {
  const _TeacherSummaryCards({required this.summaries});

  final List<TeacherSubjectResultSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final students = summaries.fold<int>(
      0,
      (total, summary) => total + summary.totalStudents,
    );
    final passed = summaries.fold<int>(
      0,
      (total, summary) => total + summary.passedStudents,
    );
    final passRate = students == 0 ? 0.0 : (passed / students) * 100;
    final failed = students - passed;
    final failRate = students == 0 ? 0.0 : (failed / students) * 100;
    final cards = [
      _SummaryCard(
        label: 'Assigned Subjects',
        value: '${summaries.length}',
        icon: Icons.menu_book_outlined,
      ),
      _SummaryCard(
        label: 'Students Assessed',
        value: '$students',
        icon: Icons.groups_outlined,
      ),
      _SummaryCard(
        label: 'Passed',
        value: '$passed',
        icon: Icons.check_circle_outline,
      ),
      _SummaryCard(
        label: 'Failed',
        value: '$failed',
        icon: Icons.cancel_outlined,
      ),
      _SummaryCard(
        label: 'Pass Percentage',
        value: '${passRate.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
      ),
      _SummaryCard(
        label: 'Fail Percentage',
        value: '${failRate.toStringAsFixed(1)}%',
        icon: Icons.percent_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1350
            ? 6
            : constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 650
                ? 2
                : 1;
        final width =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, height: 96, child: card))
              .toList(growable: false),
        );
      },
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
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _TeacherSubjectGrid extends StatelessWidget {
  const _TeacherSubjectGrid({required this.summaries});

  final List<TeacherSubjectResultSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 680
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: summaries.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: columns == 1 ? 1.15 : 0.98,
          ),
          itemBuilder: (context, index) =>
              _TeacherSubjectCard(summary: summaries[index]),
        );
      },
    );
  }
}

class _TeacherSubjectCard extends StatelessWidget {
  const _TeacherSubjectCard({required this.summary});

  final TeacherSubjectResultSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.subjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text('${summary.className}-${summary.sectionName}'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Metric(label: 'Students', value: '${summary.totalStudents}'),
                _Metric(label: 'Pass', value: '${summary.passedStudents}'),
                _Metric(label: 'Fail', value: '${summary.failedStudents}'),
                _Metric(
                  label: 'Pass %',
                  value: '${summary.passPercentage.toStringAsFixed(1)}%',
                ),
                _Metric(
                  label: 'Fail %',
                  value: '${summary.failPercentage.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Percentage Distribution',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: summary.performanceBands
                      .map(
                        (band) => Chip(
                          label: Text('${band.label}: ${band.count}'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: colors.secondaryContainer,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
}

class _TeacherResultsHint extends StatelessWidget {
  const _TeacherResultsHint();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Center(
          child: Text(
            'Select a teacher, academic session, and exam to view subject results.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _TeacherResultsEmpty extends StatelessWidget {
  const _TeacherResultsEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 72),
        child: Center(
          child: Text(
            'No published subject results were found for this teacher selection.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _TeacherResultsError extends StatelessWidget {
  const _TeacherResultsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 46),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context
                    .read<TeacherResultsBloc>()
                    .add(const LoadTeacherResults()),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
