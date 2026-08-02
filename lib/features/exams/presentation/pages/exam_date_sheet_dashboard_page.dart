import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../bloc/exam_date_sheet_bloc.dart';
import 'auto_exam_date_sheet_generator_page.dart';
import 'exam_date_sheet_publish_workflow_page.dart';
import 'exam_date_sheet_reports_page.dart';
import 'manual_exam_date_sheet_builder_page.dart';

class ExamDateSheetDashboardPage extends StatelessWidget {
  const ExamDateSheetDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamDateSheetBloc>(
      create: (_) => sl<ExamDateSheetBloc>()..add(const LoadExamDateSheets()),
      child: const _ExamDateSheetDashboardView(),
    );
  }
}

class _ExamDateSheetDashboardView extends StatelessWidget {
  const _ExamDateSheetDashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Exam Date Sheets'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date Sheet Management',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create date sheets manually or generate multiple '
              'conflict-free options automatically.',
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _ActionCard(
                  title: 'Auto Generate',
                  description:
                      'Generate 2–3 date sheet options from selected dates.',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF7E57C2),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const AutoExamDateSheetGeneratorPage(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<ExamDateSheetBloc>().add(
                        const LoadExamDateSheets(),
                      );
                    }
                  },
                ),
                _ActionCard(
                  title: 'Manual Date Sheet',
                  description: 'Create and edit every paper manually.',
                  icon: Icons.edit_calendar_outlined,
                  color: const Color(0xFF00897B),
                  onTap: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => const ManualExamDateSheetBuilderPage(),
                      ),
                    );
                    if (saved == true && context.mounted) {
                      context.read<ExamDateSheetBloc>().add(
                        const LoadExamDateSheets(),
                      );
                    }
                  },
                ),
                _ActionCard(
                  title: 'Reports & Print',
                  description:
                      'Print parent copies, school reports and teacher duty sheets.',
                  icon: Icons.print_outlined,
                  color: const Color(0xFF546E7A),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExamDateSheetReportsPage(),
                      ),
                    );
                  },
                ),
                _ActionCard(
                  title: 'Publish Workflow',
                  description:
                      'Publish, revise and archive date sheets safely.',
                  icon: Icons.publish_outlined,
                  color: const Color(0xFF2E7D32),
                  onTap: () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const ExamDateSheetPublishWorkflowPage(),
                      ),
                    );
                    if (context.mounted) {
                      context.read<ExamDateSheetBloc>().add(
                        const LoadExamDateSheets(),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Saved Date Sheets',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocConsumer<ExamDateSheetBloc, ExamDateSheetState>(
                listener: (context, state) {
                  if (state is ExamDateSheetLoaded && state.message != null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message!)));
                  } else if (state is ExamDateSheetError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (state is ExamDateSheetInitial ||
                      state is ExamDateSheetLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is ExamDateSheetError) {
                    return Center(child: Text(state.message));
                  }

                  final values = state is ExamDateSheetLoaded
                      ? state.values
                      : const <ExamDateSheetEntity>[];

                  if (values.isEmpty) {
                    return const Center(
                      child: Text('No date sheets created yet.'),
                    );
                  }

                  return ListView.separated(
                    itemCount: values.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = values[index];
                      Future<void> openDateSheet() async {
                        final saved = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) =>
                                ManualExamDateSheetBuilderPage(existing: item),
                          ),
                        );
                        if (saved == true && context.mounted) {
                          context.read<ExamDateSheetBloc>().add(
                            const LoadExamDateSheets(),
                          );
                        }
                      }

                      return Card(
                        child: ListTile(
                          onTap: openDateSheet,
                          leading: const CircleAvatar(
                            child: Icon(Icons.calendar_month_outlined),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.examName} • ${item.academicSession} • '
                            '${item.paperCount} papers',
                          ),
                          trailing: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(label: Text(item.status.name.toUpperCase())),
                              IconButton(
                                tooltip:
                                    item.status == ExamDateSheetStatus.draft
                                    ? 'Open and edit'
                                    : 'Open date sheet',
                                onPressed: openDateSheet,
                                icon: Icon(
                                  item.status == ExamDateSheetStatus.draft
                                      ? Icons.edit_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Delete',
                                onPressed: () => context
                                    .read<ExamDateSheetBloc>()
                                    .add(DeleteExamDateSheet(item.id)),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(25),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
