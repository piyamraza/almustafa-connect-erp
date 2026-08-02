import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/teacher_availability_entity.dart';
import '../../domain/entities/timetable_configuration_entity.dart';
import '../../domain/repositories/teacher_availability_repository.dart';
import '../../domain/repositories/timetable_repository.dart';
import '../bloc/teacher_availability_bloc.dart';

class TeacherAvailabilityPage extends StatelessWidget {
  const TeacherAvailabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeacherAvailabilityBloc>(
      create: (_) => sl<TeacherAvailabilityBloc>(),
      child: const _TeacherAvailabilityView(),
    );
  }
}

class _TeacherAvailabilityView extends StatefulWidget {
  const _TeacherAvailabilityView();

  @override
  State<_TeacherAvailabilityView> createState() =>
      _TeacherAvailabilityViewState();
}

class _TeacherAvailabilityViewState extends State<_TeacherAvailabilityView> {
  final _branchController = TextEditingController(text: 'main');
  final _sessionController = TextEditingController(text: '2026-2027');

  List<TeacherEntity> _teachers = const [];
  TimetableConfigurationEntity? _configuration;
  bool _referenceLoading = true;
  String? _referenceError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReferenceData();
    });
  }

  @override
  void dispose() {
    _branchController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceData() async {
    setState(() {
      _referenceLoading = true;
      _referenceError = null;
    });

    try {
      final branch = _branchController.text.trim();
      final session = _sessionController.text.trim();
      final values = await Future.wait<Object?>([
        sl<TeacherRepository>().getTeachers(),
        sl<TimetableRepository>().getConfiguration(
          branchId: branch,
          academicSession: session,
        ),
      ]);

      if (!mounted) return;

      final teachers =
          (values[0] as List<TeacherEntity>)
              .where((item) => item.isActive)
              .toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

      setState(() {
        _teachers = teachers;
        _configuration = values[1] as TimetableConfigurationEntity?;
        _referenceLoading = false;
      });

      _loadAvailabilities();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _referenceLoading = false;
        _referenceError = _message(error);
      });
    }
  }

  void _loadAvailabilities() {
    context.read<TeacherAvailabilityBloc>().add(
      LoadTeacherAvailabilities(
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
      ),
    );
  }

  Future<void> _edit(TeacherAvailabilityEntity? existing) async {
    final configuration = _configuration;
    if (configuration == null) {
      _show('Timetable configuration was not found.');
      return;
    }

    final result = await showDialog<TeacherAvailabilityEntity>(
      context: context,
      builder: (_) => _AvailabilityDialog(
        teachers: _teachers,
        configuration: configuration,
        branchId: _branchController.text.trim(),
        academicSession: _sessionController.text.trim(),
        existing: existing,
      ),
    );

    if (!mounted || result == null) return;

    context.read<TeacherAvailabilityBloc>().add(
      SaveTeacherAvailability(result),
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
      appBar: AppBar(actions: const [DashboardNavigationButton()], title: const Text('Teacher Availability')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _referenceLoading ? null : () => _edit(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Availability'),
      ),
      body: SafeArea(
        child: BlocConsumer<TeacherAvailabilityBloc, TeacherAvailabilityState>(
          listener: (context, state) {
            if (state is TeacherAvailabilityLoaded && state.message != null) {
              _show(state.message!);
            } else if (state is TeacherAvailabilityError) {
              _show(state.message);
            }
          },
          builder: (context, state) {
            final busy =
                _referenceLoading || state is TeacherAvailabilityLoading;
            final values = state is TeacherAvailabilityLoaded
                ? state.values
                : const <TeacherAvailabilityEntity>[];

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
                            'Teacher Availability',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure weekly off days, unavailable periods '
                            'and teaching load limits.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 22),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: TextFormField(
                                      controller: _branchController,
                                      decoration: const InputDecoration(
                                        labelText: 'Branch ID',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
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
                                  FilledButton.icon(
                                    onPressed: busy ? null : _loadReferenceData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Load'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          if (_referenceError != null)
                            _MessageCard(_referenceError!)
                          else if (values.isEmpty && !busy)
                            const _MessageCard(
                              'No teacher availability rules configured.',
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 1050
                                    ? 3
                                    : constraints.maxWidth >= 680
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
                                            ? 1.7
                                            : 1.25,
                                      ),
                                  itemBuilder: (context, index) {
                                    final value = values[index];
                                    return Card(
                                      child: InkWell(
                                        onTap: () => _edit(value),
                                        child: Padding(
                                          padding: const EdgeInsets.all(18),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const CircleAvatar(
                                                    child: Icon(
                                                      Icons.person_outline,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      value.teacherName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      context
                                                          .read<
                                                            TeacherAvailabilityBloc
                                                          >()
                                                          .add(
                                                            DeleteTeacherAvailability(
                                                              id: value.id,
                                                              branchId: value
                                                                  .branchId,
                                                              academicSession: value
                                                                  .academicSession,
                                                            ),
                                                          );
                                                    },
                                                    icon: const Icon(
                                                      Icons.delete_outline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 14),
                                              Text(
                                                'Weekly off: '
                                                '${value.weeklyOffDays.isEmpty ? 'None' : value.weeklyOffDays.map(_dayName).join(', ')}',
                                              ),
                                              Text(
                                                'Unavailable slots: '
                                                '${value.unavailableSlots.length}',
                                              ),
                                              Text(
                                                'Max/day: '
                                                '${value.maxPeriodsPerDay == 0 ? 'No limit' : value.maxPeriodsPerDay}',
                                              ),
                                              Text(
                                                'Max/week: '
                                                '${value.maxPeriodsPerWeek == 0 ? 'No limit' : value.maxPeriodsPerWeek}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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

  static String _dayName(int day) => switch (day) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => 'Day',
  };
}

class _AvailabilityDialog extends StatefulWidget {
  const _AvailabilityDialog({
    required this.teachers,
    required this.configuration,
    required this.branchId,
    required this.academicSession,
    this.existing,
  });

  final List<TeacherEntity> teachers;
  final TimetableConfigurationEntity configuration;
  final String branchId;
  final String academicSession;
  final TeacherAvailabilityEntity? existing;

  @override
  State<_AvailabilityDialog> createState() => _AvailabilityDialogState();
}

class _AvailabilityDialogState extends State<_AvailabilityDialog> {
  String? _teacherId;
  late Set<int> _weeklyOffDays;
  late Set<String> _unavailableKeys;
  late TextEditingController _maxDayController;
  late TextEditingController _maxWeekController;

  @override
  void initState() {
    super.initState();
    _teacherId =
        widget.existing?.teacherId ??
        (widget.teachers.isEmpty ? null : widget.teachers.first.id);
    _weeklyOffDays = widget.existing?.weeklyOffDays.toSet() ?? <int>{};
    _unavailableKeys =
        widget.existing?.unavailableSlots.map((slot) => slot.key).toSet() ??
        <String>{};
    _maxDayController = TextEditingController(
      text: '${widget.existing?.maxPeriodsPerDay ?? 0}',
    );
    _maxWeekController = TextEditingController(
      text: '${widget.existing?.maxPeriodsPerWeek ?? 0}',
    );
  }

  @override
  void dispose() {
    _maxDayController.dispose();
    _maxWeekController.dispose();
    super.dispose();
  }

  TeacherEntity? get _teacher {
    for (final teacher in widget.teachers) {
      if (teacher.id == _teacherId) return teacher;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.configuration.workingDays.toList()..sort();
    final periods = widget.configuration.orderedPeriods
        .where((period) => period.isTeaching)
        .toList();

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add Teacher Availability'
            : 'Edit Teacher Availability',
      ),
      content: SizedBox(
        width: 700,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _teacherId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Teacher',
                  border: OutlineInputBorder(),
                ),
                items: widget.teachers
                    .map(
                      (teacher) => DropdownMenuItem(
                        value: teacher.id,
                        child: Text(teacher.fullName),
                      ),
                    )
                    .toList(),
                onChanged: widget.existing == null
                    ? (value) => setState(() => _teacherId = value)
                    : null,
              ),
              const SizedBox(height: 18),
              Text(
                'Weekly Off Days',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final day in days)
                    FilterChip(
                      label: Text(_TeacherAvailabilityViewState._dayName(day)),
                      selected: _weeklyOffDays.contains(day),
                      onSelected: (selected) {
                        setState(() {
                          selected
                              ? _weeklyOffDays.add(day)
                              : _weeklyOffDays.remove(day);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxDayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Periods Per Day',
                        helperText: 'Enter 0 for no limit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _maxWeekController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maximum Periods Per Week',
                        helperText: 'Enter 0 for no limit',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Unavailable Periods',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final day in days)
                ExpansionTile(
                  title: Text(_TeacherAvailabilityViewState._dayName(day)),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final period in periods)
                          FilterChip(
                            label: Text(period.label),
                            selected: _unavailableKeys.contains(
                              '$day|${period.id}',
                            ),
                            onSelected: (selected) {
                              setState(() {
                                final key = '$day|${period.id}';
                                selected
                                    ? _unavailableKeys.add(key)
                                    : _unavailableKeys.remove(key);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
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
        FilledButton(
          onPressed: _teacher == null
              ? null
              : () {
                  final now = DateTime.now();
                  final slots = _unavailableKeys.map((key) {
                    final values = key.split('|');
                    return TeacherUnavailableSlot(
                      weekday: int.parse(values.first),
                      periodId: values.last,
                    );
                  }).toList();

                  Navigator.pop(
                    context,
                    TeacherAvailabilityEntity(
                      id:
                          widget.existing?.id ??
                          sl<TeacherAvailabilityRepository>().generateId(),
                      teacherId: _teacher!.id,
                      teacherName: _teacher!.fullName,
                      branchId: widget.branchId,
                      academicSession: widget.academicSession,
                      weeklyOffDays: _weeklyOffDays.toList()..sort(),
                      unavailableSlots: slots,
                      maxPeriodsPerDay:
                          int.tryParse(_maxDayController.text) ?? 0,
                      maxPeriodsPerWeek:
                          int.tryParse(_maxWeekController.text) ?? 0,
                      isActive: true,
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
