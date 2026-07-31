import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/fee_structure_entity.dart';
import '../../domain/entities/student_fee_assignment_entity.dart';
import '../../domain/repositories/fee_structure_repository.dart';
import '../../domain/repositories/student_fee_assignment_repository.dart';
import '../bloc/student_fee_assignment_bloc.dart';

class StudentFeeAssignmentPage extends StatelessWidget {
  const StudentFeeAssignmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StudentFeeAssignmentBloc>(
      create: (_) => sl<StudentFeeAssignmentBloc>()
        ..add(const LoadStudentFeeAssignments(academicSession: '2026-2027')),
      child: const _StudentFeeAssignmentView(),
    );
  }
}

class _StudentFeeAssignmentView extends StatefulWidget {
  const _StudentFeeAssignmentView();

  @override
  State<_StudentFeeAssignmentView> createState() =>
      _StudentFeeAssignmentViewState();
}

class _StudentFeeAssignmentViewState extends State<_StudentFeeAssignmentView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  final _searchController = TextEditingController();
  List<StudentEntity> _students = const [];
  List<FeeStructureEntity> _structures = const [];
  bool _loadingReferences = true;
  String? _referenceError;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingReferences = true;
      _referenceError = null;
    });

    try {
      final values = await Future.wait<Object?>([
        sl<StudentRepository>().getStudents(),
        sl<FeeStructureRepository>().getFeeStructures(
          academicSession: _sessionController.text.trim(),
          isActive: true,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _students =
            (values[0] as List<StudentEntity>)
                .where((item) => item.isActive)
                .toList()
              ..sort((a, b) => a.fullName.compareTo(b.fullName));
        _structures = values[1] as List<FeeStructureEntity>;
        _loadingReferences = false;
      });

      context.read<StudentFeeAssignmentBloc>().add(
        LoadStudentFeeAssignments(
          academicSession: _sessionController.text.trim(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReferences = false;
        _referenceError = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  Future<void> _edit({
    required StudentEntity student,
    StudentFeeAssignmentEntity? existing,
  }) async {
    final matching = _structures
        .where(
          (item) =>
              item.classId == student.classId &&
              item.sectionId == student.sectionId,
        )
        .toList();

    if (matching.isEmpty) {
      _show(
        'No active fee structure exists for this student class and section.',
      );
      return;
    }

    final result = await showDialog<StudentFeeAssignmentEntity>(
      context: context,
      builder: (_) => _AssignmentDialog(
        student: student,
        academicSession: _sessionController.text.trim(),
        structures: matching,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    context.read<StudentFeeAssignmentBloc>().add(
      SaveStudentFeeAssignment(result),
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
      appBar: AppBar(title: const Text('Student Fee Assignment')),
      body: SafeArea(
        child: BlocConsumer<StudentFeeAssignmentBloc, StudentFeeAssignmentState>(
          listener: (context, state) {
            if (state is StudentFeeAssignmentLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is StudentFeeAssignmentError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy =
                _loadingReferences || state is StudentFeeAssignmentLoading;
            final assignments = state is StudentFeeAssignmentLoaded
                ? state.assignments
                : const <StudentFeeAssignmentEntity>[];
            final byStudent = {
              for (final item in assignments) item.studentId: item,
            };
            final visibleStudents = _students.where((student) {
              final query = _query.trim().toLowerCase();
              if (query.isEmpty) return true;
              return student.fullName.toLowerCase().contains(query) ||
                  student.admissionNo.toLowerCase().contains(query) ||
                  student.rollNumber.toLowerCase().contains(query);
            }).toList();

            return Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
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
                              FilledButton.icon(
                                onPressed: busy ? null : _loadReferences,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Load'),
                              ),
                              SizedBox(
                                width: 310,
                                child: TextFormField(
                                  controller: _searchController,
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                  decoration: const InputDecoration(
                                    labelText: 'Search student / admission no.',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              Chip(
                                avatar: const Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 18,
                                ),
                                label: Text('${assignments.length} assigned'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _referenceError != null
                          ? Center(child: Text(_referenceError!))
                          : visibleStudents.isEmpty
                          ? const Center(child: Text('No students found.'))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: visibleStudents.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final student = visibleStudents[index];
                                final assignment = byStudent[student.id];

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        student.fullName
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(student.fullName),
                                    subtitle: Text(
                                      '${student.admissionNo} • '
                                      'Roll ${student.rollNumber}',
                                    ),
                                    trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        if (assignment == null)
                                          const Chip(
                                            label: Text('NOT ASSIGNED'),
                                          )
                                        else ...[
                                          Chip(
                                            label: Text(
                                              'Rs. ${assignment.monthlyPayable.toStringAsFixed(0)}/month',
                                            ),
                                          ),
                                          if (!assignment.isActive)
                                            const Chip(label: Text('INACTIVE')),
                                        ],
                                        FilledButton.tonalIcon(
                                          onPressed: busy
                                              ? null
                                              : () => _edit(
                                                  student: student,
                                                  existing: assignment,
                                                ),
                                          icon: Icon(
                                            assignment == null
                                                ? Icons.add
                                                : Icons.edit_outlined,
                                          ),
                                          label: Text(
                                            assignment == null
                                                ? 'Assign'
                                                : 'Edit',
                                          ),
                                        ),
                                        if (assignment != null)
                                          IconButton(
                                            tooltip: 'Remove',
                                            onPressed: busy
                                                ? null
                                                : () => context
                                                      .read<
                                                        StudentFeeAssignmentBloc
                                                      >()
                                                      .add(
                                                        DeleteStudentFeeAssignment(
                                                          assignment.id,
                                                        ),
                                                      ),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
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

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.student,
    required this.academicSession,
    required this.structures,
    this.existing,
  });

  final StudentEntity student;
  final String academicSession;
  final List<FeeStructureEntity> structures;
  final StudentFeeAssignmentEntity? existing;

  @override
  State<_AssignmentDialog> createState() => _AssignmentDialogState();
}

class _AssignmentDialogState extends State<_AssignmentDialog> {
  String? _structureId;
  FeeDiscountType _discountType = FeeDiscountType.none;
  late TextEditingController _discountValue;
  late TextEditingController _scholarship;
  late TextEditingController _siblingDiscount;
  late TextEditingController _customTuition;
  bool _transportEnabled = false;
  bool _admissionFeeWaived = false;
  bool _isActive = true;
  late DateTime _effectiveFrom;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _structureId = existing?.feeStructureId ?? widget.structures.first.id;
    _discountType = existing?.discountType ?? FeeDiscountType.none;
    _discountValue = _controller(existing?.discountValue);
    _scholarship = _controller(existing?.scholarshipAmount);
    _siblingDiscount = _controller(existing?.siblingDiscountAmount);
    _customTuition = TextEditingController(
      text: existing?.customMonthlyTuitionFee?.toStringAsFixed(0) ?? '',
    );
    _transportEnabled = existing?.transportEnabled ?? false;
    _admissionFeeWaived = existing?.admissionFeeWaived ?? false;
    _isActive = existing?.isActive ?? true;
    _effectiveFrom = existing?.effectiveFrom ?? DateTime.now();
  }

  @override
  void dispose() {
    _discountValue.dispose();
    _scholarship.dispose();
    _siblingDiscount.dispose();
    _customTuition.dispose();
    super.dispose();
  }

  FeeStructureEntity get _structure =>
      widget.structures.firstWhere((item) => item.id == _structureId);

  TextEditingController _controller(double? value) =>
      TextEditingController(text: (value ?? 0).toStringAsFixed(0));

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  double get _previewMonthly {
    final tuition = _customTuition.text.trim().isEmpty
        ? _structure.monthlyTuitionFee
        : _value(_customTuition);
    final discount = switch (_discountType) {
      FeeDiscountType.none => 0.0,
      FeeDiscountType.fixed => _value(_discountValue),
      FeeDiscountType.percentage => tuition * (_value(_discountValue) / 100),
    };
    final gross =
        tuition +
        (_transportEnabled ? _structure.transportFee : 0) +
        _structure.otherMonthlyCharges;
    final result =
        gross - discount - _value(_scholarship) - _value(_siblingDiscount);
    return result < 0 ? 0 : result;
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _effectiveFrom = value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Fee Assignment — ${widget.student.fullName}'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 360,
                child: DropdownButtonFormField<String>(
                  initialValue: _structureId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Fee Structure',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.structures
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.className} - ${item.sectionName} '
                            '(Rs. ${item.recurringMonthlyTotal.toStringAsFixed(0)})',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.existing == null
                      ? (value) => setState(() => _structureId = value)
                      : null,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<FeeDiscountType>(
                  initialValue: _discountType,
                  decoration: const InputDecoration(
                    labelText: 'Discount Type',
                    border: OutlineInputBorder(),
                  ),
                  items: FeeDiscountType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _discountType = value);
                    }
                  },
                ),
              ),
              _moneyField(
                _discountType == FeeDiscountType.percentage
                    ? 'Discount %'
                    : 'Discount Amount',
                _discountValue,
              ),
              _moneyField('Scholarship Amount', _scholarship),
              _moneyField('Sibling Discount', _siblingDiscount),
              _moneyField(
                'Custom Monthly Tuition',
                _customTuition,
                optional: true,
              ),
              SizedBox(
                width: 230,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Transport Enabled'),
                  subtitle: Text(
                    'Rs. ${_structure.transportFee.toStringAsFixed(0)}',
                  ),
                  value: _transportEnabled,
                  onChanged: (value) =>
                      setState(() => _transportEnabled = value),
                ),
              ),
              SizedBox(
                width: 230,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Waive Admission Fee'),
                  value: _admissionFeeWaived,
                  onChanged: (value) =>
                      setState(() => _admissionFeeWaived = value),
                ),
              ),
              SizedBox(
                width: 200,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.date_range),
                label: Text(
                  'Effective: '
                  '${_effectiveFrom.day.toString().padLeft(2, '0')}/'
                  '${_effectiveFrom.month.toString().padLeft(2, '0')}/'
                  '${_effectiveFrom.year}',
                ),
              ),
              SizedBox(
                width: 720,
                child: Card(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Monthly Payable: '
                          'Rs. ${_previewMonthly.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Admission Fee: Rs. '
                          '${(_admissionFeeWaived ? 0 : _structure.admissionFee).toStringAsFixed(0)}',
                        ),
                        Text(
                          'Annual Charges: Rs. '
                          '${_structure.annualCharges.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final now = DateTime.now();
            final structure = _structure;
            final repository = sl<StudentFeeAssignmentRepository>();

            Navigator.pop(
              context,
              StudentFeeAssignmentEntity(
                id: widget.existing?.id ?? repository.generateId(),
                studentId: widget.student.id,
                studentName: widget.student.fullName,
                admissionNo: widget.student.admissionNo,
                classId: widget.student.classId,
                sectionId: widget.student.sectionId,
                academicSession: widget.academicSession,
                feeStructureId: structure.id,
                feeStructureLabel:
                    '${structure.className} - ${structure.sectionName}',
                baseMonthlyTuitionFee: structure.monthlyTuitionFee,
                baseTransportFee: structure.transportFee,
                baseOtherMonthlyCharges: structure.otherMonthlyCharges,
                baseAdmissionFee: structure.admissionFee,
                baseAnnualCharges: structure.annualCharges,
                discountType: _discountType,
                discountValue: _value(_discountValue),
                scholarshipAmount: _value(_scholarship),
                siblingDiscountAmount: _value(_siblingDiscount),
                transportEnabled: _transportEnabled,
                customMonthlyTuitionFee: _customTuition.text.trim().isEmpty
                    ? null
                    : _value(_customTuition),
                admissionFeeWaived: _admissionFeeWaived,
                effectiveFrom: _effectiveFrom,
                isActive: _isActive,
                createdAt: widget.existing?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: const Text('Save Assignment'),
        ),
      ],
    );
  }

  Widget _moneyField(
    String label,
    TextEditingController controller, {
    bool optional = false,
  }) {
    return SizedBox(
      width: 210,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          prefixText:
              _discountType == FeeDiscountType.percentage &&
                  label == 'Discount %'
              ? null
              : 'Rs. ',
          suffixText: label == 'Discount %' ? '%' : null,
          helperText: optional ? 'Leave blank to use structure fee' : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
