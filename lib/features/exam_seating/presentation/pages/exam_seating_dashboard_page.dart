import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../../exams/domain/entities/exam_date_sheet_entity.dart';
import '../../domain/entities/exam_seating_entities.dart';
import '../bloc/exam_seating_bloc.dart';
import '../bloc/exam_seating_event.dart';
import '../bloc/exam_seating_state.dart';
import '../services/exam_plan_pdf_service.dart';

class ExamSeatingDashboardPage extends StatelessWidget {
  const ExamSeatingDashboardPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ExamSeatingBloc>()..add(const LoadExamSeating()),
    child: const _ExamSeatingView(),
  );
}

class _ExamSeatingView extends StatefulWidget {
  const _ExamSeatingView();
  @override
  State<_ExamSeatingView> createState() => _ExamSeatingViewState();
}

class _ExamSeatingViewState extends State<_ExamSeatingView> {
  _SessionOption? _session;
  bool _paperSupport = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Seating & Duty Plans'),
      actions: const [DashboardNavigationButton()],
    ),
    body: BlocConsumer<ExamSeatingBloc, ExamSeatingState>(
      listener: (context, state) {
        if (state is ExamSeatingLoaded && state.message != null)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message!)));
      },
      builder: (context, state) {
        if (state is ExamSeatingLoading || state is ExamSeatingInitial)
          return const Center(child: CircularProgressIndicator());
        if (state is ExamSeatingError)
          return _ErrorView(
            message: state.message,
            onRetry: () =>
                context.read<ExamSeatingBloc>().add(const LoadExamSeating()),
          );
        final data = state as ExamSeatingLoaded;
        final sheets = data.dateSheets
            .where(
              (sheet) =>
                  sheet.examId == data.selectedExamId &&
                  sheet.status != ExamDateSheetStatus.archived,
            )
            .toList();
        final sessions = _sessions(sheets);
        if (_session != null && !sessions.contains(_session)) _session = null;
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.all(constraints.maxWidth < 700 ? 12 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam Seating & Teacher Duty',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Save exam-wise rooms once, then generate a fresh student rotation and teacher duty plan for every paper session.',
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: '1. Select Exam',
                      child: DropdownButtonFormField<String>(
                        initialValue: data.selectedExamId,
                        decoration: const InputDecoration(
                          labelText: 'Exam',
                          border: OutlineInputBorder(),
                        ),
                        items: data.exams
                            .map(
                              (exam) => DropdownMenuItem(
                                value: exam.id,
                                child: Text(exam.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _session = null);
                          if (value != null)
                            context.read<ExamSeatingBloc>().add(
                              SelectSeatingExam(value),
                            );
                        },
                      ),
                    ),
                    if (data.selectedExamId != null) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '2. Exam Room Setup',
                        trailing: FilledButton.icon(
                          onPressed: () => _editRooms(context, data.roomSetup),
                          icon: const Icon(Icons.meeting_room_outlined),
                          label: Text(
                            data.roomSetup == null ? 'Add Rooms' : 'Edit Rooms',
                          ),
                        ),
                        child: data.roomSetup == null
                            ? const Text(
                                'Enter total rooms and their capacities. This setup remains fixed for the selected exam until edited.',
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  for (final room in data.roomSetup!.rooms)
                                    Chip(
                                      avatar: const Icon(
                                        Icons.chair_alt_outlined,
                                        size: 18,
                                      ),
                                      label: Text(
                                        '${room.name}: ${room.capacity} seats',
                                      ),
                                    ),
                                  Chip(
                                    label: Text(
                                      'Total: ${data.roomSetup!.totalCapacity} seats',
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                    if (data.roomSetup != null) ...[
                      const SizedBox(height: 14),
                      _SectionCard(
                        title: '3. Generate Daily Plan',
                        child: Column(
                          children: [
                            DropdownButtonFormField<_SessionOption>(
                              initialValue: _session,
                              decoration: const InputDecoration(
                                labelText: 'Exam date and session',
                                border: OutlineInputBorder(),
                              ),
                              items: sessions
                                  .map(
                                    (option) => DropdownMenuItem(
                                      value: option,
                                      child: Text(option.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _session = value),
                            ),
                            const SizedBox(height: 8),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Use Paper Support teacher'),
                              subtitle: const Text(
                                'Optional and off by default. Turn on only when a separate paper-support teacher is required.',
                              ),
                              value: _paperSupport,
                              onChanged: (value) =>
                                  setState(() => _paperSupport = value),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _session == null
                                    ? null
                                    : () {
                                        final value = _session!;
                                        context.read<ExamSeatingBloc>().add(
                                          GenerateDailyExamPlan(
                                            dateSheetId: value.dateSheetId,
                                            examDate: value.date,
                                            startMinutes: value.startMinutes,
                                            endMinutes: value.endMinutes,
                                            paperSupportEnabled: _paperSupport,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Generate Plan'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (data.preview != null) ...[
                      const SizedBox(height: 14),
                      _PlanPreview(
                        plan: data.preview!,
                        onFinalize:
                            data.preview!.status == ExamPlanStatus.finalized
                            ? null
                            : () => context.read<ExamSeatingBloc>().add(
                                FinalizeDailyExamPlan(data.preview!),
                              ),
                      ),
                    ],
                    if (data.plans.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Saved Plans',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...data.plans
                          .where(
                            (plan) =>
                                data.selectedExamId == null ||
                                plan.examId == data.selectedExamId,
                          )
                          .map(
                            (plan) => Card(
                              child: ListTile(
                                leading: const Icon(Icons.fact_check_outlined),
                                title: Text(
                                  '${DateFormat('dd MMM yyyy').format(plan.examDate)} • ${plan.sessionLabel}',
                                ),
                                subtitle: Text(
                                  '${plan.studentAssignments.length} students • ${plan.rooms.length} rooms',
                                ),
                                trailing: IconButton(
                                  tooltip: 'Print',
                                  icon: const Icon(Icons.print_outlined),
                                  onPressed: () => const ExamPlanPdfService()
                                      .printPlan(plan),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  List<_SessionOption> _sessions(List<ExamDateSheetEntity> sheets) {
    final result = <_SessionOption>[];
    for (final sheet in sheets) {
      for (final paper in sheet.papers) {
        final option = _SessionOption(
          sheet.id,
          paper.examDate,
          paper.startMinutes,
          paper.endMinutes,
        );
        if (!result.contains(option)) result.add(option);
      }
    }
    result.sort((a, b) {
      final date = a.date.compareTo(b.date);
      return date != 0 ? date : a.startMinutes.compareTo(b.startMinutes);
    });
    return result;
  }

  Future<void> _editRooms(
    BuildContext context,
    ExamRoomSetupEntity? setup,
  ) async {
    final count = TextEditingController(text: '${setup?.rooms.length ?? 8}');
    var rooms = setup?.rooms.toList() ?? const <ExamRoomEntity>[];
    final result = await showDialog<List<ExamRoomEntity>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void buildRows() {
            final value = int.tryParse(count.text) ?? 0;
            if (value < 1 || value > 50) return;
            rooms = List.generate(
              value,
              (index) => index < rooms.length
                  ? rooms[index]
                  : ExamRoomEntity(
                      id: 'room_${index + 1}',
                      name: 'Room ${index + 1}',
                      capacity: 30,
                    ),
            );
            setDialogState(() {});
          }

          return AlertDialog(
            title: const Text('Exam Room Setup'),
            content: SizedBox(
              width: 650,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: count,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Total rooms',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: buildRows,
                          child: const Text('Create Table'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (var i = 0; i < rooms.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 74,
                              child: Text(
                                'Room #${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextFormField(
                                initialValue: rooms[i].name,
                                decoration: const InputDecoration(
                                  labelText: 'Room name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => rooms[i] = ExamRoomEntity(
                                  id: rooms[i].id,
                                  name: value.trim(),
                                  capacity: rooms[i].capacity,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 150,
                              child: TextFormField(
                                initialValue: '${rooms[i].capacity}',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Capacity',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => rooms[i] = ExamRoomEntity(
                                  id: rooms[i].id,
                                  name: rooms[i].name,
                                  capacity: int.tryParse(value) ?? 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    rooms.isEmpty ||
                        rooms.any(
                          (room) => room.name.isEmpty || room.capacity <= 0,
                        )
                    ? null
                    : () => Navigator.pop(dialogContext, rooms),
                child: const Text('Save Setup'),
              ),
            ],
          );
        },
      ),
    );
    count.dispose();
    if (result != null && context.mounted)
      context.read<ExamSeatingBloc>().add(SaveExamRoomSetup(result));
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan, required this.onFinalize});
  final DailyExamPlanEntity plan;
  final VoidCallback? onFinalize;
  @override
  Widget build(BuildContext context) {
    final rest = plan.teacherAssignments
        .where((item) => item.isRest)
        .map((item) => item.teacherName)
        .join(', ');
    final support = plan.teacherAssignments
        .where((item) => item.isPaperSupport)
        .map((item) => item.teacherName)
        .join(', ');
    return _SectionCard(
      title: '4. Plan Preview',
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => const ExamPlanPdfService().printPlan(plan),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print'),
          ),
          if (onFinalize != null)
            FilledButton.icon(
              onPressed: onFinalize,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Finalize'),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('dd MMM yyyy').format(plan.examDate)} • ${plan.sessionLabel} • ${plan.studentAssignments.length} students',
          ),
          const SizedBox(height: 8),
          Text(
            'Daily Rest: ${rest.isEmpty ? '—' : rest}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (plan.paperSupportEnabled)
            Text('Paper Support: ${support.isEmpty ? '—' : support}'),
          const Divider(height: 24),
          for (final room in plan.rooms)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(room.name),
              subtitle: Text(
                '${plan.studentAssignments.where((item) => item.roomId == room.id).length}/${room.capacity} students • ${plan.teacherAssignments.where((item) => item.roomId == room.id).map((item) => item.teacherName).join(', ')}',
              ),
              children: [
                SizedBox(
                  height: 260,
                  child: ListView(
                    children: plan.studentAssignments
                        .where((item) => item.roomId == room.id)
                        .map(
                          (item) => ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              child: Text('${item.seatNumber}'),
                            ),
                            title: Text(item.studentName),
                            subtitle: Text(
                              '${item.className} • Roll ${item.rollNumber}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 8),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _SessionOption {
  const _SessionOption(
    this.dateSheetId,
    this.date,
    this.startMinutes,
    this.endMinutes,
  );
  final String dateSheetId;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  String get label =>
      '${DateFormat('EEE, dd MMM yyyy').format(date)} • ${DailyExamPlanEntity(id: '', examId: '', examName: '', dateSheetId: '', examDate: date, startMinutes: startMinutes, endMinutes: endMinutes, rooms: const [], studentAssignments: const [], teacherAssignments: const [], status: ExamPlanStatus.draft, paperSupportEnabled: false, createdAt: date, updatedAt: date).sessionLabel}';
  @override
  bool operator ==(Object other) =>
      other is _SessionOption &&
      dateSheetId == other.dateSheetId &&
      date.year == other.date.year &&
      date.month == other.date.month &&
      date.day == other.date.day &&
      startMinutes == other.startMinutes &&
      endMinutes == other.endMinutes;
  @override
  int get hashCode => Object.hash(
    dateSheetId,
    date.year,
    date.month,
    date.day,
    startMinutes,
    endMinutes,
  );
}
