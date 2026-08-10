import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/fee_structure_entity.dart';
import '../../domain/repositories/fee_structure_repository.dart';
import '../bloc/fee_structure_bloc.dart';

class FeeStructurePage extends StatelessWidget {
  const FeeStructurePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeeStructureBloc>(
      create: (_) =>
          sl<FeeStructureBloc>()
            ..add(const LoadFeeStructures(academicSession: '2026-2027')),
      child: const _FeeStructureView(),
    );
  }
}

class _FeeStructureView extends StatefulWidget {
  const _FeeStructureView();

  @override
  State<_FeeStructureView> createState() => _FeeStructureViewState();
}

class _FeeStructureViewState extends State<_FeeStructureView> {
  final _sessionController = TextEditingController(text: '2026-2027');
  List<AcademicClassEntity> _classes = const [];
  List<SectionEntity> _sections = const [];
  bool _loadingReferences = true;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    try {
      final values = await Future.wait<Object?>([
        sl<AcademicStructureRepository>().getClasses(),
        sl<AcademicStructureRepository>().getSections(),
      ]);

      if (!mounted) return;

      setState(() {
        _classes =
            (values[0] as List<AcademicClassEntity>)
              .where((item) => item.isActive)
              .toList()
              ..sort(compareAcademicClasses);
        _sections =
            (values[1] as List<SectionEntity>)
                .where((item) => item.isActive)
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        _loadingReferences = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingReferences = false;
        _referenceError = _message(error);
      });
    }
  }

  Future<void> _edit(FeeStructureEntity? existing) async {
    final result = await showDialog<FeeStructureEntity>(
      context: context,
      builder: (_) => _FeeStructureDialog(
        academicSession: _sessionController.text.trim(),
        classes: _classes,
        sections: _sections,
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    context.read<FeeStructureBloc>().add(SaveFeeStructure(result));
  }

  Future<void> _delete(FeeStructureEntity structure) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Fee Structure'),
            content: Text(
              'Delete fee structure for '
              '${structure.className} - ${structure.sectionName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      context.read<FeeStructureBloc>().add(DeleteFeeStructure(structure.id));
    }
  }

  void _load() {
    context.read<FeeStructureBloc>().add(
      LoadFeeStructures(academicSession: _sessionController.text.trim()),
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
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Fee Structure')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadingReferences ? null : () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Fee Structure'),
      ),
      body: SafeArea(
        child: BlocConsumer<FeeStructureBloc, FeeStructureState>(
          listener: (context, state) {
            if (state is FeeStructureLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is FeeStructureError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy = _loadingReferences || state is FeeStructureLoading;
            final values = state is FeeStructureLoaded
                ? state.structures
                : const <FeeStructureEntity>[];

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1350),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Class-wise Fee Structure',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Configure recurring monthly charges and '
                            'one-time fees for each class and section.',
                          ),
                          const SizedBox(height: 20),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 210,
                                    child: TextFormField(
                                      controller: _sessionController,
                                      decoration: const InputDecoration(
                                        labelText: 'Academic Session',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: busy ? null : _load,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Load'),
                                  ),
                                  const Chip(
                                    avatar: Icon(
                                      Icons.event_available_outlined,
                                      size: 18,
                                    ),
                                    label: Text('Default Due Day: 10'),
                                  ),
                                  const Chip(
                                    avatar: Icon(
                                      Icons.money_off_outlined,
                                      size: 18,
                                    ),
                                    label: Text('No Late Fine'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_referenceError != null)
                            _MessageCard(_referenceError!)
                          else if (values.isEmpty && !busy)
                            const _MessageCard(
                              'No fee structures configured for this session.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 1100
                                    ? 3
                                    : constraints.maxWidth >= 720
                                    ? 2
                                    : 1;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: values.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                        childAspectRatio: columns == 1
                                            ? 1.65
                                            : 1.12,
                                      ),
                                  itemBuilder: (context, index) {
                                    final structure = values[index];
                                    return _StructureCard(
                                      structure: structure,
                                      onEdit: () => _edit(structure),
                                      onDelete: () => _delete(structure),
                                    );
                                  },
                                );
                              },
                            ),
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

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}

class _StructureCard extends StatelessWidget {
  const _StructureCard({
    required this.structure,
    required this.onEdit,
    required this.onDelete,
  });

  final FeeStructureEntity structure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${structure.className} - ${structure.sectionName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Switch(
                    value: structure.isActive,
                    onChanged: (value) {
                      sl<FeeStructureRepository>().saveFeeStructure(
                        structure.copyWith(
                          isActive: value,
                          updatedAt: DateTime.now(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _amountRow('Monthly Tuition', structure.monthlyTuitionFee),
              _amountRow('Transport', structure.transportFee),
              _amountRow('Other Monthly', structure.otherMonthlyCharges),
              const Divider(),
              _amountRow(
                'Monthly Total',
                structure.recurringMonthlyTotal,
                bold: true,
              ),
              const SizedBox(height: 5),
              _amountRow('Admission Fee', structure.admissionFee),
              _amountRow('Annual Charges', structure.annualCharges),
              const Spacer(),
              Text(
                'Due Day: ${structure.dueDay} • '
                '${structure.academicSession}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
            ),
          ),
          Text(
            'Rs. ${amount.toStringAsFixed(0)}',
            style: bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
          ),
        ],
      ),
    );
  }
}

class _FeeStructureDialog extends StatefulWidget {
  const _FeeStructureDialog({
    required this.academicSession,
    required this.classes,
    required this.sections,
    this.existing,
  });

  final String academicSession;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final FeeStructureEntity? existing;

  @override
  State<_FeeStructureDialog> createState() => _FeeStructureDialogState();
}

class _FeeStructureDialogState extends State<_FeeStructureDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _classId;
  String? _sectionId;
  late TextEditingController _tuition;
  late TextEditingController _admission;
  late TextEditingController _annual;
  late TextEditingController _transport;
  late TextEditingController _other;
  late TextEditingController _dueDay;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _classId =
        existing?.classId ??
        (widget.classes.isEmpty ? null : widget.classes.first.id);
    _sectionId = existing?.sectionId ?? _firstSectionId(_classId);
    _tuition = _controller(existing?.monthlyTuitionFee);
    _admission = _controller(existing?.admissionFee);
    _annual = _controller(existing?.annualCharges);
    _transport = _controller(existing?.transportFee);
    _other = _controller(existing?.otherMonthlyCharges);
    _dueDay = TextEditingController(text: '${existing?.dueDay ?? 10}');
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _tuition.dispose();
    _admission.dispose();
    _annual.dispose();
    _transport.dispose();
    _other.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  AcademicClassEntity? get _selectedClass =>
      widget.classes.where((item) => item.id == _classId).firstOrNull;

  SectionEntity? get _selectedSection =>
      widget.sections.where((item) => item.id == _sectionId).firstOrNull;

  List<SectionEntity> get _availableSections => widget.sections
      .where((item) => item.classId == _classId)
      .toList(growable: false);

  String? _firstSectionId(String? classId) {
    for (final section in widget.sections) {
      if (section.classId == classId) return section.id;
    }
    return null;
  }

  TextEditingController _controller(double? value) {
    return TextEditingController(
      text: value == null ? '0' : value.toStringAsFixed(0),
    );
  }

  String? _moneyValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Fee Structure' : 'Edit Fee Structure',
      ),
      content: SizedBox(
        width: 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    initialValue: _classId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.classes
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: widget.existing == null
                        ? (value) {
                            setState(() {
                              _classId = value;
                              _sectionId = _firstSectionId(value);
                            });
                          }
                        : null,
                    validator: (value) =>
                        value == null ? 'Class is required' : null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sectionId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Section',
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
                    onChanged: widget.existing == null
                        ? (value) => setState(() => _sectionId = value)
                        : null,
                    validator: (value) =>
                        value == null ? 'Section is required' : null,
                  ),
                ),
                _moneyField('Monthly Tuition Fee', _tuition),
                _moneyField('Admission Fee (One Time)', _admission),
                _moneyField('Annual Charges', _annual),
                _moneyField('Monthly Transport Fee', _transport),
                _moneyField('Other Monthly Charges', _other),
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _dueDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Due Day',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final day = int.tryParse(value?.trim() ?? '');
                      if (day == null || day < 1 || day > 28) {
                        return 'Use day 1 to 28';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Structure'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
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
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final academicClass = _selectedClass;
            final section = _selectedSection;
            if (academicClass == null || section == null) return;

            final now = DateTime.now();
            final repository = sl<FeeStructureRepository>();

            Navigator.pop(
              context,
              FeeStructureEntity(
                id: widget.existing?.id ?? repository.generateId(),
                academicSession: widget.academicSession,
                classId: academicClass.id,
                className: academicClass.name,
                sectionId: section.id,
                sectionName: section.name,
                monthlyTuitionFee: double.parse(_tuition.text.trim()),
                admissionFee: double.parse(_admission.text.trim()),
                annualCharges: double.parse(_annual.text.trim()),
                transportFee: double.parse(_transport.text.trim()),
                otherMonthlyCharges: double.parse(_other.text.trim()),
                dueDay: int.parse(_dueDay.text.trim()),
                isActive: _isActive,
                createdAt: widget.existing?.createdAt ?? now,
                updatedAt: now,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _moneyField(String label, TextEditingController controller) {
    return SizedBox(
      width: 210,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          prefixText: 'Rs. ',
          border: const OutlineInputBorder(),
        ),
        validator: _moneyValidator,
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
