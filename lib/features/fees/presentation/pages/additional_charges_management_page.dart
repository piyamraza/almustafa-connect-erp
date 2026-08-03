import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/manual_date_picker.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/additional_charge_repository.dart';
import '../../domain/services/additional_charge_generation_service.dart';
import '../bloc/additional_charges_bloc.dart';

class AdditionalChargesManagementPage extends StatelessWidget {
  const AdditionalChargesManagementPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AdditionalChargesBloc>(),
    child: const _AdditionalChargesView(),
  );
}

class _AdditionalChargesView extends StatefulWidget {
  const _AdditionalChargesView();
  @override
  State<_AdditionalChargesView> createState() => _AdditionalChargesViewState();
}

class _AdditionalChargesViewState extends State<_AdditionalChargesView> {
  final _session = TextEditingController(text: _currentSession());
  final _search = TextEditingController();
  AdditionalChargeScope? _scope;
  AdditionalChargeCategory? _category;
  String _status = 'all';
  String _query = '';
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  List<StudentEntity> _students = const [];

  @override
  void initState() {
    super.initState();
    _loadLookups();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _session.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final values = await Future.wait([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
        sl<StudentRepository>().getStudents(),
      ]);
      if (mounted) {
        setState(() {
          _classes = values[0] as List<AcademicClassEntity>;
          _sections = values[1] as List<SectionEntity>;
          _students = values[2] as List<StudentEntity>;
        });
      }
    } catch (e) {
      if (mounted) _show('$e');
    }
  }

  void _reload() => context.read<AdditionalChargesBloc>().add(
    LoadAdditionalCharges(_session.text.trim()),
  );
  void _show(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    appBar: AppBar(
      actions: const [DashboardNavigationButton()],
      title: const Text('Additional Charges Management'),
    ),
    body: BlocConsumer<AdditionalChargesBloc, AdditionalChargesState>(
      listener: (context, state) {
        if (state is AdditionalChargesLoaded && state.message != null) {
          _show(state.message!);
        }
        if (state is AdditionalChargesError) _show(state.message);
      },
      builder: (context, state) {
        final busy = state is AdditionalChargesLoading;
        final all = state is AdditionalChargesLoaded
            ? state.charges
            : const <AdditionalChargeEntity>[];
        final charges = all.where((c) {
          final q = _query.toLowerCase();
          return (_scope == null || c.scope == _scope) &&
              (_category == null || c.category == _category) &&
              (_status == 'all' ||
                  (_status == 'active' && c.isActive) ||
                  (_status == 'inactive' && !c.isActive) ||
                  (_status == 'generated' && c.generated) ||
                  (_status == 'pending' && !c.generated)) &&
              (q.isEmpty ||
                  c.title.toLowerCase().contains(q) ||
                  c.categoryLabel.toLowerCase().contains(q));
        }).toList();
        final dues = state is AdditionalChargesLoaded
            ? state.dues
            : const <StudentAdditionalChargeDueEntity>[];
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _filters(busy),
                      const SizedBox(height: 14),
                      _summary(all, dues),
                      const SizedBox(height: 14),
                      if (state is AdditionalChargesLoaded &&
                          state.viewingCharge != null)
                        _duesPanel(state.viewingCharge!, dues)
                      else
                        _chargeList(charges, busy),
                    ],
                  ),
                ),
              ),
            ),
            if (busy) const LinearProgressIndicator(),
          ],
        );
      },
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF246BFD), Color(0xFF6C4DFF)],
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.add_card_outlined, color: Colors.white, size: 34),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Additional Charges',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Create separate school, class, section or student-specific fee dues.',
                style: TextStyle(color: Color(0xFFEAF1FF)),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF315DDC),
          ),
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Create Additional Charge'),
        ),
      ],
    ),
  );

  Widget _filters(bool busy) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Wrap(
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
          SizedBox(
            width: 240,
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          _drop<AdditionalChargeScope>(
            value: _scope,
            label: 'Scope',
            items: AdditionalChargeScope.values,
            onChanged: (v) => setState(() => _scope = v),
          ),
          _drop<AdditionalChargeCategory>(
            value: _category,
            label: 'Category',
            items: AdditionalChargeCategory.values,
            onChanged: (v) => setState(() => _category = v),
          ),
          SizedBox(
            width: 170,
            child: DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const ['all', 'active', 'inactive', 'generated', 'pending']
                  .map((v) => DropdownMenuItem(value: v, child: Text(_cap(v))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'all'),
            ),
          ),
          IconButton.filledTonal(
            onPressed: busy ? null : _reload,
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
  Widget _drop<T extends Enum>({
    required T? value,
    required String label,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) => SizedBox(
    width: 190,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<T>(value: null, child: const Text('All')),
        ...items.map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(_label(e.name), overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    ),
  );

  Widget _summary(
    List<AdditionalChargeEntity> charges,
    List<StudentAdditionalChargeDueEntity> dues,
  ) {
    final total = dues.fold<double>(0, (s, d) => s + d.netPayable);
    return LayoutBuilder(
      builder: (context, c) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: c.maxWidth < 700 ? 2 : 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.4,
        children: [
          _metric(
            'Total Charges',
            '${charges.length}',
            Icons.receipt_long,
            Colors.blue,
          ),
          _metric(
            'Active',
            '${charges.where((e) => e.isActive).length}',
            Icons.check_circle,
            Colors.green,
          ),
          _metric(
            'Generated',
            '${charges.where((e) => e.generated).length}',
            Icons.task_alt,
            Colors.teal,
          ),
          _metric(
            'Pending Generation',
            '${charges.where((e) => !e.generated).length}',
            Icons.schedule,
            Colors.orange,
          ),
          _metric(
            'Generated Amount',
            'Rs. ${total.toStringAsFixed(0)}',
            Icons.payments,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: .12),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _chargeList(List<AdditionalChargeEntity> charges, bool busy) {
    return Card(
      child: Column(
        children: [
          const ListTile(title: Text('Charge Definitions')),
          if (charges.isEmpty)
            const Padding(
              padding: EdgeInsets.all(36),
              child: Text('No additional charges match these filters.'),
            ),
          for (final charge in charges) ...[
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    (charge.generated ? Colors.green : Colors.amber).withValues(
                      alpha: .13,
                    ),
                child: Icon(
                  charge.generated ? Icons.task_alt : Icons.schedule,
                  color: charge.generated ? Colors.green : Colors.orange,
                ),
              ),
              title: Text(charge.title),
              subtitle: Text(
                '${charge.categoryLabel} • ${charge.scopeLabel} • Due ${_date(charge.dueDate)} • '
                '${charge.isActive ? 'Active' : 'Inactive'} • '
                '${charge.generated ? 'Generated (${charge.generatedStudentCount})' : 'Pending'}',
              ),
              trailing: Wrap(
                spacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Rs. ${charge.amount.toStringAsFixed(0)}'),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: busy ? null : () => _openForm(charge),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Generate',
                    onPressed: busy || !charge.isActive
                        ? null
                        : () => _confirmGenerate(charge),
                    icon: const Icon(Icons.play_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'View Generated Dues',
                    onPressed: busy
                        ? null
                        : () => context.read<AdditionalChargesBloc>().add(
                            LoadAdditionalChargeDues(charge),
                          ),
                    icon: const Icon(Icons.people_alt_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: busy ? null : () => _confirmDelete(charge),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _duesPanel(
    AdditionalChargeEntity charge,
    List<StudentAdditionalChargeDueEntity> dues,
  ) => Card(
    child: Column(
      children: [
        ListTile(
          leading: IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(
            '${charge.title} — Generated Dues',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text('${dues.length} student records'),
        ),
        const Divider(height: 1),
        if (dues.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('No generated dues.'),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Student')),
                DataColumn(label: Text('Admission')),
                DataColumn(label: Text('Due Date')),
                DataColumn(label: Text('Net')),
                DataColumn(label: Text('Paid')),
                DataColumn(label: Text('Outstanding')),
                DataColumn(label: Text('Status')),
              ],
              rows: dues
                  .map(
                    (d) => DataRow(
                      cells: [
                        DataCell(Text(d.studentName)),
                        DataCell(Text(d.admissionNo)),
                        DataCell(Text(_date(d.dueDate))),
                        DataCell(
                          Text('Rs. ${d.netPayable.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${d.paidAmount.toStringAsFixed(0)}'),
                        ),
                        DataCell(
                          Text('Rs. ${d.outstandingAmount.toStringAsFixed(0)}'),
                        ),
                        DataCell(Text(_label(d.status.name))),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );

  Future<void> _confirmGenerate(AdditionalChargeEntity charge) async {
    try {
      final estimate = await sl<AdditionalChargeGenerationService>().estimate(
        charge,
      );
      if (!mounted) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Generate Additional Charge?'),
          content: Text(
            '${charge.title}\nAmount per student: Rs. ${charge.amount.toStringAsFixed(0)}\nEligible: ${estimate.eligibleCount}\nExcluded: ${estimate.excludedCount}\nDuplicates / skipped: ${estimate.skippedCount}\nNew dues: ${estimate.generatedCount}\nEstimated total: Rs. ${estimate.totalAmountGenerated.toStringAsFixed(0)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Generate'),
            ),
          ],
        ),
      );
      if (yes == true && mounted) {
        context.read<AdditionalChargesBloc>().add(
          GenerateAdditionalCharge(charge),
        );
      }
    } catch (e) {
      _show('$e');
    }
  }

  Future<void> _confirmDelete(AdditionalChargeEntity charge) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete charge?'),
        content: const Text(
          'A charge with generated or paid dues cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      context.read<AdditionalChargesBloc>().add(DeleteAdditionalCharge(charge));
    }
  }

  Future<void> _openForm([AdditionalChargeEntity? existing]) async {
    final result = await showDialog<AdditionalChargeEntity>(
      context: context,
      builder: (c) => _ChargeFormDialog(
        existing: existing,
        session: _session.text.trim(),
        classes: _classes,
        sections: _sections,
        students: _students,
      ),
    );
    if (result != null && mounted) {
      context.read<AdditionalChargesBloc>().add(SaveAdditionalCharge(result));
    }
  }

  static String _currentSession() {
    final n = DateTime.now();
    final y = n.month >= 7 ? n.year : n.year - 1;
    return '$y-${y + 1}';
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  static String _label(String v) => v
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .trim()
      .split(' ')
      .map(_cap)
      .join(' ');
  static String _cap(String v) =>
      v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}';
}

class _ChargeFormDialog extends StatefulWidget {
  const _ChargeFormDialog({
    this.existing,
    required this.session,
    required this.classes,
    required this.sections,
    required this.students,
  });
  final AdditionalChargeEntity? existing;
  final String session;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<StudentEntity> students;
  @override
  State<_ChargeFormDialog> createState() => _ChargeFormDialogState();
}

class _ChargeFormDialogState extends State<_ChargeFormDialog> {
  final _key = GlobalKey<FormState>();
  late TextEditingController _title, _description, _custom, _amount;
  late AdditionalChargeCategory _category;
  late AdditionalChargeScope _scope;
  late AdditionalChargeFrequency _frequency;
  String? _classId, _sectionId;
  late DateTime _dueDate;
  late bool _mandatory, _refundable, _active;
  late Set<String> _selected, _excluded;
  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _description = TextEditingController(text: e?.description);
    _custom = TextEditingController(text: e?.customCategoryName);
    _amount = TextEditingController(
      text: e == null ? '' : e.amount.toStringAsFixed(0),
    );
    _category = e?.category ?? AdditionalChargeCategory.paperMoney;
    _scope = e?.scope ?? AdditionalChargeScope.entireSchool;
    _frequency = e?.frequency ?? AdditionalChargeFrequency.oneTime;
    _classId = e?.classId.isEmpty == false ? e!.classId : null;
    _sectionId = e?.sectionId.isEmpty == false ? e!.sectionId : null;
    _dueDate = e?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    _mandatory = e?.mandatory ?? true;
    _refundable = e?.refundable ?? false;
    _active = e?.isActive ?? true;
    _selected = {...?e?.selectedStudentIds};
    _excluded = {...?e?.excludedStudentIds};
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _custom.dispose();
    _amount.dispose();
    super.dispose();
  }

  List<SectionEntity> get _matchingSections => widget.sections
      .where((s) => _classId == null || s.classId == _classId)
      .toList();
  List<StudentEntity> get _filteredStudents => widget.students
      .where(
        (s) =>
            s.isActive &&
            (_classId == null ||
                s.classId == _classId ||
                widget.classes.any(
                  (c) => c.id == _classId && s.classId == c.name,
                )) &&
            (_sectionId == null ||
                s.sectionId == _sectionId ||
                widget.sections.any(
                  (x) => x.id == _sectionId && s.sectionId == x.name,
                )),
      )
      .toList();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.existing == null
          ? 'Create Additional Charge'
          : 'Edit Additional Charge',
    ),
    content: SizedBox(
      width: 850,
      child: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _field(_title, 'Title', required: true),
              _field(_description, 'Description'),
              _enumField(
                'Category',
                _category,
                AdditionalChargeCategory.values,
                (v) => setState(() => _category = v),
              ),
              if (_category == AdditionalChargeCategory.other)
                _field(_custom, 'Custom Category', required: true),
              _field(_amount, 'Amount', required: true, number: true),
              _enumField(
                'Scope',
                _scope,
                AdditionalChargeScope.values,
                (v) => setState(() {
                  _scope = v;
                  _classId = null;
                  _sectionId = null;
                  _selected.clear();
                  _excluded.clear();
                }),
              ),
              if (_scope != AdditionalChargeScope.entireSchool) _classField(),
              if (_scope == AdditionalChargeScope.sectionWise ||
                  _scope == AdditionalChargeScope.selectedStudents)
                _sectionField(),
              _enumField(
                'Frequency',
                _frequency,
                AdditionalChargeFrequency.values,
                (v) => setState(() => _frequency = v),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final d = await showManualDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _dueDate = d);
                },
                icon: const Icon(Icons.event),
                label: Text(
                  'Due: ${_AdditionalChargesViewState._date(_dueDate)}',
                ),
              ),
              if (_scope == AdditionalChargeScope.selectedStudents)
                _studentsBox('Selected Students', _selected),
              if (_scope != AdditionalChargeScope.selectedStudents)
                _studentsBox(
                  'Students to Charge',
                  _excluded,
                  exclusionMode: true,
                ),
              SwitchListTile(
                value: _mandatory,
                onChanged: (v) => setState(() => _mandatory = v),
                title: const Text('Mandatory'),
              ),
              SwitchListTile(
                value: _refundable,
                onChanged: (v) => setState(() => _refundable = v),
                title: const Text('Refundable'),
              ),
              SwitchListTile(
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save Charge')),
    ],
  );
  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
  }) => SizedBox(
    width: 260,
    child: TextFormField(
      controller: c,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? '$label is required'
          : null,
    ),
  );
  Widget _enumField<T extends Enum>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> changed,
  ) => SizedBox(
    width: 260,
    child: DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(_AdditionalChargesViewState._label(v.name)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) changed(v);
      },
    ),
  );
  Widget _classField() => SizedBox(
    width: 260,
    child: DropdownButtonFormField<String>(
      initialValue: _classId,
      decoration: const InputDecoration(
        labelText: 'Class',
        border: OutlineInputBorder(),
      ),
      items: widget.classes
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (v) => setState(() {
        _classId = v;
        _sectionId = null;
        _selected.clear();
        _excluded.clear();
      }),
      validator: (v) => v == null ? 'Class is required' : null,
    ),
  );
  Widget _sectionField() => SizedBox(
    width: 260,
    child: DropdownButtonFormField<String>(
      initialValue: _sectionId,
      decoration: InputDecoration(
        labelText: _scope == AdditionalChargeScope.sectionWise
            ? 'Section'
            : 'Section (Optional)',
        border: const OutlineInputBorder(),
      ),
      items: _matchingSections
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          .toList(),
      onChanged: (v) => setState(() {
        _sectionId = v;
        _selected.clear();
        _excluded.clear();
      }),
      validator: (v) => _scope == AdditionalChargeScope.sectionWise && v == null
          ? 'Section is required'
          : null,
    ),
  );
  Widget _studentsBox(
    String title,
    Set<String> values, {
    bool exclusionMode = false,
  }) {
    final students = _filteredStudents;
    final markedCount = exclusionMode
        ? students.where((student) => !values.contains(student.id)).length
        : students.where((student) => values.contains(student.id)).length;

    void markAll() => setState(() {
      if (exclusionMode) {
        values.removeAll(students.map((student) => student.id));
      } else {
        values.addAll(students.map((student) => student.id));
      }
    });

    void unmarkAll() => setState(() {
      if (exclusionMode) {
        values.addAll(students.map((student) => student.id));
      } else {
        values.removeAll(students.map((student) => student.id));
      }
    });

    return SizedBox(
      width: 540,
      height: 210,
      child: Card(
        color: const Color(0xFFF7F9FD),
        child: Column(
          children: [
            ListTile(
              title: Text('$title ($markedCount of ${students.length})'),
              subtitle: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton.icon(
                    onPressed:
                        students.isEmpty || markedCount == students.length
                        ? null
                        : markAll,
                    icon: const Icon(Icons.check_box_outlined, size: 18),
                    label: const Text('Mark All'),
                  ),
                  TextButton.icon(
                    onPressed: students.isEmpty || markedCount == 0
                        ? null
                        : unmarkAll,
                    icon: const Icon(
                      Icons.check_box_outline_blank,
                      size: 18,
                    ),
                    label: const Text('Unmark All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: students
                    .map(
                      (s) => CheckboxListTile(
                        dense: true,
                        value: exclusionMode
                            ? !values.contains(s.id)
                            : values.contains(s.id),
                        title: Text(s.fullName),
                        subtitle: Text(
                          'Father: ${s.fatherName.trim().isEmpty ? '-' : s.fatherName.trim()}',
                        ),
                        onChanged: (v) => setState(() {
                          if (exclusionMode) {
                            v == true
                                ? values.remove(s.id)
                                : values.add(s.id);
                          } else {
                            v == true
                                ? values.add(s.id)
                                : values.remove(s.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _save() {
    if (!_key.currentState!.validate()) return;
    if (_scope == AdditionalChargeScope.selectedStudents && _selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one student.')),
      );
      return;
    }
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    final now = DateTime.now();
    final cls = widget.classes.where((c) => c.id == _classId).firstOrNull;
    final sec = widget.sections.where((s) => s.id == _sectionId).firstOrNull;
    final old = widget.existing;
    Navigator.pop(
      context,
      AdditionalChargeEntity(
        id: old?.id ?? sl<AdditionalChargeRepository>().generateId(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        customCategoryName: _custom.text.trim(),
        academicSession: widget.session,
        amount: amount,
        scope: _scope,
        classId: _classId ?? '',
        className: cls?.name ?? '',
        sectionId: _sectionId ?? '',
        sectionName: sec?.name ?? '',
        selectedStudentIds: _selected.toList(),
        excludedStudentIds: _excluded.toList(),
        dueDate: _dueDate,
        frequency: _frequency,
        mandatory: _mandatory,
        refundable: _refundable,
        isActive: _active,
        generated: old?.generated ?? false,
        generatedStudentCount: old?.generatedStudentCount ?? 0,
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}
