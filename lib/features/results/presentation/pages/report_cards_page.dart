import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../exams/domain/entities/exam_result_entity.dart';
import '../bloc/results_bloc.dart';
import '../bloc/results_event.dart';
import '../bloc/results_state.dart';
import '../widgets/published_results_filter_card.dart';
import 'individual_report_card_page.dart';

class ReportCardsPage extends StatelessWidget {
  const ReportCardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ResultsBloc>()..add(const LoadPublishedResults()),
      child: const _ReportCardsView(),
    );
  }
}

class _ReportCardsView extends StatelessWidget {
  const _ReportCardsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Cards'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context
                .read<ResultsBloc>()
                .add(const RefreshPublishedResults()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocBuilder<ResultsBloc, ResultsState>(
        builder: (context, state) => switch (state) {
          ResultsInitial() || ResultsLoading() =>
            const Center(child: CircularProgressIndicator()),
          ResultsFailure(:final message) => _ErrorState(message: message),
          PublishedResultsLoaded() => _ReportCardsContent(data: state),
        },
      ),
    );
  }
}

class _ReportCardsContent extends StatelessWidget {
  const _ReportCardsContent({required this.data});

  final PublishedResultsLoaded data;

  @override
  Widget build(BuildContext context) {
    final results = data.filteredResults;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.isLoading) const SizedBox(height: 12),
            PublishedResultsFilterCard(data: data, includeStudent: true),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${results.length} published report card${results.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results.isEmpty
                  ? const _EmptyState(
                      message: 'No published report cards match the selected filters.',
                    )
                  : _ReportCardList(results: results),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardList extends StatelessWidget {
  const _ReportCardList({required this.results});

  final List<ExamResultEntity> results;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1120
            ? 3
            : constraints.maxWidth >= 700
                ? 2
                : 1;
        return GridView.builder(
          itemCount: results.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 1.25 : 1.38,
          ),
          itemBuilder: (context, index) {
            final result = results[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(context, result),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(
                              result.studentName.trim().isEmpty
                                  ? '?'
                                  : result.studentName.trim()[0].toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              result.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text('${result.examName} • ${result.academicSession}'),
                      const SizedBox(height: 4),
                      Text('Class ${result.className}-${result.sectionName}'),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${result.percentage.toStringAsFixed(1)}% • ${result.grade}',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(Icons.description_outlined),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _open(context, result),
                          child: const Text('Open Report Card'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _open(BuildContext context, ExamResultEntity result) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => IndividualReportCardPage(result: result),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

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
                    .read<ResultsBloc>()
                    .add(const LoadPublishedResults()),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
}
