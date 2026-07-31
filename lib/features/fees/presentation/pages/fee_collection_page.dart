import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../bloc/fee_collection_bloc.dart';
import '../bloc/fee_document_bloc.dart';

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
  StudentEntity? _selectedStudent;
  final Set<String> _selectedDueIds = {};
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
    try {
      final students = await sl<StudentRepository>().getStudents();
      if (!mounted) return;
      setState(() {
        _students = students.where((item) => item.isActive).toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        _loadingStudents = false;
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
      _amountController.clear();
    });

    context.read<FeeCollectionBloc>().add(
      LoadFeeCollectionData(
        academicSession: _sessionController.text.trim(),
        studentId: student.id,
      ),
    );
  }

  List<StudentEntity> get _visibleStudents {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students.where((student) {
      return student.fullName.toLowerCase().contains(query) ||
          student.admissionNo.toLowerCase().contains(query) ||
          student.rollNumber.toLowerCase().contains(query) ||
          student.guardianPhone.toLowerCase().contains(query);
    }).toList();
  }

  double _selectedOutstanding(List<MonthlyFeeDueEntity> dues) {
    return dues
        .where((item) => _selectedDueIds.contains(item.id))
        .fold<double>(0, (sum, item) => sum + item.outstandingAmount);
  }

  Future<void> _pickPaymentDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (value != null) setState(() => _paymentDate = value);
  }

  void _collect(List<MonthlyFeeDueEntity> dues) {
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
            final payableDues = dues
                .where(
                  (item) =>
                      item.status != MonthlyFeeDueStatus.paid &&
                      item.status != MonthlyFeeDueStatus.cancelled,
                )
                .toList();
            final selectedOutstanding = _selectedOutstanding(payableDues);

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
                              child: TextFormField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                decoration: const InputDecoration(
                                  labelText:
                                      'Search student / admission / mobile',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _visibleStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _visibleStudents[index];
                                  return ListTile(
                                    selected:
                                        _selectedStudent?.id == student.id,
                                    leading: CircleAvatar(
                                      child: Text(
                                        student.fullName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                      ),
                                    ),
                                    title: Text(student.fullName),
                                    subtitle: Text(student.admissionNo),
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
                                    selectedOutstanding,
                                    busy,
                                  ),
                                  const SizedBox(height: 12),
                                  _paymentForm(
                                    payableDues,
                                    selectedOutstanding,
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
              onPressed: busy || dues.isEmpty ? null : () => _collect(dues),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Collect Payment'),
            ),
          ],
        ),
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
                                        payment.status == FeePaymentStatus.cancelled
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
}
