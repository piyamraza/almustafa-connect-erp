import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/homework_submission_entity.dart';
import '../bloc/homework_submission_bloc.dart';
import 'homework_review_page.dart';

class HomeworkSubmissionsDashboardPage extends StatelessWidget {
  const HomeworkSubmissionsDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<HomeworkSubmissionBloc>()..add(const LoadHomeworkSubmissions()),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  HomeworkSubmissionStatus? _filter;

  Future<void> _review(HomeworkSubmissionEntity submission) async {
    final value = await Navigator.of(context).push<HomeworkSubmissionEntity>(
      MaterialPageRoute(
        builder: (_) => HomeworkReviewPage(submission: submission),
      ),
    );
    if (value != null && mounted) {
      context.read<HomeworkSubmissionBloc>().add(SaveHomeworkSubmission(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Homework Submissions'),
      ),
      body: BlocConsumer<HomeworkSubmissionBloc, HomeworkSubmissionState>(
        listener: (context, state) {
          final message = switch (state) {
            HomeworkSubmissionLoaded(:final message) => message,
            HomeworkSubmissionError(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final loading = state is HomeworkSubmissionLoading;
          final items = state is HomeworkSubmissionLoaded
              ? state.items
              : <HomeworkSubmissionEntity>[];

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          SizedBox(
                            width: 220,
                            child:
                                DropdownButtonFormField<
                                  HomeworkSubmissionStatus?
                                >(
                                  initialValue: _filter,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('All'),
                                    ),
                                    ...HomeworkSubmissionStatus.values.map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.name.toUpperCase()),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _filter = value);
                                    context.read<HomeworkSubmissionBloc>().add(
                                      LoadHomeworkSubmissions(status: value),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text('Total: ${items.length}')),
                      Chip(
                        label: Text(
                          'Submitted: ${items.where((e) => e.status == HomeworkSubmissionStatus.submitted).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Late: ${items.where((e) => e.isLate).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Reviewed: ${items.where((e) => e.status == HomeworkSubmissionStatus.reviewed).length}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final item in items)
                    Card(
                      child: ListTile(
                        onTap: () => _review(item),
                        leading: const CircleAvatar(
                          child: Icon(Icons.assignment_turned_in),
                        ),
                        title: Text(item.studentName),
                        subtitle: Text(
                          '${item.admissionNo} • '
                          '${item.status.name.toUpperCase()} • '
                          '${item.attachments.length} attachment(s)',
                        ),
                        trailing: item.isLate
                            ? const Chip(label: Text('LATE'))
                            : null,
                      ),
                    ),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }
}
