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
import 'parent_query_page.dart';

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
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ParentAccountFormPage(existing: existing),
      ),
    );

    if (saved == true && context.mounted) {
      context.read<ParentPortalBloc>().add(const LoadParentAccounts());
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ParentAccountEntity parent,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Parent Account?'),
            content: Text(
              'Delete ${parent.fullName}\'s parent portal account?\n\n'
              'Linked student records will not be deleted. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onError,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Account'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && context.mounted) {
      context.read<ParentPortalBloc>().add(DeleteParentAccount(parent.id));
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
      floatingActionButton: MediaQuery.sizeOf(context).width < 600
          ? FloatingActionButton(
              tooltip: 'Create Parent Account',
              onPressed: () => _openParentForm(context),
              child: const Icon(Icons.person_add_alt_1_rounded),
            )
          : FloatingActionButton.extended(
              onPressed: () => _openParentForm(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
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

          final compact = MediaQuery.sizeOf(context).width < 800;
          final parentList = _ParentList(
            parents: loaded.parents,
            selected: loaded.selectedParent,
            onSelect: (parent) {
              context.read<ParentPortalBloc>().add(SelectParentAccount(parent));
            },
            onEdit: (parent) => _openParentForm(context, parent),
            onDelete: (parent) => _confirmDelete(context, parent),
          );
          final dashboard = loaded.selectedParent == null
              ? const _EmptyParentSelection()
              : _ParentDashboard(
                  parent: loaded.selectedParent!,
                  students: loaded.linkedStudents,
                );
          if (compact) {
            return Column(
              children: [
                SizedBox(height: 126, child: parentList),
                const Divider(height: 1),
                Expanded(child: dashboard),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 330, child: parentList),
              const VerticalDivider(width: 1),
              Expanded(child: dashboard),
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
    required this.onDelete,
  });

  final List<ParentAccountEntity> parents;
  final ParentAccountEntity? selected;
  final ValueChanged<ParentAccountEntity> onSelect;
  final ValueChanged<ParentAccountEntity> onEdit;
  final ValueChanged<ParentAccountEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 800;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(compact ? 8 : 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Parent Accounts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                  scrollDirection: compact ? Axis.horizontal : Axis.vertical,
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final parent = parents[index];
                    final tile = ListTile(
                      dense: compact,
                      selected: selected?.id == parent.id,
                      leading: CircleAvatar(
                        radius: compact ? 18 : 20,
                        child: Icon(
                          Icons.family_restroom,
                          size: compact ? 18 : 24,
                        ),
                      ),
                      title: Text(parent.fullName),
                      subtitle: Text(
                        parent.mobileNumber.isNotEmpty
                            ? '${parent.mobileNumber}${parent.whatsappNumber.isNotEmpty ? ' • WhatsApp ${parent.whatsappNumber}' : ''}'
                            : parent.email,
                      ),
                      onTap: () => onSelect(parent),
                      trailing: compact
                          ? PopupMenuButton<String>(
                              onSelected: (value) => value == 'edit'
                                  ? onEdit(parent)
                                  : onDelete(parent),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 0,
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed: () => onEdit(parent),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete parent account',
                                  color: Theme.of(context).colorScheme.error,
                                  onPressed: () => onDelete(parent),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                    );
                    if (!compact) return tile;
                    return SizedBox(width: 260, child: Card(child: tile));
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
    final compact = MediaQuery.sizeOf(context).width < 800;
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
      padding: EdgeInsets.all(compact ? 12 : 20),
      children: [
        Text(
          'Welcome, ${widget.parent.fullName}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: compact ? 23 : null,
            fontWeight: FontWeight.bold,
          ),
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
    final compact = MediaQuery.sizeOf(context).width < 800;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: compact ? 24 : 34,
              backgroundImage: student.profileImageUrl.isEmpty
                  ? null
                  : NetworkImage(student.profileImageUrl),
              child: student.profileImageUrl.isEmpty
                  ? Icon(Icons.person, size: compact ? 24 : 34)
                  : null,
            ),
            SizedBox(width: compact ? 10 : 16),
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
                  Text(
                    'Father: ${student.fatherName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!compact)
              Chip(label: Text(student.isActive ? 'ACTIVE' : 'INACTIVE'))
            else
              Icon(
                student.isActive ? Icons.check_circle : Icons.cancel,
                color: student.isActive ? Colors.green : Colors.red,
                size: 20,
              ),
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
      _ParentModule('Attendance', Icons.fact_check_rounded, Color(0xFF2563EB)),
      _ParentModule('Timetable', Icons.schedule_rounded, Color(0xFF7C3AED)),
      _ParentModule('Homework', Icons.menu_book_rounded, Color(0xFF059669)),
      _ParentModule(
        'Date Sheet',
        Icons.calendar_month_rounded,
        Color(0xFFEA580C),
      ),
      _ParentModule('Results', Icons.star_rounded, Color(0xFFE11D48)),
      _ParentModule('Fee Status', Icons.payments_rounded, Color(0xFF0891B2)),
      _ParentModule(
        'Academic Calendar',
        Icons.event_rounded,
        Color(0xFF4F46E5),
      ),
      _ParentModule('Notices', Icons.campaign_rounded, Color(0xFFD97706)),
      _ParentModule(
        'Ask Administration',
        Icons.contact_support_rounded,
        Color(0xFF0F766E),
      ),
      _ParentModule(
        'Teacher Remarks',
        Icons.comment_rounded,
        Color(0xFF9333EA),
      ),
      _ParentModule('Timeline', Icons.timeline_rounded, Color(0xFF0284C7)),
      _ParentModule(
        'Medical Alert',
        Icons.medical_information_rounded,
        Color(0xFFDC2626),
      ),
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
            mainAxisExtent: constraints.maxWidth < 700 ? 108 : 132,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];

            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (module.title == 'Attendance') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentAttendancePage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.title == 'Homework') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentHomeworkPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.title == 'Results') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentResultsPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (module.title == 'Fee Status') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => ParentFeePage(student: student),
                      ),
                    );
                    return;
                  }

                  if (['Timetable', 'Date Sheet'].contains(module.title)) {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParentAcademicDashboardPage(student: student),
                      ),
                    );
                    return;
                  }

                  if (['Academic Calendar', 'Notices'].contains(module.title)) {
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

                  if (module.title == 'Ask Administration') {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParentQueryPage(parent: parent, student: student),
                      ),
                    );
                    return;
                  }

                  if (module.title == 'Timeline') {
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
                        '${module.title} integration will be connected '
                        'in Parent Portal Phase 4.',
                      ),
                    ),
                  );
                },
                child: Ink(
                  decoration: BoxDecoration(
                    color: module.color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: module.color.withValues(alpha: .22),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(module.icon, color: Colors.white, size: 27),
                        const SizedBox(height: 8),
                        Text(
                          module.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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

class _ParentModule {
  const _ParentModule(this.title, this.icon, this.color);

  final String title;
  final IconData icon;
  final Color color;
}
