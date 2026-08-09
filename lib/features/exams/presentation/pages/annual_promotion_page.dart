import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/annual_promotion_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/services/annual_promotion_service.dart';

class AnnualPromotionPage extends StatefulWidget {
  const AnnualPromotionPage({super.key});

  @override
  State<AnnualPromotionPage> createState() => _AnnualPromotionPageState();
}

class _AnnualPromotionPageState extends State<AnnualPromotionPage> {
  final _service = sl<AnnualPromotionService>();
  final _searchController = TextEditingController();
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  List<String> _sessions = const [];
  List<ExamEntity> _exams = const [];
  String? _session;
  String? _examId;
  String? _classFilter;
  AnnualPromotionAction? _actionFilter;
  AnnualPromotionResultStatus? _resultFilter;
  AnnualPromotionPreview? _preview;
  AnnualPromotionExecutionSummary? _summary;
  bool _loading = true;
  bool _executing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _service.sessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _selectSession(String? value) async {
    setState(() {
      _session = value;
      _examId = null;
      _exams = const [];
      _preview = null;
      _summary = null;
      _error = null;
      _loading = value != null;
    });
    if (value == null) return;
    try {
      final exams = await _service.finalExams(value);
      if (mounted) {
        setState(() {
          _exams = exams;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _generatePreview() async {
    if (_session == null || _examId == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _summary = null;
    });
    try {
      final preview = await _service.preview(
        academicSession: _session!,
        finalExamId: _examId!,
      );
      if (mounted) {
        setState(() {
          _preview = preview;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _message(error);
        });
      }
    }
  }

  List<AnnualPromotionPreviewItem> get _visibleItems {
    final preview = _preview;
    if (preview == null) return const [];
    final query = _searchController.text.trim().toLowerCase();
    return preview.items
        .where((item) {
          return (_classFilter == null ||
                  item.previousClassId == _classFilter) &&
              (_actionFilter == null || item.action == _actionFilter) &&
              (_resultFilter == null || item.resultStatus == _resultFilter) &&
              (query.isEmpty ||
                  item.student.fullName.toLowerCase().contains(query) ||
                  item.student.admissionNo.toLowerCase().contains(query));
        })
        .toList(growable: false);
  }

  Future<void> _confirmAndExecute() async {
    final preview = _preview;
    if (preview == null || _executing) return;
    final invalid = preview.items.where(
      (item) =>
          item.action == AnnualPromotionAction.promote &&
          !item.alreadyProcessed &&
          (item.targetClassId == null || item.warning.isNotEmpty),
    );
    if (invalid.isNotEmpty) {
      setState(
        () => _error = 'Resolve all target class/section warnings first.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Annual Promotion'),
        content: Text(
          'Students to Promote: ${_count(AnnualPromotionAction.promote)}\n'
          'Students to Retain: ${_count(AnnualPromotionAction.retain)}\n'
          'Students Completing School: ${_count(AnnualPromotionAction.graduate)}\n'
          'No Action / Incomplete: ${_count(AnnualPromotionAction.noAction)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & Promote'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _executing = true;
      _error = null;
    });
    try {
      final summary = await _service.execute(preview);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _executing = false;
      });
      await _generatePreview();
      if (mounted) setState(() => _summary = summary);
    } catch (error) {
      if (mounted) {
        setState(() {
          _executing = false;
          _error = _message(error);
        });
      }
    }
  }

  int _count(AnnualPromotionAction action) =>
      _preview?.items.where((item) => item.action == action).length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annual Student Promotion'),
        actions: const [DashboardNavigationButton()],
      ),
      body: _loading && _preview == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _verticalController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      _selectionCard(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Card(
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(_error!),
                          ),
                        ),
                      ],
                      if (_summary != null) ...[
                        const SizedBox(height: 12),
                        _completionCard(_summary!),
                      ],
                      if (_preview != null) ...[
                        const SizedBox(height: 16),
                        _summaryCards(),
                        const SizedBox(height: 16),
                        _filters(),
                        const SizedBox(height: 12),
                        _previewTable(),
                        const SizedBox(height: 90),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _preview == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _executing ? null : _confirmAndExecute,
              icon: _executing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.school_outlined),
              label: Text(
                _executing ? 'Processing...' : 'Confirm & Promote Students',
              ),
            ),
    );
  }

  Widget _selectionCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: DropdownButtonFormField<String>(
              initialValue: _session,
              decoration: const InputDecoration(labelText: 'Academic Session'),
              items: _sessions
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: _selectSession,
            ),
          ),
          SizedBox(
            width: 300,
            child: DropdownButtonFormField<String>(
              initialValue: _examId,
              decoration: const InputDecoration(
                labelText: 'Final Exam / Final Result',
              ),
              items: _exams
                  .map(
                    (exam) => DropdownMenuItem(
                      value: exam.id,
                      child: Text(exam.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _examId = value;
                _preview = null;
                _summary = null;
              }),
            ),
          ),
          FilledButton.icon(
            onPressed: _session != null && _examId != null && !_loading
                ? _generatePreview
                : null,
            icon: const Icon(Icons.preview_outlined),
            label: const Text('Generate Promotion Preview'),
          ),
          if (_loading) const CircularProgressIndicator(),
        ],
      ),
    ),
  );

  Widget _summaryCards() {
    final items = _preview!.items;
    int result(AnnualPromotionResultStatus value) =>
        items.where((item) => item.resultStatus == value).length;
    final values = <String, int>{
      'Total Students': items.length,
      'Passed': result(AnnualPromotionResultStatus.passed),
      'Failed': result(AnnualPromotionResultStatus.failed),
      'Incomplete':
          result(AnnualPromotionResultStatus.incomplete) +
          result(AnnualPromotionResultStatus.noResult),
      'To Promote': _count(AnnualPromotionAction.promote),
      'To Retain': _count(AnnualPromotionAction.retain),
      'School Completed': _count(AnnualPromotionAction.graduate),
      'No Action': _count(AnnualPromotionAction.noAction),
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.entries
          .map(
            (entry) => SizedBox(
              width: 175,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.value}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(entry.key),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _filters() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      SizedBox(
        width: 280,
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Student / Admission No.',
          ),
        ),
      ),
      SizedBox(
        width: 210,
        child: DropdownButtonFormField<String?>(
          initialValue: _classFilter,
          decoration: const InputDecoration(labelText: 'Class'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Classes'),
            ),
            ..._preview!.classes.map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.name)),
            ),
          ],
          onChanged: (value) => setState(() => _classFilter = value),
        ),
      ),
      SizedBox(
        width: 210,
        child: DropdownButtonFormField<AnnualPromotionAction?>(
          initialValue: _actionFilter,
          decoration: const InputDecoration(labelText: 'Proposed Action'),
          items: [
            const DropdownMenuItem<AnnualPromotionAction?>(
              value: null,
              child: Text('All Actions'),
            ),
            ...AnnualPromotionAction.values.map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(_actionLabel(item)),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _actionFilter = value),
        ),
      ),
      SizedBox(
        width: 210,
        child: DropdownButtonFormField<AnnualPromotionResultStatus?>(
          initialValue: _resultFilter,
          decoration: const InputDecoration(labelText: 'Result Status'),
          items: [
            const DropdownMenuItem<AnnualPromotionResultStatus?>(
              value: null,
              child: Text('All Results'),
            ),
            ...AnnualPromotionResultStatus.values.map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(_resultLabel(item)),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _resultFilter = value),
        ),
      ),
    ],
  );

  Widget _previewTable() => Card(
    clipBehavior: Clip.antiAlias,
    child: Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Student')),
            DataColumn(label: Text('Father Name')),
            DataColumn(label: Text('Admission No.')),
            DataColumn(label: Text('Current Class / Section')),
            DataColumn(label: Text('Final Result')),
            DataColumn(label: Text('Proposed Action')),
            DataColumn(label: Text('Target Class')),
            DataColumn(label: Text('Target Section')),
            DataColumn(label: Text('Status / Warning')),
          ],
          rows: _visibleItems.map(_row).toList(),
        ),
      ),
    ),
  );

  DataRow _row(AnnualPromotionPreviewItem item) {
    final preview = _preview!;
    final currentClass = _className(item.previousClassId);
    final currentSection = _sectionName(item.previousSectionId);
    final editable =
        !item.alreadyProcessed &&
        (item.resultStatus == AnnualPromotionResultStatus.passed ||
            item.resultStatus == AnnualPromotionResultStatus.failed);
    final actions = <AnnualPromotionAction>[
      AnnualPromotionAction.promote,
      AnnualPromotionAction.retain,
      AnnualPromotionAction.noAction,
      if (item.action == AnnualPromotionAction.graduate)
        AnnualPromotionAction.graduate,
    ];
    return DataRow(
      cells: [
        DataCell(Text(item.student.fullName)),
        DataCell(Text(item.student.fatherName)),
        DataCell(Text(item.student.admissionNo)),
        DataCell(
          Text(
            '$currentClass${currentSection.isEmpty ? '' : ' - $currentSection'}',
          ),
        ),
        DataCell(
          Text(
            '${_resultLabel(item.resultStatus)}${item.result == null ? '' : ' (${item.result!.percentage.toStringAsFixed(1)}%)'}',
          ),
        ),
        DataCell(
          DropdownButton<AnnualPromotionAction>(
            value: item.action,
            items: actions
                .map(
                  (action) => DropdownMenuItem(
                    value: action,
                    child: Text(_actionLabel(action)),
                  ),
                )
                .toList(),
            onChanged: editable ? (value) => _changeAction(item, value!) : null,
          ),
        ),
        DataCell(
          DropdownButton<String>(
            value: item.targetClassId,
            hint: const Text('—'),
            items:
                (item.action == AnnualPromotionAction.promote
                        ? preview.classes.skip(
                            preview.classes.indexWhere(
                                  (value) => value.id == item.previousClassId,
                                ) +
                                1,
                          )
                        : preview.classes.where(
                            (value) => value.id == item.targetClassId,
                          ))
                    .map(
                      (value) => DropdownMenuItem(
                        value: value.id,
                        child: Text(value.name),
                      ),
                    )
                    .toList(),
            onChanged: editable && item.action == AnnualPromotionAction.promote
                ? (value) => _changeTargetClass(item, value!)
                : null,
          ),
        ),
        DataCell(
          DropdownButton<String>(
            value: (item.targetSectionId?.isEmpty ?? true)
                ? null
                : item.targetSectionId,
            hint: const Text('None'),
            items: preview.sections
                .where((section) => section.classId == item.targetClassId)
                .map(
                  (section) => DropdownMenuItem(
                    value: section.id,
                    child: Text(section.name),
                  ),
                )
                .toList(),
            onChanged: editable && item.action == AnnualPromotionAction.promote
                ? (value) => setState(() {
                    item.targetSectionId = value;
                    item.warning = '';
                  })
                : null,
          ),
        ),
        DataCell(
          Text(
            item.warning.isEmpty
                ? (item.alreadyProcessed ? 'Already processed' : 'Ready')
                : item.warning,
          ),
        ),
      ],
    );
  }

  void _changeAction(
    AnnualPromotionPreviewItem item,
    AnnualPromotionAction action,
  ) {
    setState(() {
      item.action = action;
      item.warning = '';
      if (action == AnnualPromotionAction.retain) {
        item.targetClassId = item.previousClassId;
        item.targetSectionId = item.previousSectionId;
      } else if (action == AnnualPromotionAction.noAction) {
        item.targetClassId = null;
        item.targetSectionId = null;
      } else if (action == AnnualPromotionAction.promote) {
        final index = _preview!.classes.indexWhere(
          (value) => value.id == item.previousClassId,
        );
        if (index < 0 || index + 1 >= _preview!.classes.length) {
          item.warning = 'Select a target class.';
          item.targetClassId = null;
        } else {
          _changeTargetClass(
            item,
            _preview!.classes[index + 1].id,
            notify: false,
          );
        }
      }
    });
  }

  void _changeTargetClass(
    AnnualPromotionPreviewItem item,
    String classId, {
    bool notify = true,
  }) {
    void change() {
      item.targetClassId = classId;
      final sections = _preview!.sections
          .where((section) => section.classId == classId)
          .toList();
      item.targetSectionId = sections.length == 1 ? sections.single.id : null;
      item.warning = sections.length > 1 ? 'Select a target section.' : '';
    }

    if (notify) {
      setState(change);
    } else {
      change();
    }
  }

  Widget _completionCard(AnnualPromotionExecutionSummary value) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Annual Promotion Completed',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Promoted: ${value.promoted}   Retained: ${value.retained}   School Completed: ${value.graduated}   Skipped / No Action: ${value.noAction}   Already Processed: ${value.alreadyProcessed}',
          ),
        ],
      ),
    ),
  );

  String _className(String id) =>
      _preview!.classes.where((item) => item.id == id).firstOrNull?.name ?? id;
  String _sectionName(String id) =>
      _preview!.sections.where((item) => item.id == id).firstOrNull?.name ?? '';
  String _message(Object error) =>
      error.toString().replaceFirst('Bad state: ', '');
  String _actionLabel(AnnualPromotionAction value) => switch (value) {
    AnnualPromotionAction.promote => 'Promote',
    AnnualPromotionAction.retain => 'Retain',
    AnnualPromotionAction.graduate => 'School Completed',
    AnnualPromotionAction.noAction => 'No Action',
  };
  String _resultLabel(AnnualPromotionResultStatus value) => switch (value) {
    AnnualPromotionResultStatus.passed => 'PASS',
    AnnualPromotionResultStatus.failed => 'FAIL',
    AnnualPromotionResultStatus.incomplete => 'INCOMPLETE',
    AnnualPromotionResultStatus.noResult => 'NO FINAL RESULT',
  };
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
