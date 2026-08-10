import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/services/academic_class_order.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/entities/timetable_period_entity.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/timetable_configuration_bloc.dart';
import '../bloc/timetable_configuration_event.dart';
import '../bloc/timetable_configuration_state.dart';

class TimetableConfigurationPage extends StatelessWidget {
  const TimetableConfigurationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimetableConfigurationBloc>(
      create: (_) => sl<TimetableConfigurationBloc>(),
      child: const _TimetableConfigurationView(),
    );
  }
}

class _TimetableConfigurationView extends StatefulWidget {
  const _TimetableConfigurationView();

  @override
  State<_TimetableConfigurationView> createState() =>
      _TimetableConfigurationViewState();
}

class _TimetableConfigurationViewState
    extends State<_TimetableConfigurationView> {
  final _formKey = GlobalKey<FormState>();
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');
  final Set<int> _workingDays = {
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  };
  final List<TimetablePeriodEntity> _periods = [];
  List<AcademicClassEntity> _classes = const [];
  final Set<String> _selectedClassIds = <String>{};
  bool _creatingClassSchedule = false;

  TimeOfDay _openingTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 14, minute: 0);
  TimetableConfigurationEntity? _existingConfiguration;
  bool _saveRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initialize();
      }
    });
  }

  Future<void> _initialize() async {
    try {
      final classes = await sl<AcademicStructureRepository>().getClasses();
      if (!mounted) return;
      setState(() {
        _classes = classes.where((value) => value.isActive).toList()
          ..sort(compareAcademicClasses);
      });
    } catch (error) {
      if (mounted) _showMessage('Classes could not be loaded: $error');
    }
    if (mounted) _loadConfiguration();
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  void _loadConfiguration() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _saveRequested = false;
    context.read<TimetableConfigurationBloc>().add(
      LoadTimetableConfigurationEvent(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        classId: _selectedClassIds.isEmpty ? null : _selectedClassIds.first,
      ),
    );
  }

  void _selectClassScope(String classId, bool selected) {
    final shouldLoadSchedule = selected && _selectedClassIds.isEmpty;
    setState(() {
      if (selected) {
        _creatingClassSchedule = true;
        if (shouldLoadSchedule ||
            _existingConfiguration?.isDefaultSchedule == true) {
          _existingConfiguration = null;
        }
        _selectedClassIds.add(classId);
      } else {
        _selectedClassIds.remove(classId);
      }
    });
    if (shouldLoadSchedule) {
      _loadConfiguration();
    }
  }

  void _selectDefaultSchedule() {
    setState(() {
      _creatingClassSchedule = false;
      _existingConfiguration = null;
      _selectedClassIds.clear();
    });
    _loadConfiguration();
  }

  Future<void> _pickOpeningTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _openingTime,
    );
    if (selected != null && mounted) {
      setState(() => _openingTime = selected);
    }
  }

  Future<void> _pickClosingTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _closingTime,
    );
    if (selected != null && mounted) {
      setState(() => _closingTime = selected);
    }
  }

  Future<void> _editPeriod([TimetablePeriodEntity? existing]) async {
    _sortPeriods();
    final scheduleStartMinutes = _periods.isEmpty
        ? _toMinutes(_openingTime)
        : _periods.first.startMinutes;
    final existingIndex = existing == null
        ? -1
        : _periods.indexWhere((period) => period.id == existing.id);
    final isFirstPeriod = existing == null
        ? _periods.isEmpty
        : existingIndex == 0;
    final suggestedStartMinutes = existing != null
        ? existing.startMinutes
        : _periods.isEmpty
        ? _toMinutes(_openingTime)
        : _periods.last.endMinutes;
    final draft = await showDialog<_PeriodDraft>(
      context: context,
      builder: (_) => _PeriodEditorDialog(
        existing: existing,
        suggestedOrder: existing?.order ?? _periods.length + 1,
        suggestedStartMinutes: suggestedStartMinutes,
        canEditStartTime: isFirstPeriod,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }
    final updatedScheduleStartMinutes = isFirstPeriod
        ? draft.startMinutes
        : scheduleStartMinutes;

    final period = TimetablePeriodEntity(
      id: existing?.id ?? 'slot_${DateTime.now().microsecondsSinceEpoch}',
      label: draft.label,
      order: draft.order,
      startMinutes: draft.startMinutes,
      endMinutes: draft.endMinutes,
      type: draft.type,
    );

    setState(() {
      if (existing == null) {
        _periods.add(period);
      } else {
        final index = _periods.indexWhere((value) => value.id == existing.id);
        if (index >= 0) {
          _periods[index] = period;
        }
      }
      _sortPeriods();
      _recalculatePeriodTimes(updatedScheduleStartMinutes);
    });
  }

  Future<void> _deletePeriod(TimetablePeriodEntity period) async {
    _sortPeriods();
    final scheduleStartMinutes = _periods.isEmpty
        ? _toMinutes(_openingTime)
        : _periods.first.startMinutes;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Slot'),
            content: Text('Delete ${period.label}?'),
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

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _periods.removeWhere((value) => value.id == period.id);
      _sortPeriods();
      _recalculatePeriodTimes(scheduleStartMinutes);
    });
  }

  void _sortPeriods() {
    _periods.sort((first, second) {
      final orderComparison = first.order.compareTo(second.order);
      if (orderComparison != 0) {
        return orderComparison;
      }
      return first.startMinutes.compareTo(second.startMinutes);
    });
  }

  void _recalculatePeriodTimes(int scheduleStartMinutes) {
    if (_periods.isEmpty) {
      return;
    }

    var nextStart = scheduleStartMinutes;
    for (var index = 0; index < _periods.length; index++) {
      final period = _periods[index];
      final duration = period.durationMinutes;
      _periods[index] = period.copyWith(
        startMinutes: nextStart,
        endMinutes: nextStart + duration,
      );
      nextStart += duration;
    }
  }

  void _saveConfiguration() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_workingDays.isEmpty) {
      _showMessage('Select at least one working day.');
      return;
    }
    if (_periods.isEmpty) {
      _showMessage('Add at least one timetable slot.');
      return;
    }
    if (_creatingClassSchedule && _selectedClassIds.isEmpty) {
      _showMessage('Select at least one class for this separate schedule.');
      return;
    }

    final now = DateTime.now();
    final openingMinutes = _toMinutes(_openingTime);
    final closingMinutes = _toMinutes(_closingTime);
    final existing = _existingConfiguration;
    final repository = sl<TimetableRepository>();

    final configuration = TimetableConfigurationEntity(
      id: existing?.id ?? repository.generateConfigurationId(),
      branchId: _branchController.text.trim(),
      academicSession: _sessionController.text.trim(),
      classIds: _selectedClassIds.toList(growable: false),
      workingDays: _workingDays.toList()..sort(),
      schoolOpeningMinutes: openingMinutes,
      schoolClosingMinutes: closingMinutes,
      periods: List<TimetablePeriodEntity>.of(_periods),
      isActive: existing?.isActive ?? true,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final errors = configuration.validationErrors;
    if (errors.isNotEmpty) {
      _showMessage(errors.first);
      return;
    }

    _saveRequested = true;
    context.read<TimetableConfigurationBloc>().add(
      SaveTimetableConfigurationEvent(configuration),
    );
  }

  void _handleState(BuildContext context, TimetableConfigurationState state) {
    if (state is TimetableConfigurationLoaded) {
      final configuration = state.configuration;
      final isDefaultTemplate =
          _selectedClassIds.isNotEmpty && configuration.classIds.isEmpty;
      setState(() {
        _existingConfiguration = isDefaultTemplate ? null : configuration;
        if (!isDefaultTemplate) {
          _selectedClassIds
            ..clear()
            ..addAll(configuration.classIds);
          _creatingClassSchedule = configuration.classIds.isNotEmpty;
        } else {
          _creatingClassSchedule = true;
        }
        _workingDays
          ..clear()
          ..addAll(configuration.workingDays);
        _openingTime = _fromMinutes(configuration.schoolOpeningMinutes);
        _closingTime = _fromMinutes(configuration.schoolClosingMinutes);
        _periods
          ..clear()
          ..addAll(configuration.orderedPeriods);
      });

      if (state.successMessage != null) {
        _saveRequested = false;
        _showMessage(state.successMessage!);
      }
      if (isDefaultTemplate) {
        _showMessage(
          'No separate schedule exists for the selected class. '
          'The default schedule was loaded as a template.',
        );
      }
      return;
    }

    if (state is TimetableConfigurationEmpty) {
      setState(() {
        _existingConfiguration = null;
        _periods.clear();
      });
      _showMessage('No configuration found. You can create a new one.');
      return;
    }

    if (state is TimetableConfigurationError) {
      _saveRequested = false;
      _showMessage(state.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  TimeOfDay _fromMinutes(int minutes) {
    final safeMinutes = minutes.clamp(0, 1439).toInt();
    return TimeOfDay(hour: safeMinutes ~/ 60, minute: safeMinutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      TimetableConfigurationBloc,
      TimetableConfigurationState
    >(
      listener: _handleState,
      builder: (context, state) {
        final isLoading = state is TimetableConfigurationLoading;
        return Scaffold(
          appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Timetable Configuration')),
          body: SafeArea(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth >= 1200
                        ? 32.0
                        : constraints.maxWidth >= 700
                        ? 24.0
                        : 16.0;
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _scopeCard(),
                                const SizedBox(height: 16),
                                _classScopeCard(),
                                const SizedBox(height: 16),
                                _workingDaysCard(),
                                const SizedBox(height: 16),
                                _schoolTimingCard(),
                                const SizedBox(height: 16),
                                _periodsCard(),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: FilledButton.icon(
                                    onPressed: isLoading
                                        ? null
                                        : _saveConfiguration,
                                    icon: const Icon(Icons.save_outlined),
                                    label: Text(
                                      _saveRequested
                                          ? 'Saving...'
                                          : 'Save Configuration',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (isLoading)
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _scopeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Academic Scope',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth >= 700
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _branchController,
                        decoration: const InputDecoration(
                          labelText: 'Branch ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                        validator: _requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: fieldWidth,
                      child: TextFormField(
                        controller: _sessionController,
                        decoration: const InputDecoration(
                          labelText: 'Academic Session',
                          hintText: '2026-2027',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_month_outlined),
                        ),
                        validator: _requiredValidator,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _loadConfiguration,
                icon: const Icon(Icons.refresh),
                label: const Text('Load Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _workingDaysCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Working Days',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                return FilterChip(
                  label: Text(_weekdayName(day)),
                  selected: _workingDays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _workingDays.add(day);
                      } else {
                        _workingDays.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _classScopeCard() {
    final isDefault =
        _selectedClassIds.isEmpty && !_creatingClassSchedule;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apply Schedule To Classes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              isDefault
                  ? 'Default schedule: applies to every class without its own schedule.'
                  : _selectedClassIds.isEmpty
                  ? 'Click a class below. Its schedule will load automatically.'
                  : 'Edit the periods below and save this class schedule.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilterChip(
              selected: isDefault,
              label: const Text('Default Schedule'),
              avatar: const Icon(Icons.public, size: 18),
              onSelected: (_) => _selectDefaultSchedule(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final academicClass in _classes)
                  FilterChip(
                    selected: _selectedClassIds.contains(academicClass.id),
                    label: Text(academicClass.name),
                    onSelected: (selected) =>
                        _selectClassScope(academicClass.id, selected),
                  ),
              ],
            ),
            if (_selectedClassIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedClassIds.length} class(es) selected. '
                      'Change the timing/periods below, then press Save Configuration.',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _schoolTimingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Timing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickOpeningTime,
                  icon: const Icon(Icons.login_outlined),
                  label: Text('Opening: ${_openingTime.format(context)}'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickClosingTime,
                  icon: const Icon(Icons.logout_outlined),
                  label: Text('Closing: ${_closingTime.format(context)}'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Period Schedule',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_periods.where((period) => period.isTeaching).length} teaching periods',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                FilledButton.tonalIcon(
                  onPressed: _editPeriod,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Slot'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_periods.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'No slots added. Add assembly, teaching periods and break.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _periods.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final period = _periods[index];
                  return _PeriodListItem(
                    period: period,
                    onEdit: () => _editPeriod(period),
                    onDelete: () => _deletePeriod(period),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class _PeriodListItem extends StatelessWidget {
  const _PeriodListItem({
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  final TimetablePeriodEntity period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final startTime = _timeFromMinutes(period.startMinutes).format(context);
    final endTime = _timeFromMinutes(period.endMinutes).format(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text('${period.order}')),
      title: Text(period.label),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(_periodTypeLabel(period.type)),
            visualDensity: VisualDensity.compact,
          ),
          Text('$startTime - $endTime'),
          Text('${period.durationMinutes} minutes'),
        ],
      ),
      trailing: Wrap(
        spacing: 2,
        children: [
          IconButton(
            tooltip: 'Edit slot',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete slot',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _PeriodEditorDialog extends StatefulWidget {
  const _PeriodEditorDialog({
    required this.existing,
    required this.suggestedOrder,
    required this.suggestedStartMinutes,
    required this.canEditStartTime,
  });

  final TimetablePeriodEntity? existing;
  final int suggestedOrder;
  final int suggestedStartMinutes;
  final bool canEditStartTime;

  @override
  State<_PeriodEditorDialog> createState() => _PeriodEditorDialogState();
}

class _PeriodEditorDialogState extends State<_PeriodEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final TextEditingController _orderController;
  late final TextEditingController _durationController;
  late TimeOfDay _startTime;
  late TimetablePeriodType _type;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _orderController = TextEditingController(
      text: (existing?.order ?? widget.suggestedOrder).toString(),
    );
    _durationController = TextEditingController(
      text: (existing?.durationMinutes ?? 40).toString(),
    );
    _startTime = _timeFromMinutes(widget.suggestedStartMinutes);
    _type = existing?.type ?? TimetablePeriodType.teaching;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _orderController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (selected != null && mounted) {
      setState(() => _startTime = selected);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startMinutes = _minutesFromTime(_startTime);
    final durationMinutes = int.parse(_durationController.text.trim());
    final endMinutes = startMinutes + durationMinutes;
    if (endMinutes > 1440) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot cannot end after midnight.')),
      );
      return;
    }

    Navigator.of(context).pop(
      _PeriodDraft(
        label: _labelController.text.trim(),
        order: int.parse(_orderController.text.trim()),
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        type: _type,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Timetable Slot' : 'Edit Slot'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _labelController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Slot Label',
                    hintText: 'Period 1, Assembly or Break',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Slot label is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Display Order',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final order = int.tryParse(value?.trim() ?? '');
                    return order == null || order < 1
                        ? 'Enter a valid order'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TimetablePeriodType>(
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: 'Slot Type',
                    border: OutlineInputBorder(),
                  ),
                  items: TimetablePeriodType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_periodTypeLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: '40',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final duration = int.tryParse(value?.trim() ?? '');
                    return duration == null || duration < 1
                        ? 'Enter a valid duration'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.canEditStartTime)
                      OutlinedButton.icon(
                        onPressed: _pickStartTime,
                        icon: const Icon(Icons.schedule),
                        label: Text('Start: ${_startTime.format(context)}'),
                      )
                    else
                      Chip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          'Starts automatically: ${_startTime.format(context)}',
                        ),
                      ),
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 18),
                      label: Text(
                        'Ends automatically: ${_calculatedEndTime.format(context)}',
                      ),
                    ),
                  ],
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
        FilledButton(onPressed: _save, child: const Text('Save Slot')),
      ],
    );
  }

  TimeOfDay get _calculatedEndTime {
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    return _timeFromMinutes(
      (_minutesFromTime(_startTime) + duration).clamp(0, 1439).toInt(),
    );
  }
}

class _PeriodDraft {
  const _PeriodDraft({
    required this.label,
    required this.order,
    required this.startMinutes,
    required this.endMinutes,
    required this.type,
  });

  final String label;
  final int order;
  final int startMinutes;
  final int endMinutes;
  final TimetablePeriodType type;
}

TimeOfDay _timeFromMinutes(int minutes) {
  final safeMinutes = minutes.clamp(0, 1439).toInt();
  return TimeOfDay(hour: safeMinutes ~/ 60, minute: safeMinutes % 60);
}

int _minutesFromTime(TimeOfDay time) => time.hour * 60 + time.minute;

String _periodTypeLabel(TimetablePeriodType type) {
  switch (type) {
    case TimetablePeriodType.teaching:
      return 'Teaching';
    case TimetablePeriodType.assembly:
      return 'Assembly';
    case TimetablePeriodType.breakTime:
      return 'Break';
  }
}

String _weekdayName(int day) {
  switch (day) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return 'Unknown';
  }
}
