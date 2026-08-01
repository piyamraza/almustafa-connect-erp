import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/homework_entity.dart';
import '../bloc/homework_bloc.dart';
import 'homework_form_page.dart';
import 'homework_submissions_dashboard_page.dart';

class HomeworkDashboardPage extends StatelessWidget {
  const HomeworkDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HomeworkBloc>()..add(const LoadHomework('2026-2027')),
      child: const _HomeworkDashboardView(),
    );
  }
}

class _HomeworkDashboardView extends StatefulWidget {
  const _HomeworkDashboardView();

  @override
  State<_HomeworkDashboardView> createState() => _HomeworkDashboardViewState();
}

class _HomeworkDashboardViewState extends State<_HomeworkDashboardView> {
  final _session = TextEditingController(text: '2026-2027');
  HomeworkStatus? _filter;
  final Set<String> _selected = {};

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _load() {
    _selected.clear();
    context.read<HomeworkBloc>().add(
      LoadHomework(_session.text.trim(), status: _filter),
    );
  }

  Future<void> _open({
    HomeworkEntity? existing,
    HomeworkEntity? copyFrom,
  }) async {
    final value = await Navigator.of(context).push<HomeworkEntity>(
      MaterialPageRoute(
        builder: (_) => HomeworkFormPage(
          existing: existing,
          copyFrom: copyFrom,
          academicSession: _session.text.trim(),
        ),
      ),
    );
    if (value != null && mounted) {
      context.read<HomeworkBloc>().add(SaveHomework(value));
    }
  }

  List<HomeworkEntity> _selectedItems(List<HomeworkEntity> items) =>
      items.where((item) => _selected.contains(item.id)).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Management'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const HomeworkSubmissionsDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Submissions'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(),
        icon: const Icon(Icons.add),
        label: const Text('Create Homework'),
      ),
      body: BlocConsumer<HomeworkBloc, HomeworkState>(
        listener: (context, state) {
          final message = switch (state) {
            HomeworkLoaded(:final message) => message,
            HomeworkError(:final message) => message,
            _ => null,
          };
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final loading = state is HomeworkLoading;
          final items = state is HomeworkLoaded
              ? state.items
              : <HomeworkEntity>[];
          final selectedItems = _selectedItems(items);
          final tomorrow = DateTime.now().add(const Duration(days: 1));

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
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 190,
                            child: TextField(
                              controller: _session,
                              decoration: const InputDecoration(
                                labelText: 'Academic Session',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 190,
                            child: DropdownButtonFormField<HomeworkStatus?>(
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
                                ...HomeworkStatus.values.map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name.toUpperCase()),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _filter = value),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Load'),
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
                          'Draft: ${items.where((e) => e.status == HomeworkStatus.draft).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Published: ${items.where((e) => e.status == HomeworkStatus.published).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Overdue: ${items.where((e) => e.isOverdue).length}',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Due Tomorrow: ${items.where((e) => _sameDay(e.dueDate, tomorrow)).length}',
                        ),
                      ),
                    ],
                  ),
                  if (selectedItems.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${selectedItems.length} selected'),
                            FilledButton.tonal(
                              onPressed: () => context.read<HomeworkBloc>().add(
                                BulkChangeHomeworkStatus(
                                  selectedItems,
                                  HomeworkStatus.published,
                                ),
                              ),
                              child: const Text('Publish'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => context.read<HomeworkBloc>().add(
                                BulkChangeHomeworkStatus(
                                  selectedItems,
                                  HomeworkStatus.archived,
                                ),
                              ),
                              child: const Text('Archive'),
                            ),
                            FilledButton.tonal(
                              onPressed: () => context.read<HomeworkBloc>().add(
                                BulkDeleteHomework(selectedItems),
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No homework found.')),
                      ),
                    )
                  else
                    for (final item in items)
                      Card(
                        child: CheckboxListTile(
                          value: _selected.contains(item.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked ?? false) {
                                _selected.add(item.id);
                              } else {
                                _selected.remove(item.id);
                              }
                            });
                          },
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.className} - ${item.sectionName} • '
                            '${item.subjectName} • ${item.teacherName}\n'
                            'Assigned ${_date(item.assignedDate)} • '
                            'Due ${_date(item.dueDate)} • '
                            '${item.attachments.length} attachment(s)',
                          ),
                          secondary: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'edit':
                                  _open(existing: item);
                                case 'copy':
                                  _open(copyFrom: item);
                                case 'publish':
                                  context.read<HomeworkBloc>().add(
                                    ChangeHomeworkStatus(
                                      item,
                                      HomeworkStatus.published,
                                    ),
                                  );
                                case 'archive':
                                  context.read<HomeworkBloc>().add(
                                    ChangeHomeworkStatus(
                                      item,
                                      HomeworkStatus.archived,
                                    ),
                                  );
                                case 'delete':
                                  context.read<HomeworkBloc>().add(
                                    DeleteHomework(item.id),
                                  );
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy Homework'),
                              ),
                              PopupMenuItem(
                                value: 'publish',
                                child: Text('Publish'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 80),
                ],
              ),
              if (loading) const LinearProgressIndicator(),
            ],
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}
