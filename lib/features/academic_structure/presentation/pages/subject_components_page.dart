import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/academic_subject_entity.dart';
import '../../domain/entities/subject_component_entity.dart';
import '../bloc/subject_component_bloc.dart';

class SubjectComponentsPage extends StatelessWidget {
  const SubjectComponentsPage({super.key, required this.subject});

  final AcademicSubjectEntity subject;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SubjectComponentBloc>()
        ..add(LoadSubjectComponents(subject)),
      child: const _SubjectComponentsView(),
    );
  }
}

class _SubjectComponentsView extends StatelessWidget {
  const _SubjectComponentsView();

  Future<void> _edit(
    BuildContext context, [
    SubjectComponentEntity? item,
  ]) async {
    final controller = TextEditingController(text: item?.componentName ?? '');
    var active = item?.isActive ?? true;

    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item == null ? 'Add Component' : 'Edit Component'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Component name',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
                value: active,
                onChanged: (value) => setState(() => active = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                (controller.text, active),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (result != null && context.mounted) {
      context.read<SubjectComponentBloc>().add(
            SaveSubjectComponent(
              existing: item,
              name: result.$1,
              isActive: result.$2,
            ),
          );
    }
  }

  Future<void> _delete(
    BuildContext context,
    SubjectComponentEntity item,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Component'),
            content: Text('Delete ${item.componentName}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      context
          .read<SubjectComponentBloc>()
          .add(DeleteSubjectComponent(item));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subject Components'),
        actions: const [DashboardNavigationButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Component'),
      ),
      body: BlocConsumer<SubjectComponentBloc, SubjectComponentState>(
        listener: (context, state) {
          if (state is SubjectComponentLoaded && state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          if (state is SubjectComponentLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SubjectComponentFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as SubjectComponentLoaded;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('Parent Subject'),
                  subtitle: Text(
                    data.subject.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _setting(
                        context,
                        data,
                        'Timetable',
                        data.subject.useComponentsInTimetable,
                        (value) => data.subject.copyWith(
                          useComponentsInTimetable: value,
                        ),
                      ),
                      _setting(
                        context,
                        data,
                        'Attendance',
                        data.subject.useComponentsInAttendance,
                        (value) => data.subject.copyWith(
                          useComponentsInAttendance: value,
                        ),
                      ),
                      _setting(
                        context,
                        data,
                        'Homework',
                        data.subject.useComponentsInHomework,
                        (value) => data.subject.copyWith(
                          useComponentsInHomework: value,
                        ),
                      ),
                      _setting(
                        context,
                        data,
                        'Examination',
                        data.subject.useComponentsInExamination,
                        (value) => data.subject.copyWith(
                          useComponentsInExamination: value,
                        ),
                      ),
                      _setting(
                        context,
                        data,
                        'Report Card',
                        data.subject.useComponentsInReportCard,
                        (value) => data.subject.copyWith(
                          useComponentsInReportCard: value,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Components',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.components.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No components. This subject behaves exactly as before.',
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.components.length,
                  onReorder: data.busy
                      ? (_, _) {}
                      : (oldIndex, newIndex) => context
                          .read<SubjectComponentBloc>()
                          .add(ReorderSubjectComponents(oldIndex, newIndex)),
                  itemBuilder: (context, index) {
                    final item = data.components[index];
                    return Card(
                      key: ValueKey(item.id),
                      child: ListTile(
                        leading: const Icon(Icons.drag_handle),
                        title: Text(item.componentName),
                        subtitle: Text(item.isActive ? 'Enabled' : 'Disabled'),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: item.isActive ? 'Disable' : 'Enable',
                              onPressed: data.busy
                                  ? null
                                  : () => context
                                      .read<SubjectComponentBloc>()
                                      .add(
                                        SaveSubjectComponent(
                                          existing: item,
                                          name: item.componentName,
                                          isActive: !item.isActive,
                                        ),
                                      ),
                              icon: Icon(
                                item.isActive
                                    ? Icons.toggle_on
                                    : Icons.toggle_off,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit',
                              onPressed:
                                  data.busy ? null : () => _edit(context, item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              onPressed: data.busy
                                  ? null
                                  : () => _delete(context, item),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _setting(
    BuildContext context,
    SubjectComponentLoaded data,
    String title,
    bool value,
    AcademicSubjectEntity Function(bool) change,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: data.busy
          ? null
          : (enabled) => context.read<SubjectComponentBloc>().add(
                SaveSubjectComponentSettings(
                  change(enabled).copyWith(updatedAt: DateTime.now()),
                ),
              ),
    );
  }
}
