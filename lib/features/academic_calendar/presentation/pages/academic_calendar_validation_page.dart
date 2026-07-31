import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/academic_calendar_conflict_entity.dart';
import '../bloc/academic_calendar_validation_bloc.dart';

class AcademicCalendarValidationPage extends StatelessWidget {
  const AcademicCalendarValidationPage({
    super.key,
    this.academicSession = '2026-2027',
  });

  final String academicSession;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AcademicCalendarValidationBloc>(
      create: (_) =>
          sl<AcademicCalendarValidationBloc>()
            ..add(RunAcademicCalendarValidation(academicSession)),
      child: _ValidationView(initialSession: academicSession),
    );
  }
}

class _ValidationView extends StatefulWidget {
  const _ValidationView({required this.initialSession});

  final String initialSession;

  @override
  State<_ValidationView> createState() => _ValidationViewState();
}

class _ValidationViewState extends State<_ValidationView> {
  late final TextEditingController _sessionController;
  AcademicCalendarConflictSeverity? _severityFilter;
  AcademicCalendarConflictModule? _moduleFilter;

  @override
  void initState() {
    super.initState();
    _sessionController = TextEditingController(text: widget.initialSession);
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  void _run() {
    context.read<AcademicCalendarValidationBloc>().add(
      RunAcademicCalendarValidation(_sessionController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Validation'),
        actions: [
          IconButton(
            tooltip: 'Run Validation',
            onPressed: _run,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child:
            BlocBuilder<
              AcademicCalendarValidationBloc,
              AcademicCalendarValidationState
            >(
              builder: (context, state) {
                if (state is AcademicCalendarValidationLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AcademicCalendarValidationError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(state.message),
                    ),
                  );
                }

                final result = state is AcademicCalendarValidationLoaded
                    ? state.result
                    : null;

                if (result == null) {
                  return const Center(
                    child: Text('Run validation to check the calendar.'),
                  );
                }

                final visible = result.conflicts.where((item) {
                  return (_severityFilter == null ||
                          item.severity == _severityFilter) &&
                      (_moduleFilter == null || item.module == _moduleFilter);
                }).toList();

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _filters(),
                    const SizedBox(height: 14),
                    _summary(result),
                    const SizedBox(height: 14),
                    if (visible.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Row(
                            children: [
                              Icon(Icons.verified_outlined),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No conflicts match the selected filters.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final conflict in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _conflictCard(conflict),
                        ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Widget _filters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
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
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<AcademicCalendarConflictSeverity?>(
                initialValue: _severityFilter,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Severities'),
                  ),
                  ...AcademicCalendarConflictSeverity.values.map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_severityLabel(item)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _severityFilter = value),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<AcademicCalendarConflictModule?>(
                initialValue: _moduleFilter,
                decoration: const InputDecoration(
                  labelText: 'Module',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Modules'),
                  ),
                  ...AcademicCalendarConflictModule.values.map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(_moduleLabel(item)),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _moduleFilter = value),
              ),
            ),
            FilledButton.icon(
              onPressed: _run,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Run Validation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(AcademicCalendarValidationResult result) {
    final score = result.healthScore;
    final color = score >= 85
        ? const Color(0xFF2E7D32)
        : score >= 65
        ? const Color(0xFFEF6C00)
        : const Color(0xFFC62828);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: color.withAlpha(30),
              child: Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            Text(
              'Calendar Health Score',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Chip(label: Text('Checks: ${result.totalChecks}')),
            Chip(label: Text('Errors: ${result.errorCount}')),
            Chip(label: Text('Warnings: ${result.warningCount}')),
            Chip(label: Text('Info: ${result.infoCount}')),
          ],
        ),
      ),
    );
  }

  Widget _conflictCard(AcademicCalendarConflictEntity conflict) {
    final color = _severityColor(conflict.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(28),
              child: Icon(_severityIcon(conflict.severity), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Text(
                        conflict.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Chip(
                        label: Text(_severityLabel(conflict.severity)),
                        backgroundColor: color.withAlpha(24),
                      ),
                      Chip(label: Text(_moduleLabel(conflict.module))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(conflict.description),
                  const SizedBox(height: 8),
                  Text(
                    'Suggested fix: ${conflict.suggestedResolution}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (conflict.affectedDate != null) ...[
                    const SizedBox(height: 5),
                    Text('Affected date: ${_date(conflict.affectedDate!)}'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _severityColor(AcademicCalendarConflictSeverity severity) =>
      switch (severity) {
        AcademicCalendarConflictSeverity.error => const Color(0xFFC62828),
        AcademicCalendarConflictSeverity.warning => const Color(0xFFEF6C00),
        AcademicCalendarConflictSeverity.info => const Color(0xFF1565C0),
      };

  static IconData _severityIcon(AcademicCalendarConflictSeverity severity) =>
      switch (severity) {
        AcademicCalendarConflictSeverity.error => Icons.error_outline,
        AcademicCalendarConflictSeverity.warning =>
          Icons.warning_amber_outlined,
        AcademicCalendarConflictSeverity.info => Icons.info_outline,
      };

  static String _severityLabel(AcademicCalendarConflictSeverity severity) =>
      switch (severity) {
        AcademicCalendarConflictSeverity.error => 'Error',
        AcademicCalendarConflictSeverity.warning => 'Warning',
        AcademicCalendarConflictSeverity.info => 'Info',
      };

  static String _moduleLabel(AcademicCalendarConflictModule module) =>
      switch (module) {
        AcademicCalendarConflictModule.calendar => 'Calendar',
        AcademicCalendarConflictModule.exams => 'Exams',
        AcademicCalendarConflictModule.timetable => 'Timetable',
        AcademicCalendarConflictModule.homework => 'Homework',
        AcademicCalendarConflictModule.fees => 'Fees',
        AcademicCalendarConflictModule.notices => 'Notices',
      };

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}
