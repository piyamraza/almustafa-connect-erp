import 'package:flutter/material.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/additional_charge_repository.dart';
import '../../domain/repositories/student_additional_charge_due_repository.dart';

enum AdditionalChargeReportType {
  collection,
  pending,
  chargeWiseSummary,
  studentLedger,
  waived,
}

class AdditionalChargeReportsPage extends StatefulWidget {
  const AdditionalChargeReportsPage({super.key});
  @override
  State<AdditionalChargeReportsPage> createState() =>
      _AdditionalChargeReportsPageState();
}

class _AdditionalChargeReportsPageState
    extends State<AdditionalChargeReportsPage> {
  final _session = TextEditingController(text: _currentSession());
  AdditionalChargeReportType _type = AdditionalChargeReportType.collection;
  String? _chargeId, _classId, _sectionId;
  StudentAdditionalChargeDueStatus? _status;
  DateTime _from = DateTime(DateTime.now().year, 1, 1), _to = DateTime.now();
  List<AdditionalChargeEntity> _charges = const [];
  List<StudentAdditionalChargeDueEntity> _dues = const [];
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final c = await sl<AdditionalChargeRepository>().getCharges(
        academicSession: _session.text.trim(),
      );
      final d = await sl<StudentAdditionalChargeDueRepository>().getDues(
        academicSession: _session.text.trim(),
      );
      if (mounted) {
        setState(() {
          _charges = c;
          _dues = d;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<StudentAdditionalChargeDueEntity> get _filtered => _dues.where((d) {
    final date = DateTime(d.dueDate.year, d.dueDate.month, d.dueDate.day);
    return (_chargeId == null || d.chargeId == _chargeId) &&
        (_classId == null || d.classId == _classId) &&
        (_sectionId == null || d.sectionId == _sectionId) &&
        (_status == null || d.status == _status) &&
        !date.isBefore(_from) &&
        !date.isAfter(DateTime(_to.year, _to.month, _to.day, 23, 59, 59)) &&
        switch (_type) {
          AdditionalChargeReportType.collection => d.paidAmount > 0,
          AdditionalChargeReportType.pending => d.outstandingAmount > 0,
          AdditionalChargeReportType.waived =>
            d.waivedAmount > 0 ||
                d.status == StudentAdditionalChargeDueStatus.waived,
          _ => true,
        };
  }).toList();
  @override
  Widget build(BuildContext context) {
    final data = _filtered;
    final demand = data.fold<double>(0, (s, d) => s + d.netPayable);
    final paid = data.fold<double>(0, (s, d) => s + d.paidAmount);
    final pending = data.fold<double>(0, (s, d) => s + d.outstandingAmount);
    final waived = data.fold<double>(0, (s, d) => s + d.waivedAmount);
    return Scaffold(
      appBar: AppBar(title: const Text('Additional Charges Reports')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 170,
                      child: TextField(
                        controller: _session,
                        decoration: const InputDecoration(
                          labelText: 'Academic Session',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    _drop<AdditionalChargeReportType>(
                      'Report',
                      _type,
                      AdditionalChargeReportType.values,
                      (v) => setState(() => _type = v!),
                    ),
                    _drop<String>(
                      'Charge',
                      _chargeId,
                      _charges.map((c) => c.id).toList(),
                      (v) => setState(() => _chargeId = v),
                      names: {for (final c in _charges) c.id: c.title},
                    ),
                    _textFilter(
                      'Class',
                      _classId,
                      (v) => setState(() => _classId = v),
                    ),
                    _textFilter(
                      'Section',
                      _sectionId,
                      (v) => setState(() => _sectionId = v),
                    ),
                    _drop<StudentAdditionalChargeDueStatus>(
                      'Status',
                      _status,
                      StudentAdditionalChargeDueStatus.values,
                      (v) => setState(() => _status = v),
                    ),
                    OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text('From ${_date(_from)}'),
                    ),
                    OutlinedButton(
                      onPressed: () => _pick(false),
                      child: Text('To ${_date(_to)}'),
                    ),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Load'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  children: [
                    Chip(label: Text('Records: ${data.length}')),
                    Chip(
                      label: Text('Demand: Rs. ${demand.toStringAsFixed(0)}'),
                    ),
                    Chip(label: Text('Paid: Rs. ${paid.toStringAsFixed(0)}')),
                    Chip(
                      label: Text('Pending: Rs. ${pending.toStringAsFixed(0)}'),
                    ),
                    Chip(
                      label: Text('Waived: Rs. ${waived.toStringAsFixed(0)}'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Charge')),
                        DataColumn(label: Text('Student')),
                        DataColumn(label: Text('Admission')),
                        DataColumn(label: Text('Class')),
                        DataColumn(label: Text('Section')),
                        DataColumn(label: Text('Due')),
                        DataColumn(label: Text('Net')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Pending')),
                        DataColumn(label: Text('Waived')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: data
                          .map(
                            (d) => DataRow(
                              cells: [
                                DataCell(Text(d.chargeTitle)),
                                DataCell(Text(d.studentName)),
                                DataCell(Text(d.admissionNo)),
                                DataCell(Text(d.classId)),
                                DataCell(Text(d.sectionId)),
                                DataCell(Text(_date(d.dueDate))),
                                DataCell(Text(d.netPayable.toStringAsFixed(0))),
                                DataCell(Text(d.paidAmount.toStringAsFixed(0))),
                                DataCell(
                                  Text(d.outstandingAmount.toStringAsFixed(0)),
                                ),
                                DataCell(
                                  Text(d.waivedAmount.toStringAsFixed(0)),
                                ),
                                DataCell(Text(_label(d.status.name))),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Widget _drop<T>(
    String label,
    T? value,
    List<T> values,
    ValueChanged<T?> changed, {
    Map<T, String>? names,
  }) => SizedBox(
    width: 210,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        if (value == null)
          DropdownMenuItem<T>(value: null, child: const Text('All')),
        ...values.map(
          (v) => DropdownMenuItem(
            value: v,
            child: Text(names?[v] ?? _label((v as dynamic).name as String)),
          ),
        ),
      ],
      onChanged: changed,
    ),
  );
  Widget _textFilter(
    String label,
    String? value,
    ValueChanged<String?> changed,
  ) => SizedBox(
    width: 150,
    child: TextField(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => changed(v.trim().isEmpty ? null : v.trim()),
    ),
  );
  Future<void> _pick(bool from) async {
    final d = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => from ? _from = d : _to = d);
  }

  static String _currentSession() {
    final n = DateTime.now(), y = n.month >= 7 ? n.year : n.year - 1;
    return '$y-${y + 1}';
  }

  static String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';
  static String _label(String v) =>
      v.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').trim();
}
