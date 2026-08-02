import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/fee_structure_entity.dart';
import '../../domain/entities/student_fee_assignment_entity.dart';
import '../../domain/repositories/fee_structure_repository.dart';
import '../../domain/repositories/student_fee_assignment_repository.dart';
import '../bloc/student_fee_assignment_bloc.dart';

const _pageBackground = Color(0xFFF3F6FB);
const _brandBlue = Color(0xFF0B63CE);
const _textPrimary = Color(0xFF182230);
const _textSecondary = Color(0xFF667085);

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
  bool _bulkSaving = false;
  String? _referenceError;
  String _query = '';
  String? _selectedClassKey;
  String? _selectedStructureId;

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

  String _normal(String value) => value.trim().toLowerCase();

  String _classKey(FeeStructureEntity structure) =>
      '${_normal(structure.classId)}|${_normal(structure.className)}';

  bool _sameClass(StudentEntity student, FeeStructureEntity structure) {
    final studentClass = _normal(student.classId);
    return studentClass == _normal(structure.classId) ||
        studentClass == _normal(structure.className);
  }

  bool _sectionApplies(StudentEntity student, FeeStructureEntity structure) {
    final structureId = _normal(structure.sectionId);
    final structureName = _normal(structure.sectionName);

    final isAllSections =
        structureId.isEmpty ||
        structureName.isEmpty ||
        structureId == 'all' ||
        structureName == 'all' ||
        structureId == 'all sections' ||
        structureName == 'all sections';

    if (isAllSections) return true;

    final studentSection = _normal(student.sectionId);
    return studentSection == structureId || studentSection == structureName;
  }

  Future<void> _loadReferences() async {
    setState(() {
      _loadingReferences = true;
      _referenceError = null;
    });

    try {
      final session = _sessionController.text.trim();

      final values = await Future.wait<Object>([
        sl<StudentRepository>().getStudents(),
        sl<FeeStructureRepository>().getFeeStructures(
          academicSession: session,
          isActive: true,
        ),
      ]);

      if (!mounted) return;

      final students =
          (values[0] as List<StudentEntity>)
              .where((student) => student.isActive)
              .toList()
            ..sort(
              (a, b) =>
                  a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
            );

      final structures = (values[1] as List<FeeStructureEntity>).toList()
        ..sort((a, b) {
          final classCompare = a.className.compareTo(b.className);
          if (classCompare != 0) return classCompare;
          return a.sectionName.compareTo(b.sectionName);
        });

      setState(() {
        _students = students;
        _structures = structures;
        _loadingReferences = false;

        if (_selectedClassKey != null &&
            !structures.any((item) => _classKey(item) == _selectedClassKey)) {
          _selectedClassKey = null;
          _selectedStructureId = null;
        }
      });

      context.read<StudentFeeAssignmentBloc>().add(
        LoadStudentFeeAssignments(academicSession: session),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingReferences = false;
        _referenceError = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  List<FeeStructureEntity> get _classStructures {
    final key = _selectedClassKey;
    if (key == null) return const [];

    return _structures
        .where((structure) => _classKey(structure) == key)
        .toList(growable: false);
  }

  FeeStructureEntity? get _selectedStructure {
    final id = _selectedStructureId;
    if (id == null) return null;

    for (final structure in _structures) {
      if (structure.id == id) return structure;
    }
    return null;
  }

  List<StudentEntity> get _classStudents {
    final structures = _classStructures;
    if (structures.isEmpty) return const [];

    final reference = structures.first;
    final query = _normal(_query);

    return _students
        .where((student) {
          if (!_sameClass(student, reference)) return false;

          if (query.isEmpty) return true;

          return _normal(student.fullName).contains(query) ||
              _normal(student.admissionNo).contains(query) ||
              _normal(student.rollNumber).contains(query);
        })
        .toList(growable: false);
  }

  List<_ClassOption> get _classOptions {
    final map = <String, _ClassOption>{};

    for (final structure in _structures) {
      final key = _classKey(structure);
      map.putIfAbsent(
        key,
        () => _ClassOption(
          key: key,
          className: structure.className.isEmpty
              ? structure.classId
              : structure.className,
        ),
      );
    }

    final values = map.values.toList()
      ..sort((a, b) => a.className.compareTo(b.className));

    return values;
  }

  void _selectClass(String? key) {
    setState(() {
      _selectedClassKey = key;
      _selectedStructureId = null;
      _searchController.clear();
      _query = '';

      final structures = key == null
          ? const <FeeStructureEntity>[]
          : _structures.where((item) => _classKey(item) == key).toList();

      if (structures.length == 1) {
        _selectedStructureId = structures.first.id;
      }
    });
  }

  Future<void> _edit({
    required StudentEntity student,
    StudentFeeAssignmentEntity? existing,
  }) async {
    final matching = _classStructures
        .where(
          (structure) =>
              _sameClass(student, structure) &&
              _sectionApplies(student, structure),
        )
        .toList();

    if (matching.isEmpty) {
      _show(
        'No fee structure applies to ${student.fullName} '
        '(${student.classId} - ${student.sectionId}). '
        'Create an All Sections structure or a matching section structure.',
      );
      return;
    }

    final preferredId = existing?.feeStructureId ?? _selectedStructureId;

    matching.sort((a, b) {
      if (a.id == preferredId) return -1;
      if (b.id == preferredId) return 1;
      return a.sectionName.compareTo(b.sectionName);
    });

    final result = await showDialog<StudentFeeAssignmentEntity>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AssignmentDialog(
        student: student,
        academicSession: _sessionController.text.trim(),
        structures: matching,
        preferredStructureId: preferredId,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    try {
      await sl<StudentFeeAssignmentRepository>().saveAssignment(result);

      if (!mounted) return;

      _show('Fee assigned to ${student.fullName}.');
      context.read<StudentFeeAssignmentBloc>().add(
        LoadStudentFeeAssignments(
          academicSession: _sessionController.text.trim(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _show(
        error
            .toString()
            .replaceFirst('StateError: ', '')
            .replaceFirst('Invalid argument(s): ', ''),
      );
    }
  }

  Future<void> _assignAll(
    Map<String, StudentFeeAssignmentEntity> byStudent,
  ) async {
    final structure = _selectedStructure;

    if (structure == null) {
      _show('Select a fee structure first.');
      return;
    }

    final eligible = _classStudents
        .where(
          (student) =>
              byStudent[student.id] == null &&
              _sectionApplies(student, structure),
        )
        .toList();

    if (eligible.isEmpty) {
      _show('No unassigned students are eligible for the selected structure.');
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Assign Fee Structure'),
            content: Text(
              'Assign "${_structureLabel(structure)}" to '
              '${eligible.length} unassigned students?\n\n'
              'Individual discounts or custom fees can still be '
              'edited afterwards.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Assign All'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _bulkSaving = true);

    var saved = 0;
    final failures = <String>[];

    try {
      final repository = sl<StudentFeeAssignmentRepository>();

      for (final student in eligible) {
        try {
          await repository.saveAssignment(
            _defaultAssignment(student: student, structure: structure),
          );
          saved++;
        } catch (error) {
          failures.add(
            '${student.fullName}: '
            '${error.toString().replaceFirst('StateError: ', '')}',
          );
        }
      }

      if (!mounted) return;

      context.read<StudentFeeAssignmentBloc>().add(
        LoadStudentFeeAssignments(
          academicSession: _sessionController.text.trim(),
        ),
      );

      if (failures.isEmpty) {
        _show('$saved students assigned successfully.');
      } else {
        _show(
          '$saved assigned; ${failures.length} failed. '
          '${failures.first}',
        );
      }
    } finally {
      if (mounted) setState(() => _bulkSaving = false);
    }
  }

  StudentFeeAssignmentEntity _defaultAssignment({
    required StudentEntity student,
    required FeeStructureEntity structure,
  }) {
    final now = DateTime.now();

    return StudentFeeAssignmentEntity(
      id: sl<StudentFeeAssignmentRepository>().generateId(),
      studentId: student.id,
      studentName: student.fullName,
      admissionNo: student.admissionNo,
      classId: student.classId,
      sectionId: student.sectionId,
      academicSession: _sessionController.text.trim(),
      feeStructureId: structure.id,
      feeStructureLabel: _structureLabel(structure),
      baseMonthlyTuitionFee: structure.monthlyTuitionFee,
      baseTransportFee: structure.transportFee,
      baseOtherMonthlyCharges: structure.otherMonthlyCharges,
      baseAdmissionFee: structure.admissionFee,
      baseAnnualCharges: structure.annualCharges,
      discountType: FeeDiscountType.none,
      discountValue: 0,
      scholarshipAmount: 0,
      siblingDiscountAmount: 0,
      transportEnabled: false,
      customMonthlyTuitionFee: null,
      admissionFeeWaived: false,
      effectiveFrom: now,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  String _structureLabel(FeeStructureEntity structure) {
    final section = structure.sectionName.trim();
    return section.isEmpty
        ? structure.className
        : '${structure.className} - $section';
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Student Fee Assignment')),
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
                _loadingReferences ||
                _bulkSaving ||
                state is StudentFeeAssignmentLoading;

            final assignments = state is StudentFeeAssignmentLoaded
                ? state.assignments
                : const <StudentFeeAssignmentEntity>[];

            final byStudent = {
              for (final item in assignments) item.studentId: item,
            };

            final classStudents = _classStudents;
            final assignedInClass = classStudents
                .where((student) => byStudent[student.id] != null)
                .length;

            return Stack(
              children: [
                Column(
                  children: [
                    _buildWorkflowHeader(
                      assignments: assignments,
                      byStudent: byStudent,
                      classStudents: classStudents,
                      assignedInClass: assignedInClass,
                      busy: busy,
                    ),
                    Expanded(
                      child: _referenceError != null
                          ? _ErrorPanel(
                              message: _referenceError!,
                              onRetry: _loadReferences,
                            )
                          : _selectedClassKey == null
                          ? const _EmptyPanel(
                              icon: Icons.school_outlined,
                              title: 'Select a Class',
                              message:
                                  'Choose a class above to see all active students and assign its fee structure.',
                            )
                          : classStudents.isEmpty
                          ? const _EmptyPanel(
                              icon: Icons.person_search_outlined,
                              title: 'No Students Found',
                              message:
                                  'No active students match the selected class or search.',
                            )
                          : _StudentAssignmentList(
                              students: classStudents,
                              assignments: byStudent,
                              selectedStructure: _selectedStructure,
                              sectionApplies: _sectionApplies,
                              onEdit: _edit,
                              onDelete: (assignment) {
                                context.read<StudentFeeAssignmentBloc>().add(
                                  DeleteStudentFeeAssignment(assignment.id),
                                );
                              },
                              busy: busy,
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

  Widget _buildWorkflowHeader({
    required List<StudentFeeAssignmentEntity> assignments,
    required Map<String, StudentFeeAssignmentEntity> byStudent,
    required List<StudentEntity> classStudents,
    required int assignedInClass,
    required bool busy,
  }) {
    final classOptions = _classOptions;
    final structures = _classStructures;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0B63CE),
                  Color(0xFF3B82F6),
                  Color(0xFF7C3AED),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.assignment_ind_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class-wise Fee Assignment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Select class → select fee structure → assign students → adjust individual fee when required.',
                        style: TextStyle(color: Color(0xFFEAF2FF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    child: TextFormField(
                      controller: _sessionController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Session',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 230,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedClassKey,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '1. Select Class',
                        prefixIcon: Icon(Icons.school_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: classOptions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.key,
                              child: Text(item.className),
                            ),
                          )
                          .toList(),
                      onChanged: busy ? null : _selectClass,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    child: DropdownButtonFormField<String>(
                      initialValue:
                          structures.any(
                            (item) => item.id == _selectedStructureId,
                          )
                          ? _selectedStructureId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '2. Select Fee Structure',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: structures
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                '${_structureLabel(item)} • '
                                'Rs. ${item.recurringMonthlyTotal.toStringAsFixed(0)}/month',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (value) =>
                                setState(() => _selectedStructureId = value),
                    ),
                  ),
                  SizedBox(
                    width: 270,
                    child: TextFormField(
                      controller: _searchController,
                      enabled: _selectedClassKey != null,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        labelText: 'Search selected class students',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: busy ? null : _loadReferences,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reload'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                    ),
                    onPressed: busy || _selectedStructure == null
                        ? null
                        : () => _assignAll(byStudent),
                    icon: const Icon(Icons.done_all_outlined),
                    label: const Text('Assign All Unassigned'),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedClassKey != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _MetricChip(
                  label: 'Students',
                  value: '${classStudents.length}',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Assigned',
                  value: '$assignedInClass',
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                _MetricChip(
                  label: 'Pending',
                  value: '${classStudents.length - assignedInClass}',
                  color: const Color(0xFFEA580C),
                ),
                const Spacer(),
                Text(
                  '${assignments.length} total assignments in '
                  '${_sessionController.text.trim()}',
                  style: const TextStyle(color: _textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ClassOption {
  const _ClassOption({required this.key, required this.className});

  final String key;
  final String className;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StudentAssignmentList extends StatelessWidget {
  const _StudentAssignmentList({
    required this.students,
    required this.assignments,
    required this.selectedStructure,
    required this.sectionApplies,
    required this.onEdit,
    required this.onDelete,
    required this.busy,
  });

  final List<StudentEntity> students;
  final Map<String, StudentFeeAssignmentEntity> assignments;
  final FeeStructureEntity? selectedStructure;
  final bool Function(StudentEntity, FeeStructureEntity) sectionApplies;
  final Future<void> Function({
    required StudentEntity student,
    StudentFeeAssignmentEntity? existing,
  })
  onEdit;
  final void Function(StudentFeeAssignmentEntity) onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final assignment = assignments[student.id];
        final compatible =
            selectedStructure == null ||
            sectionApplies(student, selectedStructure!);

        final initials = student.fullName.trim().isEmpty
            ? '?'
            : student.fullName.trim()[0].toUpperCase();

        return Card(
          elevation: 0,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: assignment == null
                  ? const Color(0xFFEAF2FF)
                  : const Color(0xFFE8FBF3),
              child: Text(
                initials,
                style: TextStyle(
                  color: assignment == null
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF059669),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              student.fullName,
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              '${student.admissionNo} • Roll '
              '${student.rollNumber.isEmpty ? '-' : student.rollNumber} '
              '• ${student.classId} - ${student.sectionId}',
            ),
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!compatible)
                  const Chip(
                    avatar: Icon(Icons.warning_amber_rounded, size: 17),
                    label: Text('SECTION NOT MATCHED'),
                  )
                else if (assignment == null)
                  const Chip(label: Text('NOT ASSIGNED'))
                else ...[
                  Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 17),
                    label: Text(
                      'Rs. ${assignment.monthlyPayable.toStringAsFixed(0)}/month',
                    ),
                  ),
                  if (!assignment.isActive) const Chip(label: Text('INACTIVE')),
                ],
                FilledButton.tonalIcon(
                  onPressed: busy || !compatible
                      ? null
                      : () => onEdit(student: student, existing: assignment),
                  icon: Icon(
                    assignment == null ? Icons.add : Icons.edit_outlined,
                  ),
                  label: Text(assignment == null ? 'Assign' : 'Adjust Fee'),
                ),
                if (assignment != null)
                  IconButton(
                    tooltip: 'Remove Assignment',
                    onPressed: busy ? null : () => onDelete(assignment),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentDialog extends StatefulWidget {
  const _AssignmentDialog({
    required this.student,
    required this.academicSession,
    required this.structures,
    required this.preferredStructureId,
    this.existing,
  });

  final StudentEntity student;
  final String academicSession;
  final List<FeeStructureEntity> structures;
  final String? preferredStructureId;
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
    final preferred =
        widget.structures.any(
          (item) =>
              item.id ==
              (existing?.feeStructureId ?? widget.preferredStructureId),
        )
        ? existing?.feeStructureId ?? widget.preferredStructureId
        : widget.structures.first.id;

    _structureId = preferred;
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

    final payable =
        gross - discount - _value(_scholarship) - _value(_siblingDiscount);

    return payable < 0 ? 0 : payable;
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (value != null) {
      setState(() => _effectiveFrom = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Assign Fee — ${widget.student.fullName}'
            : 'Adjust Fee — ${widget.student.fullName}',
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 720,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.student.admissionNo} • '
                    '${widget.student.classId} - '
                    '${widget.student.sectionId}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
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
                            '${item.className} - '
                            '${item.sectionName} '
                            '(Rs. ${item.recurringMonthlyTotal.toStringAsFixed(0)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _structureId = value),
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
                  color: const Color(0xFFE8FBF3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Monthly Payable: '
                          'Rs. ${_previewMonthly.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Color(0xFF047857),
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
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
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Assignment'),
        ),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    final structure = _structure;

    Navigator.pop(
      context,
      StudentFeeAssignmentEntity(
        id:
            widget.existing?.id ??
            sl<StudentFeeAssignmentRepository>().generateId(),
        studentId: widget.student.id,
        studentName: widget.student.fullName,
        admissionNo: widget.student.admissionNo,
        classId: widget.student.classId,
        sectionId: widget.student.sectionId,
        academicSession: widget.academicSession,
        feeStructureId: structure.id,
        feeStructureLabel: '${structure.className} - ${structure.sectionName}',
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
          prefixText: label == 'Discount %' ? null : 'Rs. ',
          suffixText: label == 'Discount %' ? '%' : null,
          helperText: optional ? 'Leave blank to use structure fee' : null,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: _brandBlue),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
