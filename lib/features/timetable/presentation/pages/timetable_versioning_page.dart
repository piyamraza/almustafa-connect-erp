import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/timetable_version_entity.dart';
import '../bloc/timetable_version_bloc.dart';

class TimetableVersioningPage extends StatelessWidget {
  const TimetableVersioningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimetableVersionBloc>(
      create: (_) => sl<TimetableVersionBloc>(),
      child: const _TimetableVersioningView(),
    );
  }
}

class _TimetableVersioningView extends StatefulWidget {
  const _TimetableVersioningView();

  @override
  State<_TimetableVersioningView> createState() =>
      _TimetableVersioningViewState();
}

class _TimetableVersioningViewState extends State<_TimetableVersioningView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<TimetableVersionBloc>().add(
      LoadTimetableVersions(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
      ),
    );
  }

  Future<void> _createDraft() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Draft Version'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Version Name',
            hintText: 'e.g. Revised September Timetable',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create Snapshot'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (!mounted || name == null) return;

    context.read<TimetableVersionBloc>().add(
      CreateTimetableDraft(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        name: name,
      ),
    );
  }

  Future<bool> _confirm(String title, String message) async {
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
                child: const Text('Confirm'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timetable Versioning')),
      body: SafeArea(
        child: BlocConsumer<TimetableVersionBloc, TimetableVersionState>(
          listener: (context, state) {
            if (state is TimetableVersionLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is TimetableVersionError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = state is TimetableVersionLoading;
            final versions = state is TimetableVersionLoaded
                ? state.versions
                : const <TimetableVersionEntity>[];

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1350),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Timetable Versioning',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create snapshots, publish approved versions and '
                            'restore previous timetables safely.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 22),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: TextFormField(
                                      controller: _branchController,
                                      decoration: const InputDecoration(
                                        labelText: 'Branch ID',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 190,
                                    child: TextFormField(
                                      controller: _sessionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Academic Session',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: busy ? null : _load,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Load Versions'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: busy ? null : _createDraft,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Draft Snapshot'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (versions.isEmpty && !busy)
                            const _MessageCard(
                              text:
                                  'No timetable versions exist for this session.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 1100
                                    ? 3
                                    : constraints.maxWidth >= 700
                                    ? 2
                                    : 1;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: versions.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: columns == 1
                                            ? 1.85
                                            : 1.35,
                                      ),
                                  itemBuilder: (context, index) => _VersionCard(
                                    version: versions[index],
                                    onPublish: () async {
                                      if (await _confirm(
                                        'Publish Version',
                                        'This version will become the '
                                            'current published timetable. '
                                            'Any existing published version '
                                            'will be archived.',
                                      )) {
                                        if (!context.mounted) return;
                                        context
                                            .read<TimetableVersionBloc>()
                                            .add(
                                              PublishTimetableVersion(
                                                versions[index],
                                              ),
                                            );
                                      }
                                    },
                                    onArchive: () async {
                                      if (await _confirm(
                                        'Archive Version',
                                        'Archive this timetable version?',
                                      )) {
                                        if (!context.mounted) return;
                                        context
                                            .read<TimetableVersionBloc>()
                                            .add(
                                              ArchiveTimetableVersion(
                                                versions[index],
                                              ),
                                            );
                                      }
                                    },
                                    onRollback: () async {
                                      if (await _confirm(
                                        'Restore Version',
                                        'The live timetable entries will '
                                            'be replaced with this snapshot.',
                                      )) {
                                        if (!context.mounted) return;
                                        context
                                            .read<TimetableVersionBloc>()
                                            .add(
                                              RollbackTimetableVersion(
                                                versions[index],
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                );
                              },
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
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.onPublish,
    required this.onArchive,
    required this.onRollback,
  });

  final TimetableVersionEntity version;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onRollback;

  @override
  Widget build(BuildContext context) {
    final color = switch (version.status) {
      TimetableVersionStatus.draft => const Color(0xFF039BE5),
      TimetableVersionStatus.published => const Color(0xFF00897B),
      TimetableVersionStatus.archived => const Color(0xFF546E7A),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withAlpha(25),
                  child: Text(
                    'V${version.versionNumber}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(version.status.name.toUpperCase()),
                  backgroundColor: color.withAlpha(25),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              version.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('${version.entryCount} timetable entries'),
            Text('Created: ${_date(version.createdAt)}'),
            if (version.publishedAt != null)
              Text('Published: ${_date(version.publishedAt!)}'),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (version.status != TimetableVersionStatus.published)
                  FilledButton.tonalIcon(
                    onPressed: onPublish,
                    icon: const Icon(Icons.publish, size: 18),
                    label: const Text('Publish'),
                  ),
                OutlinedButton.icon(
                  onPressed: onRollback,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('Restore'),
                ),
                if (version.status != TimetableVersionStatus.archived)
                  TextButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined, size: 18),
                    label: const Text('Archive'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
