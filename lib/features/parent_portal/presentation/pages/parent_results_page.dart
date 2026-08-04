import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_results_summary.dart';
import '../../domain/services/parent_results_service.dart';

class ParentResultsPage extends StatefulWidget {
  const ParentResultsPage({super.key, required this.student});

  final StudentEntity student;

  @override
  State<ParentResultsPage> createState() => _ParentResultsPageState();
}

class _ParentResultsPageState extends State<ParentResultsPage> {
  final ParentResultsService _service = sl<ParentResultsService>();

  ParentResultsSummary? _summary;
  bool _loading = true;
  String? _errorMessage;
  String? _selectedResultId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final value = await _service.loadPublishedResults(
        studentId: widget.student.id,
        classId: widget.student.classId,
        sectionId: widget.student.sectionId,
      );

      if (!mounted) return;

      setState(() {
        _summary = value;
        _selectedResultId ??= value.latestResult?.id;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Exception: ', '');
      });
    }
  }

  ExamResultEntity? get _selectedResult {
    final summary = _summary;
    if (summary == null || summary.results.isEmpty) {
      return null;
    }

    for (final result in summary.results) {
      if (result.id == _selectedResultId) {
        return result;
      }
    }

    return summary.latestResult;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.student.fullName} Results')),
      body: RefreshIndicator(onRefresh: _load, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 240),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.error_outline, size: 54),
          const SizedBox(height: 14),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;
    final selected = _selectedResult;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _ResultsSummaryGrid(summary: summary),
        const SizedBox(height: 18),
        if (summary.results.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'No published result is available for this student.',
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          DropdownButtonFormField<String>(
            initialValue: selected?.id,
            decoration: const InputDecoration(
              labelText: 'Select Result',
              border: OutlineInputBorder(),
            ),
            items: summary.results
                .map(
                  (result) => DropdownMenuItem<String>(
                    value: result.id,
                    child: Text(
                      '${result.examName} â€¢ '
                      '${result.percentage.toStringAsFixed(1)}%',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              setState(() => _selectedResultId = value);
            },
          ),
          const SizedBox(height: 16),
          if (selected != null) _ResultDetailCard(result: selected),
        ],
      ],
    );
  }
}

class _ResultsSummaryGrid extends StatelessWidget {
  const _ResultsSummaryGrid({required this.summary});

  final ParentResultsSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Published',
        summary.totalPublishedResults,
        Icons.assignment_turned_in_outlined,
      ),
      ('Passed', summary.passedResults, Icons.check_circle_outline),
      ('Failed', summary.failedResults, Icons.cancel_outlined),
      (
        'Average',
        '${summary.averagePercentage.toStringAsFixed(1)}%',
        Icons.analytics_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 4
            : constraints.maxWidth >= 480
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.4 : 2.0,
          ),
          itemBuilder: (context, index) {
            final item = items[index];

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(item.$3),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.$2}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(item.$1),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultDetailCard extends StatelessWidget {
  const _ResultDetailCard({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.examName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(result.academicSession),
                    ],
                  ),
                ),
                Chip(
                  avatar: Icon(
                    result.isPassed
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    size: 18,
                  ),
                  label: Text(result.isPassed ? 'PASSED' : 'FAILED'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ResultStats(result: result),
            const SizedBox(height: 18),
            Text(
              'Subject-wise Marks',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Obtained')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Remarks')),
                ],
                rows: result.subjectResults
                    .map(
                      (subject) => DataRow(
                        cells: [
                          DataCell(Text(subject.subjectName)),
                          DataCell(Text(subject.totalMarks.toStringAsFixed(1))),
                          DataCell(
                            Text(
                              subject.isAbsent
                                  ? 'Absent'
                                  : subject.obtainedMarks.toStringAsFixed(1),
                            ),
                          ),
                          DataCell(Text(subject.isPassed ? 'Pass' : 'Fail')),
                          DataCell(Text(subject.remarks)),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            if (result.principalRemarks.trim().isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Principal Remarks',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(result.principalRemarks),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.result});

  final ExamResultEntity result;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Total Marks', result.grandTotalMarks.toStringAsFixed(1)),
      ('Obtained', result.grandObtainedMarks.toStringAsFixed(1)),
      ('Percentage', '${result.percentage.toStringAsFixed(1)}%'),
      ('Grade', result.grade),
      ('Class Position', '${result.classPosition}'),
      ('Section Position', '${result.sectionPosition}'),
      ('Overall Rank', '${result.overallRank}'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) => Chip(label: Text('${item.$1}: ${item.$2}')))
          .toList(growable: false),
    );
  }
}
