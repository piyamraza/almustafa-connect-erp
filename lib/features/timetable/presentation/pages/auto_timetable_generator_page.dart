import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/auto_timetable_generation_entity.dart';
import '../bloc/auto_timetable_bloc.dart';

class AutoTimetableGeneratorPage extends StatelessWidget {
  const AutoTimetableGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AutoTimetableBloc>(
      create: (_) => sl<AutoTimetableBloc>(),
      child: const _AutoTimetableGeneratorView(),
    );
  }
}

class _AutoTimetableGeneratorView extends StatefulWidget {
  const _AutoTimetableGeneratorView();

  @override
  State<_AutoTimetableGeneratorView> createState() =>
      _AutoTimetableGeneratorViewState();
}

class _AutoTimetableGeneratorViewState
    extends State<_AutoTimetableGeneratorView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');
  bool _replaceExisting = false;

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  void _preview() {
    context.read<AutoTimetableBloc>().add(
      PreviewAutoTimetable(
        AutoTimetableGenerationRequest(
          branchId: _branchController.text.trim(),
          academicSession: _sessionController.text.trim(),
          replaceExisting: _replaceExisting,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Save generated timetable?'),
            content: Text(
              _replaceExisting
                  ? 'All existing timetable entries for this session will be '
                        'deleted and replaced by the generated timetable.'
                  : 'Generated entries will be added only to currently empty '
                        'slots. Existing manual entries will remain unchanged.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Save Timetable'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      context.read<AutoTimetableBloc>().add(const SaveAutoTimetable());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Auto Timetable Generator'),
      ),
      body: SafeArea(
        child: BlocConsumer<AutoTimetableBloc, AutoTimetableState>(
          listener: (context, state) {
            if (state is AutoTimetableError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.message)));
            } else if (state is AutoTimetableSaved) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.result.generatedCount} timetable periods saved.',
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            final busy = state is AutoTimetableLoading;
            final compact = MediaQuery.sizeOf(context).width < 700;
            final result = switch (state) {
              AutoTimetablePreviewReady(:final result) => result,
              AutoTimetableSaved(:final result) => result,
              _ => null,
            };

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 12 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!compact) ...[
                            Text(
                              'Auto Timetable Generator',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generate a conflict-free timetable from active '
                              'classes, subjects and teacher assignments.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 22),
                          ],
                          Card(
                            child: Padding(
                              padding: EdgeInsets.all(compact ? 10 : 18),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: compact ? 150 : 180,
                                      child: TextFormField(
                                        controller: _branchController,
                                        decoration: const InputDecoration(
                                          labelText: 'Branch ID',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: compact ? 165 : 190,
                                      child: TextFormField(
                                        controller: _sessionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Academic Session',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: compact ? 285 : 360,
                                      child: SwitchListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: const Text(
                                          'Replace existing timetable',
                                        ),
                                        subtitle: const Text(
                                          'Keep off to preserve manual entries.',
                                        ),
                                        value: _replaceExisting,
                                        onChanged: busy
                                            ? null
                                            : (value) => setState(
                                                () => _replaceExisting = value,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    FilledButton.icon(
                                      onPressed: busy ? null : _preview,
                                      icon: const Icon(Icons.auto_awesome),
                                      label: const Text('Generate Preview'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (result == null)
                            const _InfoCard(
                              icon: Icons.info_outline,
                              text:
                                  'Preview generation does not change Firestore. '
                                  'Review the result before saving.',
                            )
                          else ...[
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: [
                                _SummaryCard(
                                  label: 'Generated',
                                  value: '${result.generatedCount}',
                                  icon: Icons.auto_awesome,
                                ),
                                _SummaryCard(
                                  label: 'Class / Sections',
                                  value: '${result.totalClassSections}',
                                  icon: Icons.school_outlined,
                                ),
                                _SummaryCard(
                                  label: 'Available Slots',
                                  value: '${result.totalAvailableSlots}',
                                  icon: Icons.grid_view_outlined,
                                ),
                                _SummaryCard(
                                  label: 'Preserved',
                                  value: '${result.preservedEntries}',
                                  icon: Icons.lock_outline,
                                ),
                                _SummaryCard(
                                  label: 'Warnings',
                                  value: '${result.warningCount}',
                                  icon: Icons.warning_amber_outlined,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Generation Summary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '${result.generatedCount} conflict-free '
                                      'periods are ready to save.',
                                    ),
                                    if (result.warnings.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        'Warnings',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 260,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          itemCount: result.warnings.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) =>
                                              ListTile(
                                                dense: true,
                                                leading: const Icon(
                                                  Icons.warning_amber_outlined,
                                                ),
                                                title: Text(
                                                  result.warnings[index],
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 18),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FilledButton.icon(
                                        onPressed:
                                            busy ||
                                                result.generatedEntries.isEmpty
                                            ? null
                                            : _save,
                                        icon: const Icon(Icons.save_outlined),
                                        label: const Text(
                                          'Save Generated Timetable',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    return SizedBox(
      width: 210,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
