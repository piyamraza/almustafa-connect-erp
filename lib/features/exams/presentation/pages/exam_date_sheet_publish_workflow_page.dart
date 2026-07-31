import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/exam_date_sheet_entity.dart';
import '../bloc/exam_date_sheet_workflow_bloc.dart';
import 'manual_exam_date_sheet_builder_page.dart';

class ExamDateSheetPublishWorkflowPage extends StatelessWidget {
  const ExamDateSheetPublishWorkflowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExamDateSheetWorkflowBloc>(
      create: (_) =>
          sl<ExamDateSheetWorkflowBloc>()
            ..add(const LoadExamDateSheetWorkflow()),
      child: const _PublishWorkflowView(),
    );
  }
}

class _PublishWorkflowView extends StatefulWidget {
  const _PublishWorkflowView();

  @override
  State<_PublishWorkflowView> createState() => _PublishWorkflowViewState();
}

class _PublishWorkflowViewState extends State<_PublishWorkflowView> {
  ExamDateSheetStatus? _statusFilter;

  Future<bool> _confirm({
    required String title,
    required String message,
    String action = 'Confirm',
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDraft(ExamDateSheetEntity draft) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualExamDateSheetBuilderPage(existing: draft),
      ),
    );

    if (saved == true && mounted) {
      context.read<ExamDateSheetWorkflowBloc>().add(
        const LoadExamDateSheetWorkflow(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Sheet Publish Workflow'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => context.read<ExamDateSheetWorkflowBloc>().add(
              const LoadExamDateSheetWorkflow(),
            ),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child:
            BlocConsumer<ExamDateSheetWorkflowBloc, ExamDateSheetWorkflowState>(
              listener: (context, state) {
                if (state is ExamDateSheetWorkflowLoaded) {
                  if (state.message != null) {
                    _show(state.message!);
                  }
                  if (state.createdDraft != null) {
                    _openDraft(state.createdDraft!);
                  }
                } else if (state is ExamDateSheetWorkflowError) {
                  _show(state.message);
                }
              },
              builder: (context, state) {
                final busy = state is ExamDateSheetWorkflowLoading;
                final all = state is ExamDateSheetWorkflowLoaded
                    ? state.dateSheets
                    : const <ExamDateSheetEntity>[];
                final values = _statusFilter == null
                    ? all
                    : all
                          .where((item) => item.status == _statusFilter)
                          .toList(growable: false);

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
                                'Publish Workflow',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Review drafts, publish final schedules, create '
                                'revisions and archive outdated date sheets.',
                              ),
                              const SizedBox(height: 18),
                              _summary(all),
                              const SizedBox(height: 14),
                              _filterBar(busy),
                              const SizedBox(height: 14),
                              if (values.isEmpty && !busy)
                                const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'No date sheets match this filter.',
                                    ),
                                  ),
                                )
                              else
                                ...values.map(
                                  (dateSheet) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _workflowCard(dateSheet, busy),
                                  ),
                                ),
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

  Widget _summary(List<ExamDateSheetEntity> values) {
    int count(ExamDateSheetStatus status) =>
        values.where((item) => item.status == status).length;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _summaryChip(
          'Draft',
          count(ExamDateSheetStatus.draft),
          Icons.edit_note_outlined,
        ),
        _summaryChip(
          'Published',
          count(ExamDateSheetStatus.published),
          Icons.verified_outlined,
        ),
        _summaryChip(
          'Archived',
          count(ExamDateSheetStatus.archived),
          Icons.archive_outlined,
        ),
      ],
    );
  }

  Widget _summaryChip(String label, int value, IconData icon) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
  }

  Widget _filterBar(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Filter:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ChoiceChip(
              label: const Text('All'),
              selected: _statusFilter == null,
              onSelected: busy
                  ? null
                  : (_) => setState(() => _statusFilter = null),
            ),
            for (final status in ExamDateSheetStatus.values)
              ChoiceChip(
                label: Text(_statusLabel(status)),
                selected: _statusFilter == status,
                onSelected: busy
                    ? null
                    : (_) => setState(() => _statusFilter = status),
              ),
          ],
        ),
      ),
    );
  }

  Widget _workflowCard(ExamDateSheetEntity dateSheet, bool busy) {
    final color = switch (dateSheet.status) {
      ExamDateSheetStatus.draft => const Color(0xFF1976D2),
      ExamDateSheetStatus.published => const Color(0xFF00897B),
      ExamDateSheetStatus.archived => const Color(0xFF546E7A),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(24),
              child: Icon(_statusIcon(dateSheet.status), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dateSheet.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Chip(
                        label: Text(
                          _statusLabel(dateSheet.status).toUpperCase(),
                        ),
                        backgroundColor: color.withAlpha(24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${dateSheet.examName} • '
                    '${dateSheet.academicSession} • '
                    '${dateSheet.paperCount} papers',
                  ),
                  Text(
                    'Updated: ${_dateTime(dateSheet.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (dateSheet.publishedAt != null)
                    Text(
                      'Published: ${_dateTime(dateSheet.publishedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (dateSheet.status == ExamDateSheetStatus.draft) ...[
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => _openDraft(dateSheet),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Draft'),
                        ),
                        FilledButton.icon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await _confirm(
                                    title: 'Publish Date Sheet',
                                    message:
                                        'Publish this date sheet as the '
                                        'current final schedule? Any existing '
                                        'published date sheet for this exam '
                                        'will be archived.',
                                    action: 'Publish',
                                  );
                                  if (confirmed && mounted) {
                                    context
                                        .read<ExamDateSheetWorkflowBloc>()
                                        .add(PublishExamDateSheet(dateSheet));
                                  }
                                },
                          icon: const Icon(Icons.publish_outlined),
                          label: const Text('Publish'),
                        ),
                      ],
                      if (dateSheet.status == ExamDateSheetStatus.published)
                        FilledButton.tonalIcon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await _confirm(
                                    title: 'Create Revision',
                                    message:
                                        'Create a new editable draft from '
                                        'this published date sheet? The '
                                        'published original will remain '
                                        'unchanged.',
                                    action: 'Create Draft',
                                  );
                                  if (confirmed && mounted) {
                                    context
                                        .read<ExamDateSheetWorkflowBloc>()
                                        .add(ReviseExamDateSheet(dateSheet));
                                  }
                                },
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: const Text('Revise'),
                        ),
                      if (dateSheet.status == ExamDateSheetStatus.archived)
                        FilledButton.tonalIcon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await _confirm(
                                    title: 'Revise Archived Date Sheet',
                                    message:
                                        'Create a new editable draft from '
                                        'this archived date sheet?',
                                    action: 'Create Draft',
                                  );
                                  if (confirmed && mounted) {
                                    context
                                        .read<ExamDateSheetWorkflowBloc>()
                                        .add(ReviseExamDateSheet(dateSheet));
                                  }
                                },
                          icon: const Icon(Icons.restore_page_outlined),
                          label: const Text('Copy as Draft'),
                        ),
                      if (dateSheet.status != ExamDateSheetStatus.archived)
                        TextButton.icon(
                          onPressed: busy
                              ? null
                              : () async {
                                  final confirmed = await _confirm(
                                    title: 'Archive Date Sheet',
                                    message:
                                        'Archive this date sheet? It will '
                                        'remain available in history and '
                                        'reports.',
                                    action: 'Archive',
                                  );
                                  if (confirmed && mounted) {
                                    context
                                        .read<ExamDateSheetWorkflowBloc>()
                                        .add(ArchiveExamDateSheet(dateSheet));
                                  }
                                },
                          icon: const Icon(Icons.archive_outlined),
                          label: const Text('Archive'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(ExamDateSheetStatus status) => switch (status) {
    ExamDateSheetStatus.draft => 'Draft',
    ExamDateSheetStatus.published => 'Published',
    ExamDateSheetStatus.archived => 'Archived',
  };

  static IconData _statusIcon(ExamDateSheetStatus status) => switch (status) {
    ExamDateSheetStatus.draft => Icons.edit_note_outlined,
    ExamDateSheetStatus.published => Icons.verified_outlined,
    ExamDateSheetStatus.archived => Icons.archive_outlined,
  };

  static String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}
