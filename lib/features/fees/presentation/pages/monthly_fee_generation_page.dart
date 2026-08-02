import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_calendar/domain/services/academic_calendar_policy_service.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/entities/monthly_fee_generation_entity.dart';
import '../../domain/entities/student_fee_assignment_entity.dart';
import '../../domain/repositories/student_fee_assignment_repository.dart';
import '../bloc/monthly_fee_generation_bloc.dart';

class MonthlyFeeGenerationPage extends StatelessWidget {
  const MonthlyFeeGenerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider<MonthlyFeeGenerationBloc>(
      create: (_) => sl<MonthlyFeeGenerationBloc>()
        ..add(
          LoadMonthlyFeeGenerationData(
            academicSession: '2026-2027',
            month: now.month,
            year: now.year,
          ),
        ),
      child: const _MonthlyFeeGenerationView(),
    );
  }
}

class _MonthlyFeeGenerationView extends StatefulWidget {
  const _MonthlyFeeGenerationView();

  @override
  State<_MonthlyFeeGenerationView> createState() =>
      _MonthlyFeeGenerationViewState();
}

class _MonthlyFeeGenerationViewState extends State<_MonthlyFeeGenerationView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  final _dueDayController = TextEditingController(text: '10');
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  FeeGenerationScope _scope = FeeGenerationScope.entireSchool;
  List<StudentFeeAssignmentEntity> _assignments = const [];
  bool _loadingAssignments = true;
  String? _classId;
  String? _sectionId;
  final Set<String> _selectedAssignmentIds = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarFeeDefaults();
    _loadAssignments();
  }

  Future<void> _loadCalendarFeeDefaults() async {
    try {
      final service = sl<AcademicCalendarPolicyService>();
      final config = await service.getConfig(_sessionController.text.trim());
      if (!mounted || config == null) return;
      setState(() {
        _dueDayController.text = '${config.feeDueDay}';
      });
    } catch (_) {
      // Keep the existing default when Academic Year Wizard is not ready.
    }
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Future<void> _loadAssignments() async {
    setState(() => _loadingAssignments = true);
    try {
      final values = await sl<StudentFeeAssignmentRepository>().getAssignments(
        academicSession: _sessionController.text.trim(),
        isActive: true,
      );
      if (!mounted) return;
      setState(() {
        _assignments = values;
        _classId = _classOptions.isEmpty ? null : _classOptions.first.id;
        _sectionId = _sectionOptions.isEmpty ? null : _sectionOptions.first.id;
        _selectedAssignmentIds.clear();
        _loadingAssignments = false;
      });
      _loadDues();
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingAssignments = false);
      _show(error.toString().replaceFirst('StateError: ', ''));
    }
  }

  List<_IdLabel> get _classOptions {
    final map = <String, String>{};
    for (final assignment in _assignments) {
      final label = assignment.feeStructureLabel.split(' - ').first.trim();
      map[assignment.classId] = label;
    }
    final values =
        map.entries.map((entry) => _IdLabel(entry.key, entry.value)).toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return values;
  }

  List<_IdLabel> get _sectionOptions {
    final map = <String, String>{};
    for (final assignment in _assignments.where(
      (item) => item.classId == _classId,
    )) {
      final parts = assignment.feeStructureLabel.split(' - ');
      final label = parts.length > 1
          ? parts.last.trim()
          : itemLabel(assignment);
      map[assignment.sectionId] = label;
    }
    final values =
        map.entries.map((entry) => _IdLabel(entry.key, entry.value)).toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return values;
  }

  String itemLabel(StudentFeeAssignmentEntity assignment) =>
      assignment.sectionId;

  List<StudentFeeAssignmentEntity> get _scopeAssignments {
    return switch (_scope) {
      FeeGenerationScope.entireSchool => _assignments,
      FeeGenerationScope.classWise =>
        _assignments.where((item) => item.classId == _classId).toList(),
      FeeGenerationScope.sectionWise =>
        _assignments
            .where(
              (item) =>
                  item.classId == _classId && item.sectionId == _sectionId,
            )
            .toList(),
      FeeGenerationScope.selectedStudents => _assignments,
    };
  }

  void _loadDues() {
    context.read<MonthlyFeeGenerationBloc>().add(
      LoadMonthlyFeeGenerationData(
        academicSession: _sessionController.text.trim(),
        month: _month,
        year: _year,
      ),
    );
  }

  Future<void> _generate() async {
    final day = int.tryParse(_dueDayController.text.trim());
    if (day == null || day < 1 || day > 28) {
      _show('Due day must be between 1 and 28.');
      return;
    }
    if (_scope == FeeGenerationScope.selectedStudents &&
        _selectedAssignmentIds.isEmpty) {
      _show('Select at least one student.');
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Generate Monthly Fees'),
            content: Text(
              'Generate fee dues for ${_monthName(_month)} $_year?\n'
              'Existing student-month dues will be skipped.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Generate'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    context.read<MonthlyFeeGenerationBloc>().add(
      GenerateMonthlyFeeDues(
        MonthlyFeeGenerationRequest(
          academicSession: _sessionController.text.trim(),
          month: _month,
          year: _year,
          dueDay: day,
          scope: _scope,
          classId: _classId,
          sectionId: _sectionId,
          selectedAssignmentIds: _selectedAssignmentIds.toList(),
        ),
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Monthly Fee Generation')),
      body: SafeArea(
        child:
            BlocConsumer<MonthlyFeeGenerationBloc, MonthlyFeeGenerationState>(
              listener: (context, state) {
                if (state is MonthlyFeeGenerationLoaded &&
                    state.message != null) {
                  _show(state.message!);
                } else if (state is MonthlyFeeGenerationError) {
                  _show(state.message);
                }
              },
              builder: (context, state) {
                final busy =
                    _loadingAssignments || state is MonthlyFeeGenerationLoading;
                final dues = state is MonthlyFeeGenerationLoaded
                    ? state.dues
                    : const <MonthlyFeeDueEntity>[];
                final result = state is MonthlyFeeGenerationLoaded
                    ? state.result
                    : null;

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1450),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Monthly Fee Generation',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Generate monthly dues with discounts, arrears '
                                'and duplicate protection.',
                              ),
                              const SizedBox(height: 18),
                              _configurationCard(busy),
                              if (_scope ==
                                  FeeGenerationScope.selectedStudents) ...[
                                const SizedBox(height: 14),
                                _studentSelectionCard(busy),
                              ],
                              if (result != null) ...[
                                const SizedBox(height: 14),
                                _summaryCard(result),
                              ],
                              const SizedBox(height: 16),
                              _duesTable(dues, busy),
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

  Widget _configurationCard(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
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
              width: 170,
              child: DropdownButtonFormField<int>(
                initialValue: _month,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(_monthName(month)),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _month = value);
                          _loadDues();
                        }
                      },
              ),
            ),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<int>(
                initialValue: _year,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (
                    var year = DateTime.now().year - 1;
                    year <= DateTime.now().year + 2;
                    year++
                  )
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _year = value);
                          _loadDues();
                        }
                      },
              ),
            ),
            SizedBox(
              width: 140,
              child: TextFormField(
                controller: _dueDayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Due Day',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<FeeGenerationScope>(
                initialValue: _scope,
                decoration: const InputDecoration(
                  labelText: 'Generation Scope',
                  border: OutlineInputBorder(),
                ),
                items: FeeGenerationScope.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(_scopeLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _scope = value);
                        }
                      },
              ),
            ),
            if (_scope == FeeGenerationScope.classWise ||
                _scope == FeeGenerationScope.sectionWise)
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _classId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    border: OutlineInputBorder(),
                  ),
                  items: _classOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) {
                          setState(() {
                            _classId = value;
                            _sectionId = _sectionOptions.isEmpty
                                ? null
                                : _sectionOptions.first.id;
                          });
                        },
                ),
              ),
            if (_scope == FeeGenerationScope.sectionWise)
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _sectionId,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                  ),
                  items: _sectionOptions
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _sectionId = value),
                ),
              ),
            OutlinedButton.icon(
              onPressed: busy ? null : _loadAssignments,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
            FilledButton.icon(
              onPressed: busy ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text('Generate (${_scopeAssignments.length})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentSelectionCard(bool busy) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Select Students',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: busy
                      ? null
                      : () {
                          setState(() {
                            if (_selectedAssignmentIds.length ==
                                _assignments.length) {
                              _selectedAssignmentIds.clear();
                            } else {
                              _selectedAssignmentIds
                                ..clear()
                                ..addAll(_assignments.map((item) => item.id));
                            }
                          });
                        },
                  child: const Text('Select / Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _assignments.length,
                itemBuilder: (context, index) {
                  final assignment = _assignments[index];
                  return CheckboxListTile(
                    dense: true,
                    value: _selectedAssignmentIds.contains(assignment.id),
                    title: Text(assignment.studentName),
                    subtitle: Text(
                      '${assignment.admissionNo} • '
                      'Rs. ${assignment.monthlyPayable.toStringAsFixed(0)}',
                    ),
                    onChanged: busy
                        ? null
                        : (selected) {
                            setState(() {
                              selected == true
                                  ? _selectedAssignmentIds.add(assignment.id)
                                  : _selectedAssignmentIds.remove(
                                      assignment.id,
                                    );
                            });
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

  Widget _summaryCard(MonthlyFeeGenerationResult result) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _metric('Generated', '${result.generatedCount}'),
            _metric('Skipped', '${result.skippedCount}'),
            _metric('Gross', 'Rs. ${result.totalGross.toStringAsFixed(0)}'),
            _metric(
              'Discounts',
              'Rs. ${result.totalDiscounts.toStringAsFixed(0)}',
            ),
            _metric('Arrears', 'Rs. ${result.totalArrears.toStringAsFixed(0)}'),
            _metric(
              'Net Receivable',
              'Rs. ${result.netReceivable.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Chip(
      avatar: const Icon(Icons.analytics_outlined, size: 18),
      label: Text('$label: $value'),
    );
  }

  Widget _duesTable(List<MonthlyFeeDueEntity> dues, bool busy) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${_monthName(_month)} $_year Dues (${dues.length})',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          if (dues.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No dues generated for this month.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Student')),
                  DataColumn(label: Text('Admission No.')),
                  DataColumn(label: Text('Tuition')),
                  DataColumn(label: Text('Transport')),
                  DataColumn(label: Text('Discounts')),
                  DataColumn(label: Text('Arrears')),
                  DataColumn(label: Text('Net Payable')),
                  DataColumn(label: Text('Due Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final due in dues)
                    DataRow(
                      color: WidgetStatePropertyAll(_dueRowColor(due)),
                      cells: [
                        DataCell(Text(due.studentName)),
                        DataCell(Text(due.admissionNo)),
                        DataCell(
                          Text('Rs. ${due.tuitionFee.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${due.transportFee.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${due.totalDeductions.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${due.previousArrears.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${due.netPayable.toStringAsFixed(0)}'),
                        ),
                        DataCell(Text(_date(due.dueDate))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _dueStatusColor(
                                due,
                              ).withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _dueStatusColor(
                                  due,
                                ).withValues(alpha: .35),
                              ),
                            ),
                            child: Text(
                              due.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _dueStatusColor(due),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          IconButton(
                            tooltip: 'Delete generated due',
                            onPressed: busy || due.paidAmount > 0
                                ? null
                                : () => context
                                      .read<MonthlyFeeGenerationBloc>()
                                      .add(
                                        DeleteGeneratedMonthlyDue(
                                          id: due.id,
                                          academicSession: _sessionController
                                              .text
                                              .trim(),
                                          month: _month,
                                          year: _year,
                                        ),
                                      ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _dueRowColor(MonthlyFeeDueEntity due) {
    if (due.status == MonthlyFeeDueStatus.paid) {
      return const Color(0xFFE8F7EE);
    }

    if (due.status == MonthlyFeeDueStatus.cancelled) {
      return const Color(0xFFF1F3F5);
    }

    if (due.paidAmount > 0) {
      return const Color(0xFFFFF5DB);
    }

    return const Color(0xFFFFECEC);
  }

  Color _dueStatusColor(MonthlyFeeDueEntity due) {
    if (due.status == MonthlyFeeDueStatus.paid) {
      return const Color(0xFF15803D);
    }

    if (due.status == MonthlyFeeDueStatus.cancelled) {
      return const Color(0xFF64748B);
    }

    if (due.paidAmount > 0) {
      return const Color(0xFFB45309);
    }

    return const Color(0xFFDC2626);
  }

  static String _scopeLabel(FeeGenerationScope scope) => switch (scope) {
    FeeGenerationScope.entireSchool => 'Entire School',
    FeeGenerationScope.classWise => 'Class Wise',
    FeeGenerationScope.sectionWise => 'Section Wise',
    FeeGenerationScope.selectedStudents => 'Selected Students',
  };

  static String _monthName(int month) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}';
}

class _IdLabel {
  const _IdLabel(this.id, this.label);

  final String id;
  final String label;
}
