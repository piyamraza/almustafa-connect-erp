import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../bloc/fee_collection_bloc.dart';
import '../bloc/fee_document_bloc.dart';

import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';

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
            ..sort((a, b) => a.name.compareTo(b.name));

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
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
      _show(error.toString());
    }
  }

  void _selectStudent(StudentEntity student) {
    setState(() {
      _selectedStudent = student;
      _selectedDueIds.clear();
      _selectedAdditionalDueIds.clear();
      _amountController.clear();
    });

    context.read<FeeCollectionBloc>().add(
      LoadFeeCollectionData(
        academicSession: _sessionController.text.trim(),
        studentId: student.id,
      ),
    );
  }

  String _normal(String value) => value.trim().toLowerCase();

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

    final value = _normal(student.classId);
    return value == _normal(selected.id) || value == _normal(selected.name);
  }

  bool _matchesSection(StudentEntity student) {
    final selected = _selectedSection;
    if (selected == null) return false;

    final value = _normal(student.sectionId);
    return value == _normal(selected.id) || value == _normal(selected.name);
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
    final value = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (value != null) setState(() => _paymentDate = value);
  }

  void _collect() {
    final student = _selectedStudent;
    if (student == null) {
      _show('Select a student.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _show('Enter a valid payment amount.');
      return;
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

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fee Collection')),
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

            return Stack(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 340,
                      child: Card(
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedClassId,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: '1. Select Class',
                                      prefixIcon: Icon(Icons.school_outlined),
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
                                        : (value) {
                                            setState(() {
                                              _selectedClassId = value;
                                              _selectedSectionId = null;
                                              _selectedStudent = null;
                                              _selectedDueIds.clear();
                                              _selectedAdditionalDueIds.clear();
                                              _searchController.clear();
                                              _query = '';
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        _availableSections.any(
                                          (item) =>
                                              item.id == _selectedSectionId,
                                        )
                                        ? _selectedSectionId
                                        : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: '2. Select Section',
                                      prefixIcon: Icon(
                                        Icons.view_list_outlined,
                                      ),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _availableSections
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item.id,
                                            child: Text(item.name),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: busy || _selectedClassId == null
                                        ? null
                                        : (value) {
                                            setState(() {
                                              _selectedSectionId = value;
                                              _selectedStudent = null;
                                              _selectedDueIds.clear();
                                              _selectedAdditionalDueIds.clear();
                                              _searchController.clear();
                                              _query = '';
                                            });
                                          },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _searchController,
                                    enabled: _selectedSectionId != null,
                                    onChanged: (value) =>
                                        setState(() => _query = value),
                                    decoration: const InputDecoration(
                                      labelText: '3. Search selected section',
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
                                      itemCount: _visibleStudents.length,
                                      itemBuilder: (context, index) {
                                        final student = _visibleStudents[index];
                                        final name = student.fullName.trim();
                                        return ListTile(
                                          selected:
                                              _selectedStudent?.id ==
                                              student.id,
                                          selectedTileColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: .35),
                                          leading: CircleAvatar(
                                            child: Text(
                                              name.isEmpty
                                                  ? '?'
                                                  : name[0].toUpperCase(),
                                            ),
                                          ),
                                          title: Text(student.fullName),
                                          subtitle: Text(
                                            '${student.admissionNo}\n'
                                            'Roll: '
                                            '${student.rollNumber.isEmpty ? '-' : student.rollNumber}',
                                          ),
                                          isThreeLine: true,
                                          trailing:
                                              _selectedStudent?.id == student.id
                                              ? const Icon(Icons.check_circle)
                                              : null,
                                          onTap: busy
                                              ? null
                                              : () => _selectStudent(student),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _selectedStudent == null
                          ? const Center(
                              child: Text('Select a student to collect fee.'),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(0, 16, 16, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _studentHeader(),
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

  Widget _studentHeader() {
    final student = _selectedStudent!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            Text(
              student.fullName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Chip(label: Text(student.admissionNo)),
            Chip(label: Text('Roll ${student.rollNumber}')),
            Chip(label: Text(student.guardianPhone)),
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
                      'Net Rs. ${due.netPayable.toStringAsFixed(0)} • '
                      'Paid Rs. ${due.paidAmount.toStringAsFixed(0)} • '
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
    bool busy,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixText: 'Rs. ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy || selectedOutstanding <= 0
                  ? null
                  : () {
                      _amountController.text = selectedOutstanding
                          .toStringAsFixed(0);
                    },
              icon: const Icon(Icons.done_all),
              label: const Text('Pay Selected Full'),
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
                onChanged: busy
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
              onPressed:
                  busy ||
                      (_selectedDueIds.isEmpty &&
                          _selectedAdditionalDueIds.isEmpty)
                  ? null
                  : _collect,
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Collect Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _additionalDuesCard(
    List<StudentAdditionalChargeDueEntity> dues,
    double selectedOutstanding,
    bool busy,
  ) {
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
                  '${_label(due.chargeCategory.name)} • Due ${_date(due.dueDate)} • '
                  'Net Rs. ${due.netPayable.toStringAsFixed(0)} • '
                  'Paid Rs. ${due.paidAmount.toStringAsFixed(0)} • '
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
                  DataColumn(label: Text('Advance')),
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
                        DataCell(Text(payment.referenceNumber)),
                        DataCell(Text(payment.status.name.toUpperCase())),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
