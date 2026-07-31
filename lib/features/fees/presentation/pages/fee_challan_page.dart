import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../bloc/fee_document_bloc.dart';

class FeeChallanPage extends StatelessWidget {
  const FeeChallanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeeDocumentBloc>(
      create: (_) => sl<FeeDocumentBloc>(),
      child: const _FeeChallanView(),
    );
  }
}

class _FeeChallanView extends StatefulWidget {
  const _FeeChallanView();

  @override
  State<_FeeChallanView> createState() => _FeeChallanViewState();
}

class _FeeChallanViewState extends State<_FeeChallanView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  int _copyCount = 3;
  List<MonthlyFeeDueEntity> _dues = const [];
  final Set<String> _selectedDueIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final values = await sl<MonthlyFeeDueRepository>().getMonthlyDues(
        academicSession: _sessionController.text.trim(),
        month: _month,
        year: _year,
      );

      if (!mounted) return;

      final printable = values
          .where(
            (item) =>
                item.status != MonthlyFeeDueStatus.cancelled &&
                item.outstandingAmount > 0,
          )
          .toList();

      setState(() {
        _dues = printable;
        _selectedDueIds
          ..clear()
          ..addAll(printable.map((item) => item.id));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('StateError: ', '');
      });
    }
  }

  List<MonthlyFeeDueEntity> get _selectedDues => _dues
      .where((item) => _selectedDueIds.contains(item.id))
      .toList(growable: false);

  void _print(bool share) {
    if (_selectedDues.isEmpty) {
      _show('Select at least one challan.');
      return;
    }

    final request = FeeChallanDocumentRequest(
      dues: _selectedDues,
      copyCount: _copyCount,
    );

    context.read<FeeDocumentBloc>().add(
      share ? ShareFeeChallan(request) : PrintFeeChallan(request),
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
      appBar: AppBar(title: const Text('Fee Challans')),
      body: SafeArea(
        child: BlocConsumer<FeeDocumentBloc, FeeDocumentState>(
          listener: (context, state) {
            if (state is FeeDocumentSuccess) {
              _show(state.message);
            } else if (state is FeeDocumentError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = _loading || state is FeeDocumentLoading;

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
                              SizedBox(
                                width: 160,
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
                                            _load();
                                          }
                                        },
                                ),
                              ),
                              SizedBox(
                                width: 130,
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
                                      DropdownMenuItem(
                                        value: year,
                                        child: Text('$year'),
                                      ),
                                  ],
                                  onChanged: busy
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() => _year = value);
                                            _load();
                                          }
                                        },
                                ),
                              ),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<int>(
                                  initialValue: _copyCount,
                                  decoration: const InputDecoration(
                                    labelText: 'Copies',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 1,
                                      child: Text('School Copy'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2,
                                      child: Text('School + Parent'),
                                    ),
                                    DropdownMenuItem(
                                      value: 3,
                                      child: Text('School + Parent + Bank'),
                                    ),
                                  ],
                                  onChanged: busy
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() => _copyCount = value);
                                          }
                                        },
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: busy ? null : _load,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Load'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: busy ? null : () => _print(false),
                                icon: const Icon(Icons.print_outlined),
                                label: Text('Print (${_selectedDues.length})'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: busy ? null : () => _print(true),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: const Text('Share PDF'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _error != null
                          ? Center(child: Text(_error!))
                          : _dues.isEmpty
                          ? const Center(
                              child: Text('No outstanding challans found.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _dues.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final due = _dues[index];
                                return Card(
                                  child: CheckboxListTile(
                                    value: _selectedDueIds.contains(due.id),
                                    title: Text(due.studentName),
                                    subtitle: Text(
                                      '${due.admissionNo} • '
                                      '${_monthName(due.month)} ${due.year} • '
                                      'Due ${_date(due.dueDate)}',
                                    ),
                                    secondary: Chip(
                                      label: Text(
                                        'Rs. ${due.outstandingAmount.toStringAsFixed(0)}',
                                      ),
                                    ),
                                    onChanged: busy
                                        ? null
                                        : (selected) {
                                            setState(() {
                                              selected == true
                                                  ? _selectedDueIds.add(due.id)
                                                  : _selectedDueIds.remove(
                                                      due.id,
                                                    );
                                            });
                                          },
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
