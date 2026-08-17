import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../../documents/presentation/pages/fee_receipt_preview_page.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../school_store/domain/entities/store_sale_entity.dart';
import '../../../school_store/domain/repositories/store_payment_repository.dart';
import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../bloc/fee_collection_bloc.dart';
import '../bloc/fee_document_bloc.dart';

import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_reference_resolver.dart';

class FeeCollectionPage extends StatelessWidget {
  const FeeCollectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeeCollectionBloc>(create: (_) => sl<FeeCollectionBloc>()),
        BlocProvider<FeeDocumentBloc>(create: (_) => sl<FeeDocumentBloc>()),
      ],
      child: const _FeeCollectionView(),
    );
  }
}

class _FeeCollectionView extends StatefulWidget {
  const _FeeCollectionView();

  @override
  State<_FeeCollectionView> createState() => _FeeCollectionViewState();
}

class _FeeCollectionViewState extends State<_FeeCollectionView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  List<StudentEntity> _students = const [];
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  String? _selectedClassId;
  String? _selectedSectionId;
  StudentEntity? _selectedStudent;
  final Set<String> _selectedDueIds = {};
  final Set<String> _selectedAdditionalDueIds = {};
  FeePaymentMethod _method = FeePaymentMethod.cash;
  DateTime _paymentDate = DateTime.now();
  bool _loadingStudents = true;
  bool _useAdvance = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _searchController.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);

    try {
      final repository = sl<AcademicStructureRepository>();
      final values = await Future.wait<Object>([
        sl<StudentRepository>().getStudents(),
        repository.getClasses(),
        repository.getSections(),
      ]);

      if (!mounted) return;

      final students =
          (values[0] as List<StudentEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort(
              (a, b) =>
                  a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
            );

      final classes =
          (values[1] as List<AcademicClassEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort(compareAcademicClasses);

      final sections =
          (values[2] as List<SectionEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _students = students;
        _classes = classes;
        _sections = sections;
        _loadingStudents = false;

        if (_selectedClassId != null &&
            !classes.any((item) => item.id == _selectedClassId)) {
          _selectedClassId = null;
          _selectedSectionId = null;
          _selectedStudent = null;
        } else if (_selectedClassId != null) {
          final classSections = sections
              .where((section) => section.classId == _selectedClassId)
              .toList();
          if (classSections.length == 1) {
            _selectedSectionId = classSections.first.id;
          }
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
      _show(error.toString());
    }
  }

  void _selectClass(String? classId) {
    final sections = _sections
        .where((section) => section.classId == classId)
        .toList(growable: false);
    setState(() {
      _selectedClassId = classId;
      _selectedSectionId = sections.length == 1 ? sections.first.id : null;
      _selectedStudent = null;
      _selectedDueIds.clear();
      _selectedAdditionalDueIds.clear();
      _searchController.clear();
      _query = '';
    });
  }

  void _selectSection(String? sectionId) {
    setState(() {
      _selectedSectionId = sectionId;
      _selectedStudent = null;
      _selectedDueIds.clear();
      _selectedAdditionalDueIds.clear();
      _searchController.clear();
      _query = '';
    });
  }

  void _selectStudent(StudentEntity student) {
    setState(() {
      _selectedStudent = student;
      _selectedDueIds.clear();
      _selectedAdditionalDueIds.clear();
      _amountController.clear();
      _useAdvance = true;
    });

    context.read<FeeCollectionBloc>().add(
      LoadFeeCollectionData(
        academicSession: _sessionController.text.trim(),
        studentId: student.id,
      ),
    );
  }

  void _selectStudentFromSearch(StudentEntity student) {
    AcademicClassEntity? studentClass;
    for (final item in _classes) {
      if (_academicResolver.sameClass(item.id, student.classId)) {
        studentClass = item;
        break;
      }
    }

    SectionEntity? studentSection;
    final normalizedStudentSection = AcademicReferenceResolver.normalize(
      student.sectionId,
    );

    for (final item in _sections) {
      final belongsToSelectedClass =
          studentClass == null || item.classId == studentClass.id;
      final sectionMatches =
          AcademicReferenceResolver.normalize(item.id) ==
              normalizedStudentSection ||
          AcademicReferenceResolver.normalize(item.name) ==
              normalizedStudentSection;

      if (belongsToSelectedClass && sectionMatches) {
        studentSection = item;
        break;
      }
    }

    setState(() {
      _selectedClassId = studentClass?.id;
      _selectedSectionId = studentSection?.id;
      _searchController.clear();
      _query = '';
    });
    _selectStudent(student);
  }

  String _normal(String value) => value.trim().toLowerCase();

  AcademicReferenceResolver get _academicResolver =>
      AcademicReferenceResolver(classes: _classes, sections: _sections);

  String _className(StudentEntity student) =>
      _academicResolver.className(student.classId);

  String _sectionName(StudentEntity student) =>
      _academicResolver.sectionName(student.sectionId);

  AcademicClassEntity? get _selectedClass {
    final id = _selectedClassId;
    if (id == null) return null;

    for (final item in _classes) {
      if (item.id == id) return item;
    }

    return null;
  }

  SectionEntity? get _selectedSection {
    final id = _selectedSectionId;
    if (id == null) return null;

    for (final item in _sections) {
      if (item.id == id) return item;
    }

    return null;
  }

  List<SectionEntity> get _availableSections {
    final classId = _selectedClassId;
    if (classId == null) return const [];

    return _sections
        .where((section) => section.classId == classId)
        .toList(growable: false);
  }

  bool _matchesClass(StudentEntity student) {
    final selected = _selectedClass;
    if (selected == null) return false;

    return _academicResolver.sameClass(student.classId, selected.id);
  }

  bool _matchesSection(StudentEntity student) {
    final selectedClass = _selectedClass;
    final selectedSection = _selectedSection;

    if (selectedClass == null || selectedSection == null) {
      return false;
    }

    if (!_academicResolver.sameClass(student.classId, selectedClass.id)) {
      return false;
    }

    final studentSection = AcademicReferenceResolver.normalize(
      student.sectionId,
    );
    final selectedSectionId = AcademicReferenceResolver.normalize(
      selectedSection.id,
    );
    final selectedSectionName = AcademicReferenceResolver.normalize(
      selectedSection.name,
    );

    return studentSection == selectedSectionId ||
        studentSection == selectedSectionName;
  }

  List<StudentEntity> get _visibleStudents {
    if (_selectedClassId == null || _selectedSectionId == null) {
      return const [];
    }

    final query = _query.trim().toLowerCase();

    return _students
        .where((student) {
          if (!_matchesClass(student) || !_matchesSection(student)) {
            return false;
          }

          if (query.isEmpty) return true;

          return student.fullName.toLowerCase().contains(query) ||
              student.admissionNo.toLowerCase().contains(query) ||
              student.rollNumber.toLowerCase().contains(query) ||
              student.guardianPhone.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  double _selectedOutstanding(List<MonthlyFeeDueEntity> dues) {
    return dues
        .where((item) => _selectedDueIds.contains(item.id))
        .fold<double>(0, (sum, item) => sum + item.outstandingAmount);
  }

  double _selectedAdditionalOutstanding(
    List<StudentAdditionalChargeDueEntity> dues,
  ) => dues
      .where((item) => _selectedAdditionalDueIds.contains(item.id))
      .fold<double>(0, (sum, item) => sum + item.outstandingAmount);

  Future<void> _pickPaymentDate() async {
    final value = await showManualDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (value != null) setState(() => _paymentDate = value);
  }

  Future<void> _collect({
    required double selectedOutstanding,
    required double availableAdvance,
  }) async {
    final student = _selectedStudent;
    if (student == null) {
      _show('Select a student.');
      return;
    }

    final rawAmount = _amountController.text.trim();
    final amount = rawAmount.isEmpty ? 0.0 : double.tryParse(rawAmount);
    if (amount == null || amount < 0) {
      _show('Enter a valid payment amount.');
      return;
    }

    final advanceUsed = _useAdvance
        ? (availableAdvance < selectedOutstanding
              ? availableAdvance
              : selectedOutstanding)
        : 0.0;

    if (selectedOutstanding > 0 && amount <= 0 && advanceUsed <= 0) {
      _show('Enter a payment amount or use available advance.');
      return;
    }

    if (_selectedDueIds.isEmpty && _selectedAdditionalDueIds.isEmpty) {
      if (amount <= 0) {
        _show('Enter an amount to collect as advance fee.');
        return;
      }

      final confirmed =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              icon: const Icon(Icons.info_outline),
              title: const Text('No Receivable Found'),
              content: Text(
                'There is no selected receivable for ${student.fullName}. '
                'Rs. ${amount.toStringAsFixed(0)} will be recorded as advance fee. '
                'Do you want to continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  icon: const Icon(Icons.payments_outlined),
                  label: const Text('Collect as Advance'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmed || !mounted) return;
    }

    context.read<FeeCollectionBloc>().add(
      CollectStudentFeePayment(
        academicSession: _sessionController.text.trim(),
        studentId: student.id,
        studentName: student.fullName,
        admissionNo: student.admissionNo,
        paymentDate: _paymentDate,
        method: _method,
        referenceNumber: _referenceController.text.trim(),
        amount: amount,
        dueIds: _selectedDueIds.toList(),
        additionalChargeDueIds: _selectedAdditionalDueIds.toList(),
        useAdvance: _useAdvance,
        notes: _notesController.text.trim(),
      ),
    );
  }

  Future<void> _cancelPayment(FeePaymentEntity payment) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Payment'),
        content: TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Cancellation Reason',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Cancel Payment'),
          ),
        ],
      ),
    );
    controller.dispose();

    final student = _selectedStudent;
    if (reason == null || reason.isEmpty || student == null || !mounted) {
      return;
    }

    context.read<FeeCollectionBloc>().add(
      CancelStudentFeePayment(
        paymentId: payment.id,
        reason: reason,
        academicSession: _sessionController.text.trim(),
        studentId: student.id,
      ),
    );
  }

  void _previewReceipt(FeePaymentEntity payment) {
    final student = _selectedStudent;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FeeReceiptPreviewPage(
          request: FeeReceiptDocumentRequest(payment: payment),
          className: student == null ? '' : _className(student),
          sectionName: student == null ? '' : _sectionName(student),
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
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        actions: const [DashboardNavigationButton()],
        title: const Text('Fee Collection'),
      ),
      body: SafeArea(
        child: BlocConsumer<FeeCollectionBloc, FeeCollectionState>(
          listener: (context, state) {
            if (state is FeeCollectionLoaded && state.message != null) {
              _show(state.message!);
              if (state.latestPayment != null) {
                _selectedDueIds.clear();
                _selectedAdditionalDueIds.clear();
                _amountController.clear();
                _referenceController.clear();
                _notesController.clear();
              }
            } else if (state is FeeCollectionError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = _loadingStudents || state is FeeCollectionLoading;
            final dues = state is FeeCollectionLoaded
                ? state.dues
                : const <MonthlyFeeDueEntity>[];
            final payments = state is FeeCollectionLoaded
                ? state.payments
                : const <FeePaymentEntity>[];
            final additionalDues = state is FeeCollectionLoaded
                ? state.additionalChargeDues
                : const <StudentAdditionalChargeDueEntity>[];
            final availableAdvance = state is FeeCollectionLoaded
                ? state.availableAdvance
                : 0.0;
            final payableDues = dues
                .where(
                  (item) =>
                      item.status != MonthlyFeeDueStatus.paid &&
                      item.status != MonthlyFeeDueStatus.cancelled,
                )
                .toList();
            final selectedOutstanding = _selectedOutstanding(payableDues);
            final payableAdditionalDues = additionalDues
                .where(
                  (item) =>
                      item.status != StudentAdditionalChargeDueStatus.paid &&
                      item.status != StudentAdditionalChargeDueStatus.waived &&
                      item.status != StudentAdditionalChargeDueStatus.cancelled,
                )
                .toList();
            final totalSelectedOutstanding =
                selectedOutstanding +
                _selectedAdditionalOutstanding(payableAdditionalDues);
            final compact = MediaQuery.sizeOf(context).width < 760;

            return Stack(
              children: [
                Column(
                  children: [
                    _globalStudentSearch(busy),
                    Expanded(
                      child: Row(
                        children: [
                          if (!compact || _selectedStudent == null)
                            Flexible(
                              fit: compact ? FlexFit.tight : FlexFit.loose,
                              child: SizedBox(
                                width: compact ? null : 310,
                                child: Card(
                                  margin: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    10,
                                    12,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: [
                                            DropdownButtonFormField<String>(
                                              initialValue: _selectedClassId,
                                              isExpanded: true,
                                              decoration: const InputDecoration(
                                                labelText: '1. Select Class',
                                                prefixIcon: Icon(
                                                  Icons.school_outlined,
                                                ),
                                                border: OutlineInputBorder(),
                                              ),
                                              items: _classes
                                                  .map(
                                                    (item) => DropdownMenuItem(
                                                      value: item.id,
                                                      child: Text(item.name),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: busy
                                                  ? null
                                                  : _selectClass,
                                            ),
                                            const SizedBox(height: 8),
                                            DropdownButtonFormField<String>(
                                              initialValue:
                                                  _availableSections.any(
                                                    (item) =>
                                                        item.id ==
                                                        _selectedSectionId,
                                                  )
                                                  ? _selectedSectionId
                                                  : null,
                                              isExpanded: true,
                                              decoration: InputDecoration(
                                                labelText:
                                                    _availableSections.length ==
                                                        1
                                                    ? '2. Section'
                                                    : '2. Select Section',
                                                helperText:
                                                    _availableSections.length ==
                                                        1
                                                    ? 'Automatically selected'
                                                    : null,
                                                prefixIcon: const Icon(
                                                  Icons.view_list_outlined,
                                                ),
                                                border:
                                                    const OutlineInputBorder(),
                                              ),
                                              items: _availableSections
                                                  .map(
                                                    (item) => DropdownMenuItem(
                                                      value: item.id,
                                                      child: Text(item.name),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged:
                                                  busy ||
                                                      _selectedClassId ==
                                                          null ||
                                                      _availableSections
                                                              .length <=
                                                          1
                                                  ? null
                                                  : _selectSection,
                                            ),
                                            const SizedBox(height: 8),
                                            TextFormField(
                                              controller: _searchController,
                                              enabled:
                                                  _selectedSectionId != null,
                                              onChanged: (value) => setState(
                                                () => _query = value,
                                              ),
                                              decoration: const InputDecoration(
                                                labelText:
                                                    '3. Search selected section',
                                                prefixIcon: Icon(Icons.search),
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: _selectedClassId == null
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    'Select a class first.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              )
                                            : _selectedSectionId == null
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    'Now select a section.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              )
                                            : _visibleStudents.isEmpty
                                            ? const Center(
                                                child: Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child: Text(
                                                    'No active students found in this section.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                              )
                                            : ListView.builder(
                                                itemCount:
                                                    _visibleStudents.length,
                                                itemBuilder: (context, index) {
                                                  final student =
                                                      _visibleStudents[index];
                                                  final name = student.fullName
                                                      .trim();
                                                  return ListTile(
                                                    dense: true,
                                                    visualDensity:
                                                        const VisualDensity(
                                                          vertical: -2,
                                                        ),
                                                    selected:
                                                        _selectedStudent?.id ==
                                                        student.id,
                                                    selectedTileColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer
                                                            .withValues(
                                                              alpha: .35,
                                                            ),
                                                    leading: CircleAvatar(
                                                      child: Text(
                                                        name.isEmpty
                                                            ? '?'
                                                            : name[0]
                                                                  .toUpperCase(),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      student.fullName,
                                                    ),
                                                    subtitle: Text(
                                                      '${student.admissionNo}  |  Roll: '
                                                      '${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                                                    ),
                                                    trailing:
                                                        _selectedStudent?.id ==
                                                            student.id
                                                        ? const Icon(
                                                            Icons.check_circle,
                                                          )
                                                        : null,
                                                    onTap: busy
                                                        ? null
                                                        : () => _selectStudent(
                                                            student,
                                                          ),
                                                  );
                                                },
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!compact || _selectedStudent != null)
                            Expanded(
                              child: _selectedStudent == null
                                  ? const Center(
                                      child: Text(
                                        'Select a student to collect fee.',
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      padding: EdgeInsets.fromLTRB(
                                        compact ? 12 : 0,
                                        10,
                                        12,
                                        18,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _studentHeader(
                                            dues,
                                            additionalDues,
                                            payments,
                                            busy,
                                          ),
                                          const SizedBox(height: 12),
                                          _duesCard(
                                            payableDues,
                                            totalSelectedOutstanding,
                                            busy,
                                          ),
                                          const SizedBox(height: 12),
                                          _additionalDuesCard(
                                            payableAdditionalDues,
                                            totalSelectedOutstanding,
                                            busy,
                                          ),
                                          const SizedBox(height: 12),
                                          _paymentForm(
                                            payableDues,
                                            totalSelectedOutstanding,
                                            availableAdvance,
                                            busy,
                                          ),
                                          const SizedBox(height: 12),
                                          _paymentHistory(payments, busy),
                                        ],
                                      ),
                                    ),
                            ),
                        ],
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

  Widget _globalStudentSearch(bool busy) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Autocomplete<StudentEntity>(
        displayStringForOption: (student) => student.fullName,
        optionsBuilder: (value) {
          final query = _normal(value.text);
          if (query.isEmpty) return const Iterable<StudentEntity>.empty();
          return _students
              .where(
                (student) =>
                    _normal(student.fullName).contains(query) ||
                    _normal(student.fatherName).contains(query) ||
                    _normal(student.admissionNo).contains(query) ||
                    _normal(student.rollNumber).contains(query),
              )
              .take(10);
        },
        onSelected: busy ? (_) {} : _selectStudentFromSearch,
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !busy,
              onSubmitted: (_) => onFieldSubmitted(),
              decoration: const InputDecoration(
                labelText: 'Search student by name',
                hintText: 'Type student or father name, admission or roll no.',
                prefixIcon: Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
        optionsViewBuilder: (context, onSelected, options) {
          final results = options.toList(growable: false);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 720,
                  maxHeight: 360,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = results[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(
                        'Father: ${student.fatherName.isEmpty ? '-' : student.fatherName}  |  '
                        'Class: ${_className(student)} - ${_sectionName(student)}  |  '
                        'Roll: ${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                      ),
                      onTap: () => onSelected(student),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _studentHeader(
    List<MonthlyFeeDueEntity> dues,
    List<StudentAdditionalChargeDueEntity> additionalDues,
    List<FeePaymentEntity> payments,
    bool busy,
  ) {
    final student = _selectedStudent!;
    return Card(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: .42),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Text(
                student.fullName.trim().isEmpty
                    ? '?'
                    : student.fullName.trim()[0].toUpperCase(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${student.admissionNo}  |  Roll ${student.rollNumber}  |  '
                    '${_className(student)}-${_sectionName(student)}',
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: busy
                  ? null
                  : () => _openStudentLedger(dues, additionalDues, payments),
              icon: const Icon(Icons.menu_book_outlined, size: 19),
              label: const Text('Student Ledger'),
            ),
            const SizedBox(width: 8),
            if (student.guardianPhone.trim().isNotEmpty)
              Chip(
                avatar: const Icon(Icons.phone_outlined, size: 16),
                label: Text(student.guardianPhone),
              ),
          ],
        ),
      ),
    );
  }

  Widget _duesCard(
    List<MonthlyFeeDueEntity> dues,
    double selectedOutstanding,
    bool busy,
  ) {
    if (dues.isEmpty) {
      return const Card(
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            child: Icon(Icons.check_circle_outline, size: 20),
          ),
          title: Text('No Monthly Fee Due'),
          subtitle: Text('This student has no outstanding monthly fee.'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Outstanding Dues',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    'Selected: Rs. ${selectedOutstanding.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dues.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text('No outstanding dues.'),
            )
          else
            Column(
              children: [
                for (final due in dues)
                  CheckboxListTile(
                    value: _selectedDueIds.contains(due.id),
                    title: Text('${_monthName(due.month)} ${due.year}'),
                    subtitle: Text(
                      'Net Rs. ${due.netPayable.toStringAsFixed(0)} | '
                      'Paid Rs. ${due.paidAmount.toStringAsFixed(0)} | '
                      'Outstanding Rs. ${due.outstandingAmount.toStringAsFixed(0)}',
                    ),
                    secondary: Chip(label: Text(due.status.name.toUpperCase())),
                    onChanged: busy
                        ? null
                        : (selected) {
                            setState(() {
                              selected == true
                                  ? _selectedDueIds.add(due.id)
                                  : _selectedDueIds.remove(due.id);
                            });
                          },
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _paymentForm(
    List<MonthlyFeeDueEntity> dues,
    double selectedOutstanding,
    double availableAdvance,
    bool busy,
  ) {
    final advanceUsed = _useAdvance
        ? (availableAdvance < selectedOutstanding
              ? availableAdvance
              : selectedOutstanding)
        : 0.0;
    final cashRequired = selectedOutstanding > advanceUsed
        ? selectedOutstanding - advanceUsed
        : 0.0;
    final enteredCash = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isAdvanceOnly =
        selectedOutstanding > 0 && advanceUsed > 0 && cashRequired <= 0;

    String buttonLabel;
    if (isAdvanceOnly) {
      buttonLabel = 'Adjust From Advance';
    } else if (selectedOutstanding > 0 && cashRequired > 0) {
      buttonLabel = 'Collect Rs. ${cashRequired.toStringAsFixed(0)}';
    } else if (selectedOutstanding <= 0 && enteredCash > 0) {
      buttonLabel = 'Collect as Advance';
    } else {
      buttonLabel = 'Collect Payment';
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Collect Payment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      selectedOutstanding > 0
                          ? 'Selected Rs. ${selectedOutstanding.toStringAsFixed(0)}'
                          : 'No due selected - payment can be saved as advance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedStudent != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: .28),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Wrap(
                  spacing: 22,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _advanceSummaryItem(
                      'Selected Fee',
                      selectedOutstanding,
                      Icons.receipt_long_outlined,
                    ),
                    _advanceSummaryItem(
                      'Available Advance',
                      availableAdvance,
                      Icons.account_balance_wallet_outlined,
                    ),
                    if (availableAdvance > 0 && selectedOutstanding > 0)
                      SizedBox(
                        width: 245,
                        child: CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _useAdvance,
                          title: const Text('Use Available Advance'),
                          subtitle: const Text('Applied automatically first'),
                          controlAffinity: ListTileControlAffinity.leading,
                          onChanged: busy
                              ? null
                              : (value) {
                                  setState(() {
                                    _useAdvance = value ?? true;
                                    final nextAdvanceUsed = _useAdvance
                                        ? (availableAdvance <
                                                  selectedOutstanding
                                              ? availableAdvance
                                              : selectedOutstanding)
                                        : 0.0;
                                    final nextCash =
                                        selectedOutstanding > nextAdvanceUsed
                                        ? selectedOutstanding - nextAdvanceUsed
                                        : 0.0;
                                    _amountController.text = nextCash <= 0
                                        ? ''
                                        : nextCash.toStringAsFixed(0);
                                  });
                                },
                        ),
                      ),
                    _advanceSummaryItem(
                      'Advance Used',
                      advanceUsed,
                      Icons.savings_outlined,
                    ),
                    _advanceSummaryItem(
                      'Cash Required',
                      cashRequired,
                      Icons.payments_outlined,
                      emphasized: true,
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: 170,
              child: TextFormField(
                controller: _amountController,
                enabled: !busy && !isAdvanceOnly,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: isAdvanceOnly
                      ? 'Cash Amount (Not Required)'
                      : 'Cash / Payment Amount',
                  prefixText: 'Rs. ',
                  border: const OutlineInputBorder(),
                  helperText: selectedOutstanding > 0
                      ? 'Required: Rs. ${cashRequired.toStringAsFixed(0)}'
                      : 'Will be saved as advance',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy || selectedOutstanding <= 0
                  ? null
                  : () {
                      _amountController.text = cashRequired <= 0
                          ? ''
                          : cashRequired.toStringAsFixed(0);
                      setState(() {});
                    },
              icon: const Icon(Icons.done_all),
              label: const Text('Set Required Amount'),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<FeePaymentMethod>(
                initialValue: _method,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: FeePaymentMethod.values
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(_methodLabel(item)),
                      ),
                    )
                    .toList(),
                onChanged: busy || isAdvanceOnly
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _method = value);
                        }
                      },
              ),
            ),
            SizedBox(
              width: 230,
              child: TextFormField(
                controller: _referenceController,
                enabled: !busy && !isAdvanceOnly,
                decoration: InputDecoration(
                  labelText: _method == FeePaymentMethod.cash
                      ? 'Reference (Optional)'
                      : 'Transaction / Reference No.',
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : _pickPaymentDate,
              icon: const Icon(Icons.date_range),
              label: Text(_date(_paymentDate)),
            ),
            SizedBox(
              width: 300,
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () => _collect(
                      selectedOutstanding: selectedOutstanding,
                      availableAdvance: availableAdvance,
                    ),
              icon: Icon(
                isAdvanceOnly
                    ? Icons.savings_outlined
                    : Icons.payments_outlined,
              ),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _advanceSummaryItem(
    String label,
    double amount,
    IconData icon, {
    bool emphasized = false,
  }) {
    final textStyle = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700);

    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text('Rs. ${amount.toStringAsFixed(0)}', style: textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _additionalDuesCard(
    List<StudentAdditionalChargeDueEntity> dues,
    double selectedOutstanding,
    bool busy,
  ) {
    if (dues.isEmpty) {
      return const Card(
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            child: Icon(Icons.check_circle_outline, size: 20),
          ),
          title: Text('No Additional Charges'),
          subtitle: Text('This student has no outstanding additional dues.'),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Additional Charge Dues',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    'Combined selected: Rs. ${selectedOutstanding.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (dues.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text('No outstanding additional charges.'),
            )
          else
            for (final due in dues)
              CheckboxListTile(
                value: _selectedAdditionalDueIds.contains(due.id),
                title: Text(due.chargeTitle),
                subtitle: Text(
                  '${_label(due.chargeCategory.name)} | Due ${_date(due.dueDate)} | '
                  'Net Rs. ${due.netPayable.toStringAsFixed(0)} | '
                  'Paid Rs. ${due.paidAmount.toStringAsFixed(0)} | '
                  'Outstanding Rs. ${due.outstandingAmount.toStringAsFixed(0)}',
                ),
                secondary: Chip(label: Text(due.status.name.toUpperCase())),
                onChanged: busy
                    ? null
                    : (selected) => setState(() {
                        selected == true
                            ? _selectedAdditionalDueIds.add(due.id)
                            : _selectedAdditionalDueIds.remove(due.id);
                      }),
              ),
        ],
      ),
    );
  }

  Widget _paymentHistory(List<FeePaymentEntity> payments, bool busy) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Payment History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const Divider(height: 1),
          if (payments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(22),
              child: Text('No payment history.'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Receipt')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Paid')),
                  DataColumn(label: Text('Allocated')),
                  DataColumn(label: Text('Advance Added')),
                  DataColumn(label: Text('Advance Used')),
                  DataColumn(label: Text('Reference')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Action')),
                ],
                rows: [
                  for (final payment in payments)
                    DataRow(
                      cells: [
                        DataCell(Text(payment.receiptNumber)),
                        DataCell(Text(_date(payment.paymentDate))),
                        DataCell(Text(_methodLabel(payment.method))),
                        DataCell(
                          Text('Rs. ${payment.totalPaid.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text(
                            'Rs. ${payment.allocatedAmount.toStringAsFixed(0)}',
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rs. ${payment.advanceAmount.toStringAsFixed(0)}',
                          ),
                        ),
                        DataCell(
                          Text('Rs. ${payment.advanceUsed.toStringAsFixed(0)}'),
                        ),
                        DataCell(Text(payment.referenceNumber)),
                        DataCell(Text(payment.status.name.toUpperCase())),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Preview receipt',
                                onPressed:
                                    payment.status == FeePaymentStatus.cancelled
                                    ? null
                                    : () => _previewReceipt(payment),
                                icon: const Icon(Icons.visibility_outlined),
                              ),
                              IconButton(
                                tooltip: 'Print receipt',
                                onPressed:
                                    payment.status == FeePaymentStatus.cancelled
                                    ? null
                                    : () => context.read<FeeDocumentBloc>().add(
                                        PrintFeeReceipt(
                                          FeeReceiptDocumentRequest(
                                            payment: payment,
                                          ),
                                        ),
                                      ),
                                icon: const Icon(Icons.print_outlined),
                              ),
                              IconButton(
                                tooltip: 'Share receipt PDF',
                                onPressed:
                                    payment.status == FeePaymentStatus.cancelled
                                    ? null
                                    : () => context.read<FeeDocumentBloc>().add(
                                        ShareFeeReceipt(
                                          FeeReceiptDocumentRequest(
                                            payment: payment,
                                          ),
                                        ),
                                      ),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                              ),
                              IconButton(
                                tooltip: 'Cancel payment',
                                onPressed:
                                    busy ||
                                        payment.status ==
                                            FeePaymentStatus.cancelled
                                    ? null
                                    : () => _cancelPayment(payment),
                                icon: const Icon(Icons.cancel_outlined),
                              ),
                            ],
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

  Future<void> _openStudentLedger(
    List<MonthlyFeeDueEntity> dues,
    List<StudentAdditionalChargeDueEntity> additionalDues,
    List<FeePaymentEntity> payments,
  ) async {
    final now = DateTime.now();
    var fromMonth = 1;
    var fromYear = now.year;
    var toMonth = now.month;
    var toYear = now.year;

    final period = await showDialog<_LedgerPeriod>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Student Ledger Duration'),
          content: SizedBox(
            width: 520,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ledgerMonthField(
                  label: 'From Month',
                  value: fromMonth,
                  changed: (value) => setDialogState(() => fromMonth = value),
                ),
                _ledgerYearField(
                  label: 'From Year',
                  value: fromYear,
                  changed: (value) => setDialogState(() => fromYear = value),
                ),
                _ledgerMonthField(
                  label: 'To Month',
                  value: toMonth,
                  changed: (value) => setDialogState(() => toMonth = value),
                ),
                _ledgerYearField(
                  label: 'To Year',
                  value: toYear,
                  changed: (value) => setDialogState(() => toYear = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                final from = DateTime(fromYear, fromMonth);
                final to = DateTime(toYear, toMonth);
                if (from.isAfter(to)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('From month must be before To month.'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext, _LedgerPeriod(from: from, to: to));
              },
              icon: const Icon(Icons.summarize_outlined),
              label: const Text('Generate Ledger'),
            ),
          ],
        ),
      ),
    );

    if (period == null || !mounted) return;

    List<StoreSaleEntity> storeSales = const [];
    try {
      final storeRepository = sl<StorePaymentRepository>();
      storeSales = await storeRepository.getSales();
    } catch (_) {
      // Fee ledger remains available if the optional school-store data fails.
    }

    if (!mounted) return;
    _showStudentLedger(
      period: period,
      dues: dues,
      additionalDues: additionalDues,
      payments: payments,
      storeSales: storeSales,
    );
  }

  Widget _ledgerMonthField({
    required String label,
    required int value,
    required ValueChanged<int> changed,
  }) => SizedBox(
    width: 230,
    child: DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (var month = 1; month <= 12; month++)
          DropdownMenuItem(value: month, child: Text(_monthName(month))),
      ],
      onChanged: (next) {
        if (next != null) changed(next);
      },
    ),
  );

  Widget _ledgerYearField({
    required String label,
    required int value,
    required ValueChanged<int> changed,
  }) => SizedBox(
    width: 230,
    child: DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        for (
          var year = DateTime.now().year - 5;
          year <= DateTime.now().year + 2;
          year++
        )
          DropdownMenuItem(value: year, child: Text('$year')),
      ],
      onChanged: (next) {
        if (next != null) changed(next);
      },
    ),
  );

  void _showStudentLedger({
    required _LedgerPeriod period,
    required List<MonthlyFeeDueEntity> dues,
    required List<StudentAdditionalChargeDueEntity> additionalDues,
    required List<FeePaymentEntity> payments,
    required List<StoreSaleEntity> storeSales,
  }) {
    final student = _selectedStudent!;
    final periodStart = DateTime(period.from.year, period.from.month);
    final periodEndExclusive = DateTime(period.to.year, period.to.month + 1);

    bool beforePeriod(DateTime date) => date.isBefore(periodStart);

    bool inPeriod(DateTime date) =>
        !date.isBefore(periodStart) && date.isBefore(periodEndExclusive);

    final activeMonthlyDues = dues
        .where((due) => due.status != MonthlyFeeDueStatus.cancelled)
        .toList(growable: false);

    final activeAdditionalDues = additionalDues
        .where(
          (due) => due.status != StudentAdditionalChargeDueStatus.cancelled,
        )
        .toList(growable: false);

    final completedPayments = payments
        .where((payment) => payment.status == FeePaymentStatus.completed)
        .toList(growable: false);

    final studentStoreSales = storeSales
        .where((sale) => sale.studentId == student.id)
        .toList(growable: false);

    var openingReceivable = 0.0;
    var openingAdvance = 0.0;

    for (final due in activeMonthlyDues) {
      final date = DateTime(due.year, due.month);
      if (beforePeriod(date)) {
        openingReceivable += due.netPayable;
      }
    }

    for (final due in activeAdditionalDues) {
      if (beforePeriod(due.dueDate)) {
        openingReceivable += due.netPayable;
      }
    }

    for (final sale in studentStoreSales) {
      if (beforePeriod(sale.saleDate)) {
        openingReceivable += sale.netAmount - sale.paidAmount;
      }
    }

    for (final payment in completedPayments) {
      if (!beforePeriod(payment.paymentDate)) continue;

      openingReceivable -= payment.allocatedAmount;
      openingAdvance += payment.advanceAmount - payment.advanceUsed;
    }

    if (openingReceivable < 0) {
      openingReceivable = 0;
    }
    if (openingAdvance < 0) {
      openingAdvance = 0;
    }

    final transactions = <_LedgerTransaction>[];

    for (final due in activeMonthlyDues) {
      final date = DateTime(due.year, due.month);
      if (!inPeriod(date)) continue;

      transactions.add(
        _LedgerTransaction(
          date: date,
          description: '${_monthName(due.month)} ${due.year} Monthly Fee',
          debit: due.netPayable,
          credit: 0,
          advanceChange: 0,
          sortOrder: 10,
        ),
      );
    }

    for (final due in activeAdditionalDues) {
      if (!inPeriod(due.dueDate)) continue;

      transactions.add(
        _LedgerTransaction(
          date: due.dueDate,
          description: 'Additional Charge - ${due.chargeTitle}',
          debit: due.netPayable,
          credit: 0,
          advanceChange: 0,
          sortOrder: 20,
        ),
      );
    }

    for (final sale in studentStoreSales) {
      if (!inPeriod(sale.saleDate)) continue;

      transactions.add(
        _LedgerTransaction(
          date: sale.saleDate,
          description: 'School Store Sale',
          debit: sale.netAmount,
          credit: 0,
          advanceChange: 0,
          sortOrder: 30,
        ),
      );

      if (sale.paidAmount > 0) {
        transactions.add(
          _LedgerTransaction(
            date: sale.saleDate,
            description: 'School Store Payment',
            debit: 0,
            credit: sale.paidAmount,
            advanceChange: 0,
            sortOrder: 31,
          ),
        );
      }
    }

    for (final payment in completedPayments) {
      if (!inPeriod(payment.paymentDate)) continue;

      final advanceApplied = payment.advanceUsed > payment.allocatedAmount
          ? payment.allocatedAmount
          : payment.advanceUsed;

      final cashApplied = payment.allocatedAmount - advanceApplied;

      if (cashApplied > 0) {
        transactions.add(
          _LedgerTransaction(
            date: payment.paymentDate,
            description:
                'Fee Payment - ${payment.receiptNumber} (${_methodLabel(payment.method)})',
            debit: 0,
            credit: cashApplied,
            advanceChange: 0,
            sortOrder: 40,
          ),
        );
      }

      if (advanceApplied > 0) {
        transactions.add(
          _LedgerTransaction(
            date: payment.paymentDate,
            description: 'Advance Used - ${payment.receiptNumber}',
            debit: 0,
            credit: advanceApplied,
            advanceChange: -advanceApplied,
            sortOrder: 41,
          ),
        );
      }

      if (payment.advanceAmount > 0) {
        transactions.add(
          _LedgerTransaction(
            date: payment.paymentDate,
            description: 'Advance Added - ${payment.receiptNumber}',
            debit: 0,
            credit: 0,
            advanceChange: payment.advanceAmount,
            sortOrder: 42,
          ),
        );
      }
    }

    transactions.sort((a, b) {
      final date = a.date.compareTo(b.date);
      if (date != 0) return date;
      return a.sortOrder.compareTo(b.sortOrder);
    });

    var receivableBalance = openingReceivable;
    var advanceBalance = openingAdvance;
    var periodDebit = 0.0;
    var periodCredit = 0.0;
    var periodAdvanceCreated = 0.0;
    var periodAdvanceUsed = 0.0;

    final rows = <_LedgerDisplayRow>[];

    if (openingReceivable > 0 || openingAdvance > 0) {
      rows.add(
        _LedgerDisplayRow(
          dateLabel: 'Opening',
          description: 'Opening Balances',
          debit: 0,
          credit: 0,
          receivableBalance: openingReceivable,
          advanceBalance: openingAdvance,
        ),
      );
    }

    for (final transaction in transactions) {
      receivableBalance += transaction.debit - transaction.credit;
      advanceBalance += transaction.advanceChange;

      if (receivableBalance < 0) receivableBalance = 0;
      if (advanceBalance < 0) advanceBalance = 0;

      periodDebit += transaction.debit;
      periodCredit += transaction.credit;

      if (transaction.advanceChange > 0) {
        periodAdvanceCreated += transaction.advanceChange;
      } else if (transaction.advanceChange < 0) {
        periodAdvanceUsed += -transaction.advanceChange;
      }

      rows.add(
        _LedgerDisplayRow(
          dateLabel: _date(transaction.date),
          description: transaction.description,
          debit: transaction.debit,
          credit: transaction.credit,
          receivableBalance: receivableBalance,
          advanceBalance: advanceBalance,
        ),
      );
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${student.fullName} - Student Ledger'),
        content: SizedBox(
          width: 1050,
          height: 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_monthName(period.from.month)} ${period.from.year} to '
                '${_monthName(period.to.month)} ${period.to.year}',
              ),
              const SizedBox(height: 12),
              Expanded(
                child: rows.isEmpty
                    ? const Center(
                        child: Text(
                          'No ledger transactions found for this duration.',
                        ),
                      )
                    : Scrollbar(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Description')),
                                DataColumn(
                                  label: Text('New Charges'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text('Payment Received'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text('Amount Due'),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text('Advance Available'),
                                  numeric: true,
                                ),
                              ],
                              rows: [
                                for (final row in rows)
                                  DataRow(
                                    cells: [
                                      DataCell(Text(row.dateLabel)),
                                      DataCell(
                                        SizedBox(
                                          width: 310,
                                          child: Text(row.description),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row.debit <= 0
                                              ? '-'
                                              : 'Rs. ${row.debit.toStringAsFixed(0)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          row.credit <= 0
                                              ? '-'
                                              : 'Rs. ${row.credit.toStringAsFixed(0)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          'Rs. ${row.receivableBalance.toStringAsFixed(0)}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          'Rs. ${row.advanceBalance.toStringAsFixed(0)}',
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
              const Divider(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      'Previous Due: Rs. '
                      '${openingReceivable.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Total New Charges: Rs. ${periodDebit.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Total Payments: Rs. ${periodCredit.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Total Amount Due: Rs. '
                      '${receivableBalance.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Advance Added: Rs. '
                      '${periodAdvanceCreated.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Advance Used: Rs. '
                      '${periodAdvanceUsed.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Available Advance: Rs. '
                      '${advanceBalance.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _methodLabel(FeePaymentMethod method) => switch (method) {
    FeePaymentMethod.cash => 'Cash',
    FeePaymentMethod.bankTransfer => 'Bank Transfer',
    FeePaymentMethod.easypaisa => 'Easypaisa',
    FeePaymentMethod.jazzCash => 'JazzCash',
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

  static String _label(String value) => value
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim();
}

class _LedgerPeriod {
  const _LedgerPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

class _LedgerTransaction {
  const _LedgerTransaction({
    required this.date,
    required this.description,
    required this.debit,
    required this.credit,
    required this.advanceChange,
    required this.sortOrder,
  });

  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double advanceChange;
  final int sortOrder;
}

class _LedgerDisplayRow {
  const _LedgerDisplayRow({
    required this.dateLabel,
    required this.description,
    required this.debit,
    required this.credit,
    required this.receivableBalance,
    required this.advanceBalance,
  });

  final String dateLabel;
  final String description;
  final double debit;
  final double credit;
  final double receivableBalance;
  final double advanceBalance;
}
