import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../fees/domain/entities/student_additional_charge_due_entity.dart';
import '../../../fees/domain/repositories/monthly_fee_due_repository.dart';
import '../../../fees/domain/repositories/student_additional_charge_due_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/services/whatsapp_contact_export_service.dart';

class WhatsAppContactListsPage extends StatefulWidget {
  const WhatsAppContactListsPage({super.key});

  @override
  State<WhatsAppContactListsPage> createState() =>
      _WhatsAppContactListsPageState();
}

class _WhatsAppContactListsPageState
    extends State<WhatsAppContactListsPage> {
  final _exporter = const WhatsAppContactExportService();
  final _searchController = TextEditingController();
  List<StudentEntity> _students = const [];
  List<MonthlyFeeDueEntity> _dues = const [];
  List<StudentAdditionalChargeDueEntity> _additionalDues = const [];
  final Set<String> _selectedStudentIds = {};
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  Map<String, double> get _pendingByStudent {
    final result = <String, double>{};
    for (final due in _dues.where((item) => item.outstandingAmount > 0)) {
      result.update(
        due.studentId,
        (value) => value + due.outstandingAmount,
        ifAbsent: () => due.outstandingAmount,
      );
    }
    for (final due in _additionalDues.where(
      (item) => item.outstandingAmount > 0,
    )) {
      result.update(
        due.studentId,
        (value) => value + due.outstandingAmount,
        ifAbsent: () => due.outstandingAmount,
      );
    }
    return result;
  }

  List<StudentEntity> get _pendingStudents {
    final pending = _pendingByStudent;
    final query = _searchController.text.trim().toLowerCase();
    final values = _students.where((student) {
      if (!student.isActive || !pending.containsKey(student.id)) return false;
      if (query.isEmpty) return true;
      return student.fullName.toLowerCase().contains(query) ||
          student.admissionNo.toLowerCase().contains(query) ||
          student.classId.toLowerCase().contains(query);
    }).toList();
    values.sort((a, b) => a.fullName.compareTo(b.fullName));
    return values;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        sl<StudentRepository>().getStudents(),
        sl<MonthlyFeeDueRepository>().getMonthlyDues(),
        sl<StudentAdditionalChargeDueRepository>().getDues(),
      ]);
      if (!mounted) return;
      setState(() {
        _students = values[0] as List<StudentEntity>;
        _dues = values[1] as List<MonthlyFeeDueEntity>;
        _additionalDues =
            values[2] as List<StudentAdditionalChargeDueEntity>;
        _selectedStudentIds.removeWhere(
          (id) => !_students.any((student) => student.id == id),
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _export({required bool wholeSchool}) async {
    final students = wholeSchool
        ? _students.where((student) => student.isActive)
        : _students.where(
            (student) => _selectedStudentIds.contains(student.id),
          );
    setState(() => _exporting = true);
    try {
      final result = await _exporter.exportVCardBatches(
        contacts: _exporter.contactsFromStudents(students),
        filePrefix: wholeSchool
            ? 'AlMustafa_School_Broadcast'
            : 'AlMustafa_Pending_Fee',
      );
      if (!mounted) return;
      final message = result.filesCreated == 0
          ? 'No valid WhatsApp numbers were found.'
          : '${result.uniqueContacts} unique contacts exported in '
                '${result.filesCreated} file(s). '
                '${result.duplicatesRemoved} duplicate(s) removed and '
                '${result.missingNumbers} missing/invalid number(s) skipped.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact export failed: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WhatsApp Contact Lists'),
          actions: [
            IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
            const DashboardNavigationButton(),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Whole School', icon: Icon(Icons.school_outlined)),
              Tab(text: 'Pending Fee', icon: Icon(Icons.payments_outlined)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!))
            : TabBarView(children: [_wholeSchoolTab(), _pendingFeeTab()]),
      ),
    );
  }

  Widget _wholeSchoolTab() {
    final active = _students.where((student) => student.isActive).toList();
    final withNumbers = active
        .where((student) => student.preferredWhatsAppNumber.isNotEmpty)
        .length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Whole-school broadcast contacts', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text('${active.length} active students • $withNumbers with a parent WhatsApp number'),
                const SizedBox(height: 8),
                const Text('Duplicate parent numbers are removed and contacts are split into batches of 250. Import each VCF file on the phone, then create the WhatsApp broadcast list manually.'),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _exporting ? null : () => _export(wholeSchool: true),
                  icon: const Icon(Icons.contact_page_outlined),
                  label: const Text('Export Whole School VCF'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pendingFeeTab() {
    final students = _pendingStudents;
    final selectableIds = students
        .where((student) => student.preferredWhatsAppNumber.isNotEmpty)
        .map((student) => student.id)
        .toSet();
    final selectedVisible = selectableIds.where(_selectedStudentIds.contains).length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search student, admission no. or class',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: selectableIds.isEmpty
                        ? null
                        : () => setState(() => _selectedStudentIds.addAll(selectableIds)),
                    icon: const Icon(Icons.select_all),
                    label: const Text('Mark All'),
                  ),
                  OutlinedButton.icon(
                    onPressed: selectedVisible == 0
                        ? null
                        : () => setState(() => _selectedStudentIds.removeAll(selectableIds)),
                    icon: const Icon(Icons.deselect),
                    label: const Text('Unmark All'),
                  ),
                  Chip(label: Text('${_selectedStudentIds.length} selected')),
                  FilledButton.icon(
                    onPressed: _exporting || _selectedStudentIds.isEmpty
                        ? null
                        : () => _export(wholeSchool: false),
                    icon: const Icon(Icons.contact_page_outlined),
                    label: const Text('Export Selected VCF'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? const Center(child: Text('No pending-fee students found.'))
              : ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final phone = student.preferredWhatsAppNumber;
                    final enabled = phone.isNotEmpty;
                    return CheckboxListTile(
                      value: _selectedStudentIds.contains(student.id),
                      onChanged: !enabled
                          ? null
                          : (checked) => setState(() {
                              if (checked == true) {
                                _selectedStudentIds.add(student.id);
                              } else {
                                _selectedStudentIds.remove(student.id);
                              }
                            }),
                      title: Text('${student.fullName} • ${student.admissionNo}'),
                      subtitle: Text(
                        '${student.classId}${student.sectionId.isEmpty ? '' : ' / ${student.sectionId}'} '
                        '• Pending Rs. ${(_pendingByStudent[student.id] ?? 0).toStringAsFixed(0)}\n'
                        '${enabled ? '${student.preferredWhatsAppContactName}: $phone' : 'WhatsApp number missing'}',
                      ),
                      secondary: Icon(enabled ? Icons.chat_outlined : Icons.phone_disabled_outlined),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
