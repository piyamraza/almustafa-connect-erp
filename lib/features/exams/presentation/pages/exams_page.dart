import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_entity.dart';
import '../bloc/exam_bloc.dart';
import '../bloc/exam_event.dart';
import '../bloc/exam_state.dart';
import 'add_exam_page.dart';
import 'exam_date_sheet_dashboard_page.dart';
import 'edit_exam_page.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamBloc>(
      create: (_) => sl<ExamBloc>()..add(const LoadExams()),
      child: const _ExamsView(),
    );
  }
}

class _ExamsView extends StatefulWidget {
  const _ExamsView();

  @override
  State<_ExamsView> createState() => _ExamsViewState();
}

class _ExamsViewState extends State<_ExamsView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<ExamBloc>();
    final nextState = bloc.stream.firstWhere(
      (state) => state is ExamLoaded || state is ExamError,
    );
    bloc.add(const RefreshExams());
    await nextState;
  }

  Future<void> _openAddPage() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: context.read<ExamBloc>(),
          child: const AddExamPage(),
        ),
      ),
    );
  }

  Future<void> _openEditPage(ExamEntity exam) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => BlocProvider.value(
          value: context.read<ExamBloc>(),
          child: EditExamPage(exam: exam),
        ),
      ),
    );
  }

  Future<void> _deleteExam(ExamEntity exam) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: const Text('Delete Exam'),
        content: Text('Delete "${exam.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      context.read<ExamBloc>().add(DeleteExam(exam.id));
    }
  }

  void _showExamDetails(ExamEntity exam) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(exam.name),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: 'Academic Session',
                  value: exam.academicSession,
                ),
                _DetailRow(
                  label: 'Start Date',
                  value: _formatDate(dialogContext, exam.startDate),
                ),
                _DetailRow(
                  label: 'End Date',
                  value: _formatDate(dialogContext, exam.endDate),
                ),
                _DetailRow(
                  label: 'Result Date',
                  value: _formatDate(dialogContext, exam.resultDate),
                ),
                _DetailRow(
                  label: 'Status',
                  value: exam.isActive ? 'Active' : 'Inactive',
                ),
                if (exam.description.trim().isNotEmpty)
                  _DetailRow(label: 'Description', value: exam.description),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Management'),
        actions: [const DashboardNavigationButton(),
          IconButton(
            tooltip: 'Date Sheets',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ExamDateSheetDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) {
                context.read<ExamBloc>().add(SearchExams(value));
              },
              decoration: InputDecoration(
                hintText: 'Search by exam name, academic session, or status...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ExamBloc>().add(const SearchExams(''));
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocConsumer<ExamBloc, ExamState>(
                listener: (context, state) {
                  if (state is ExamError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                  if (state is ExamLoaded && state.successMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.successMessage!)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ExamInitial || state is ExamLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ExamError) {
                    return _MessageState(
                      icon: Icons.error_outline,
                      message: 'Unable to load exams.',
                      actionLabel: 'Try Again',
                      onAction: () =>
                          context.read<ExamBloc>().add(const RefreshExams()),
                    );
                  }

                  final exams = state is ExamLoaded
                      ? state.exams
                      : const <ExamEntity>[];
                  if (exams.isEmpty) {
                    return _MessageState(
                      icon: Icons.assignment_outlined,
                      message: 'No exams found.',
                      actionLabel: 'Add Exam',
                      onAction: _openAddPage,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: exams.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) => _ExamListCard(
                            exam: exams[index],
                            isDesktop: constraints.maxWidth >= 900,
                            onTap: () => _showExamDetails(exams[index]),
                            onEdit: () => _openEditPage(exams[index]),
                            onDelete: () => _deleteExam(exams[index]),
                            onStatusChanged: (isActive) =>
                                context.read<ExamBloc>().add(
                                  ToggleExamActiveStatus(
                                    examId: exams[index].id,
                                    isActive: isActive,
                                  ),
                                ),
                          ),
                        );
                      },
                    ),
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

class _ExamListCard extends StatelessWidget {
  const _ExamListCard({
    required this.exam,
    required this.isDesktop,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final ExamEntity exam;
  final bool isDesktop;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dates = [
      'Start: ${_formatDate(context, exam.startDate)}',
      'End: ${_formatDate(context, exam.endDate)}',
      'Result: ${_formatDate(context, exam.resultDate)}',
    ].join('  •  ');

    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exam.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          exam.academicSession,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dates,
          maxLines: isDesktop ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _ExamStatusChip(isActive: exam.isActive),
        Switch(value: exam.isActive, onChanged: onStatusChanged),
        IconButton(
          tooltip: 'Edit exam',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        ),
        IconButton(
          tooltip: 'Delete exam',
          icon: Icon(Icons.delete_outline, color: colors.error),
          onPressed: onDelete,
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: isDesktop
              ? Row(
                  children: [
                    Icon(Icons.assignment_outlined, color: colors.primary),
                    const SizedBox(width: 16),
                    Expanded(child: information),
                    const SizedBox(width: 24),
                    actions,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment_outlined, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(child: information),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ExamStatusChip extends StatelessWidget {
  const _ExamStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(isActive ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: isActive
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isActive ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

String _formatDate(BuildContext context, DateTime? value) {
  if (value == null) {
    return '-';
  }
  return MaterialLocalizations.of(context).formatMediumDate(value);
}
