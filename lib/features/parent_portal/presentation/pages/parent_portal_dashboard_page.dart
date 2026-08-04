import 'package:flutter/material.dart';
import '../../../academic_structure/presentation/widgets/academic_reference_label.dart';
import 'package:almustafa_connect_erp/core/widgets/dashboard_navigation_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../bloc/parent_portal_bloc.dart';
import 'parent_account_form_page.dart';

import 'parent_academic_dashboard_page.dart';
import 'parent_attendance_page.dart';
import 'parent_homework_page.dart';
import 'parent_results_page.dart';
import 'parent_fee_page.dart';
import 'parent_chat_page.dart';

import 'parent_communication_dashboard_page.dart';

import 'parent_notification_center_page.dart';
import '../../../timeline/presentation/pages/timeline_page.dart';
import '../../../timeline/presentation/widgets/recent_timeline_card.dart';

class ParentPortalDashboardPage extends StatelessWidget {
  const ParentPortalDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ParentPortalBloc>()..add(const LoadParentAccounts()),
      child: const _ParentPortalDashboardView(),
    );
  }
}

class _ParentPortalDashboardView extends StatelessWidget {
  const _ParentPortalDashboardView();

  Future<void> _openParentForm(
    BuildContext context, [
    ParentAccountEntity? existing,
  ]) async {
    final value = await Navigator.of(context).push<ParentAccountEntity>(
      MaterialPageRoute(
        builder: (_) => ParentAccountFormPage(existing: existing),
      ),
    );

    if (value != null && context.mounted) {
      context.read<ParentPortalBloc>().add(SaveParentAccount(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Portal'),
        actions: [
          const DashboardNavigationButton(),
          BlocBuilder<ParentPortalBloc, ParentPortalState>(
            builder: (context, state) {
              if (state is! ParentPortalLoaded ||
                  state.selectedParent == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ParentNotificationCenterPage(
                        parent: state.selectedParent!,
                        studentId: state.linkedStudents.isEmpty
                            ? null
                            : state.linkedStudents.first.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openParentForm(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Create Parent Account'),
      ),
      body: BlocConsumer<ParentPortalBloc, ParentPortalState>(
        listener: (context, state) {
          final message = switch (state) {
            ParentPortalLoaded(:final message) => message,
            ParentPortalError(:final message) => message,
            _ => null,
          };

          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          if (state is ParentPortalLoading || state is ParentPortalInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ParentPortalError) {
            return Center(child: Text(state.message));
          }

          final loaded = state as ParentPortalLoaded;

          return Row(
            children: [
              SizedBox(
                width: 330,
                child: _ParentList(
                  parents: loaded.parents,
                  selected: loaded.selectedParent,
                  onSelect: (parent) {
                    context.read<ParentPortalBloc>().add(
                      SelectParentAccount(parent),
                    );
                  },
                  onEdit: (parent) => _openParentForm(context, parent),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: loaded.selectedParent == null
                    ? const _EmptyParentSelection()
                    : _ParentDashboard(
                        parent: loaded.selectedParent!,
                        students: loaded.linkedStudents,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParentList extends StatelessWidget {
  const _ParentList({
    required this.parents,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });

  final List<ParentAccountEntity> parents;
  final ParentAccountEntity? selected;
  final ValueChanged<ParentAccountEntity> onSelect;
  final ValueChanged<ParentAccountEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Parent Accounts',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Chip(label: Text('${parents.length}')),
            ],
          ),
        ),
        Expanded(
          child: parents.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No parent accounts found. Create the first '
                      'account and link students using guardian '
                      'phone or email.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];

                    return ListTile(
                      selected: selected?.id == parent.id,
                      leading: const CircleAvatar(
                        child: Icon(Icons.family_restroom),
                      ),
                      title: Text(parent.fullName),
                      subtitle: Text(
                        parent.mobileNumber.isNotEmpty
                            ? '${parent.mobileNumber}${parent.whatsappNumber.isNotEmpty ? ' • WhatsApp ${parent.whatsappNumber}' : ''}'
                            : parent.email,
                      ),
                      onTap: () => onSelect(parent),
                      trailing: IconButton(
                        tooltip: 'Edit',
                        onPressed: () => onEdit(parent),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _EmptyParentSelection extends StatelessWidget {
  const _EmptyParentSelection();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Select a parent account to open the portal preview.'),
    );
  }
}

class _ParentDashboard extends StatefulWidget {
  const _ParentDashboard({required this.parent, required this.students});

  final ParentAccountEntity parent;
  final List<StudentEntity> students;

  @override
  State<_ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<_ParentDashboard> {
  String? _selectedStudentId;

  @override
  void didUpdateWidget(covariant _ParentDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.parent.id != widget.parent.id) {
      _selectedStudentId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId =
        _selectedStudentId ??
        (widget.students.isEmpty ? null : widget.students.first.id);

    StudentEntity? selectedStudent;
    for (final student in widget.students) {
      if (student.id == selectedId) {
        selectedStudent = student;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Welcome, ${widget.parent.fullName}',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.parent.relationship} • '
          '${widget.parent.mobileNumber}${widget.parent.whatsappNumber.isNotEmpty ? ' • WhatsApp ${widget.parent.whatsappNumber}' : ''}',
        ),
        const SizedBox(height: 18),
        if (widget.students.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No active student is linked with this parent.'),
            ),
          )
        else ...[
          SizedBox(
            width: 320,
            child: DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(
                labelText: 'Select Child',
                border: OutlineInputBorder(),
              ),
              items: widget.students
                  .map(
                    (student) => DropdownMenuItem(
                      value: student.id,
                      child: Text(
                        '${student.fullName} (${student.admissionNo})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedStudentId = value);
              },
            ),
          ),
          const SizedBox(height: 18),
          if (selectedStudent case final student?) ...[
            _StudentHeader(student: student),
            const SizedBox(height: 18),
            RecentTimelineCard(studentId: student.id),
            const SizedBox(height: 18),
            _PortalModulesGrid(parent: widget.parent, student: student),
          ],
        ],
      ],
    );
  }
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundImage: student.profileImageUrl.isEmpty
                  ? null
                  : NetworkImage(student.profileImageUrl),
              child: student.profileImageUrl.isEmpty
                  ? const Icon(Icons.person, size: 34)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${student.admissionNo} • '),
                      Expanded(
                        child: AcademicReferenceLabel(
                          classReference: student.classId,
                          sectionReference: student.sectionId,
                        ),
                      ),
                    ],
                  ),
                  Text('Father: ${student.fatherName}'),
                ],
              ),
            ),
            Chip(label: Text(student.isActive ? 'ACTIVE' : 'INACTIVE')),
          ],
        ),
      ),
    );
  }
}

class _PortalModulesGrid extends StatelessWidget {
  const _PortalModulesGrid({required this.parent, required this.student});

  final ParentAccountEntity parent;
  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    const modules = [
      ('Attendance', Icons.fact_check_outlined),
      ('Timetable', Icons.schedule_outlined),
      ('Homework', Icons.menu_book_outlined),
      ('Date Sheet', Icons.calendar_month_outlined),
      ('Results', Icons.grade_outlined),
      ('Fee Status', Icons.payments_outlined),
      ('Academic Calendar', Icons.event_outlined),
      ('Notices', Icons.campaign_outlined),
      ('Messages', Icons.chat_bubble_outline),
      ('Teacher Remarks', Icons.comment_outlined),
      ('Timeline', Icons.timeline),
      ('Medical Alert', Icons.medical_information_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (module.$1 == 'Attendance') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentAttendancePage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Homework') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentHomeworkPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Results') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentResultsPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Fee Status') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentFeePage(student: student),
                      ),
                    );
                    return;
                  }

                  if (['Timetable', 'Date Sheet'].contains(module.$1)) {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParentAcademicDashboardPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (['Academic Calendar', 'Notices'].contains(module.$1)) {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentCommunicationDashboardPage(
                          parent: parent,

                          student: student,
                        ),
                      ),
                    );

                    return;
                  }

                  if (module.$1 == 'Messages') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParentChatPage(parent: parent, student: student),
                      ),
                    );
                    return;
                  }

                  if (module.$1 == 'Timeline') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => TimelinePage(
                          studentId: student.id,
                          title: '${student.fullName} Timeline',
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${module.$1} integration will be connected '
                        'in Parent Portal Phase 4.',
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(module.$2),
                      const Spacer(),
                      Text(
                        module.$1,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
