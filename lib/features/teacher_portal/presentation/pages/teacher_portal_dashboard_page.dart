import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/subject_component_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/repositories/subject_component_repository.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../access_control/data/services/user_account_service_impl.dart';
import '../../../authentication/domain/usecases/logout_usecase.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/pages/mark_attendance_page.dart';
import '../../../exams/domain/entities/exam_date_sheet_entity.dart';
import '../../../exams/domain/repositories/exam_date_sheet_repository.dart';
import '../../../exams/presentation/pages/question_paper_module_page.dart';
import '../../../exam_seating/domain/entities/exam_seating_entities.dart';
import '../../../exam_seating/domain/repositories/exam_seating_repository.dart';
import '../../../homework/domain/entities/homework_entity.dart';
import '../../../homework/domain/entities/homework_question_entity.dart';
import '../../../homework/domain/repositories/homework_question_repository.dart';
import '../../../homework/domain/repositories/homework_repository.dart';
import '../../../homework/presentation/pages/homework_dashboard_page.dart';
import '../../../communication/presentation/pages/in_app_chat_page.dart';
import '../../../notices/domain/entities/notice_entity.dart';
import '../../../notices/domain/repositories/notice_repository.dart';
import '../../../notifications/domain/entities/portal_notification_entity.dart';
import '../../../notifications/domain/repositories/portal_notification_repository.dart';
import '../../../notifications/presentation/pages/portal_notification_center_page.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../../timetable/domain/entities/class_timetable_entry_entity.dart';
import '../../../timetable/domain/repositories/timetable_repository.dart';
import 'teacher_homework_questions_page.dart';
import 'teacher_leave_duties_page.dart';

class TeacherPortalDashboardPage extends StatefulWidget {
  const TeacherPortalDashboardPage({
    super.key,
    this.teacherId,
    this.previewMode = false,
  });

  final String? teacherId;
  final bool previewMode;

  @override
  State<TeacherPortalDashboardPage> createState() =>
      _TeacherPortalDashboardPageState();
}

class _TeacherPortalDashboardPageState
    extends State<TeacherPortalDashboardPage> {
  static const _session = '2026-2027';
  late Future<_TeacherDashboardData> _future;
  StreamSubscription<RemoteMessage>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _future = _load();
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }
    _messageSubscription = FirebaseMessaging.onMessage.listen((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _future = _load());
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  Future<_TeacherDashboardData> _load() async {
    final access = sl<AccessControlService>();
    final email = access.currentUserEmail?.trim().toLowerCase() ?? '';
    final repository = sl<TeacherRepository>();
    final previewTeacherId = widget.teacherId?.trim() ?? '';
    final linkedTeacherId = previewTeacherId.isNotEmpty
        ? previewTeacherId
        : access.assignment?.linkedEntityType == 'teacher'
        ? access.assignment?.linkedEntityId.trim() ?? ''
        : '';
    final teacher = linkedTeacherId.isNotEmpty
        ? await repository.getTeacherById(linkedTeacherId)
        : await repository.getTeacherByEmail(email);
    if (teacher == null) {
      throw StateError(
        'This login is not linked with a teacher profile. Ask Admin to select the teacher record in User Accounts.',
      );
    }

    final assignments =
        (await sl<TeacherAssignmentRepository>().getAssignmentsForTeacher(
              teacher.id,
            ))
            .where(
              (item) =>
                  item.teacherId == teacher.id &&
                  _sameText(item.academicSession, _session),
            )
            .toList();
    final results = await Future.wait<Object>([
      _loadPart(
        'timetable',
        sl<TimetableRepository>().getTeacherTimetable(
          branchId: 'main',
          academicSession: _session,
          teacherId: teacher.id,
        ),
      ),
      _loadPart(
        'homework',
        sl<HomeworkRepository>().getHomework(
          academicSession: _session,
          teacherId: teacher.id,
        ),
      ),
      _loadPart(
        'homework questions',
        sl<HomeworkQuestionRepository>().getForTeacher(teacher.id),
      ),
      _loadPart('assigned students', sl<StudentRepository>().getStudents()),
      _loadPart(
        'attendance',
        sl<AttendanceRepository>().getAttendanceByDate(DateTime.now()),
      ),
      _loadPart(
        'exam date sheets',
        sl<ExamDateSheetRepository>().getDateSheets(academicSession: _session),
      ),
      _loadPart(
        'notices',
        sl<NoticeRepository>().getNotices(
          academicSession: _session,
          status: NoticeStatus.published,
        ),
      ),
      _loadPart(
        'notifications',
        sl<PortalNotificationRepository>().getNotifications(
          recipientType: PortalRecipientType.teacher,
          recipientId: teacher.id,
          isRead: false,
        ),
      ),
      _loadPart('classes', sl<AcademicStructureRepository>().getClasses()),
      _loadPart('sections', sl<AcademicStructureRepository>().getSections()),
      _loadPart('exam duties', sl<ExamSeatingRepository>().getPlans()),
      _loadPart('subjects', sl<AcademicStructureRepository>().getSubjects()),
      _loadPart(
        'subject components',
        sl<SubjectComponentRepository>().getComponents(),
      ),
    ]);

    final students = (results[3] as List<StudentEntity>)
        .where(
          (student) => assignments.any((assignment) {
            return _sameText(assignment.classId, student.classId) &&
                _sameText(assignment.sectionId, student.sectionId);
          }),
        )
        .toList();
    final studentIds = students.map((item) => item.id).toSet();
    final attendance = (results[4] as List<AttendanceEntity>)
        .where((item) => studentIds.contains(item.studentId))
        .toList();
    final dateSheets = results[5] as List<ExamDateSheetEntity>;
    final papers = dateSheets
        .expand((sheet) => sheet.papers)
        .where((paper) => paper.teacherId == teacher.id)
        .toList();
    final notices = (results[6] as List<NoticeEntity>)
        .where(
          (item) =>
              item.audienceType == NoticeAudienceType.wholeSchool ||
              item.audienceType == NoticeAudienceType.teachers,
        )
        .toList();

    return _TeacherDashboardData(
      teacher: teacher,
      assignments: assignments,
      timetable: results[0] as List<ClassTimetableEntryEntity>,
      homework: results[1] as List<HomeworkEntity>,
      questions: results[2] as List<HomeworkQuestionEntity>,
      students: students,
      attendance: attendance,
      examPapers: papers,
      notices: notices,
      unreadNotifications:
          (results[7] as List<PortalNotificationEntity>).length,
      classes: results[8] as List<AcademicClassEntity>,
      sections: results[9] as List<SectionEntity>,
      todayDuties: (results[10] as List<DailyExamPlanEntity>)
          .where(
            (plan) =>
                plan.status == ExamPlanStatus.finalized &&
                _sameDay(plan.examDate, DateTime.now()),
          )
          .expand(
            (plan) => plan.teacherAssignments
                .where((duty) => duty.teacherId == teacher.id)
                .map((duty) => _TodayTeacherDuty(plan: plan, duty: duty)),
          )
          .toList(),
      subjects: results[11] as List<AcademicSubjectEntity>,
      subjectComponents: results[12] as List<SubjectComponentEntity>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _logout() async {
    try {
      await sl<LogoutUseCase>()();
    } finally {
      await sl<AccessControlService>().clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<T> _loadPart<T>(String label, Future<T> request) async {
    try {
      return await request;
    } catch (error) {
      throw StateError('Unable to load teacher $label: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      title: Text(
        widget.previewMode ? 'Teacher Portal Preview' : 'My Teaching',
      ),
      actions: [
        if (!widget.previewMode)
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
      ],
    ),
    body: FutureBuilder<_TeacherDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_off, size: 52),
                  const SizedBox(height: 12),
                  Text('${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
            children: [
              _header(context, data),
              const SizedBox(height: 12),
              _actions(context, data),
              const SizedBox(height: 12),
              _section(
                context,
                'Today’s Timetable',
                data.todayTimetable.isEmpty
                    ? const [Text('No class scheduled for today.')]
                    : data.todayTimetable
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.schedule),
                              title: Text(
                                '${item.className}-${item.sectionName} • ${data.periodSubjectName(item)}',
                              ),
                              subtitle: Text(item.periodLabel),
                            ),
                          )
                          .toList(),
              ),
              const SizedBox(height: 12),
              _section(
                context,
                'Assigned Classes & Subjects',
                data.assignments.isEmpty
                    ? const [Text('No active teaching assignment found.')]
                    : [_assignedClassesTable(data)],
              ),
              const SizedBox(height: 12),
              _section(
                context,
                'Today’s Duty',
                data.todayDuties.isEmpty
                    ? const [Text('No examination duty assigned for today.')]
                    : data.todayDuties.map(_dutyTile).toList(),
              ),
              const SizedBox(height: 12),
              _section(
                context,
                'Teacher Notices',
                data.notices.isEmpty
                    ? const [Text('No current teacher notice.')]
                    : data.notices
                          .take(5)
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.campaign_outlined),
                              title: Text(item.title),
                              subtitle: Text(
                                item.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _header(BuildContext context, _TeacherDashboardData data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            child: Text(
              data.teacher.firstName.isEmpty
                  ? 'T'
                  : data.teacher.firstName[0].toUpperCase(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.teacher.fullName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('${data.teacher.designation} • $_session'),
              ],
            ),
          ),
          Badge(
            label: Text('${data.unreadNotifications}'),
            isLabelVisible: data.unreadNotifications > 0,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => _open(
                context,
                PortalNotificationCenterPage(
                  recipientType: PortalRecipientType.teacher,
                  recipientId: data.teacher.id,
                ),
              ),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _actions(BuildContext context, _TeacherDashboardData data) {
    final actions = [
      _TeacherAction(
        'Mark Attendance',
        Icons.how_to_reg_rounded,
        const Color(0xFF2563EB),
        () => _showAttendanceClasses(data),
      ),
      _TeacherAction(
        'Question Papers',
        Icons.quiz_rounded,
        const Color(0xFF7C3AED),
        () => _open(
          context,
          QuestionPaperModulePage(teacherAssignments: data.assignments),
        ),
      ),
      _TeacherAction(
        'Homework & Syllabus',
        Icons.menu_book_rounded,
        const Color(0xFF0F9D76),
        () => _open(context, HomeworkDashboardPage(teacherId: data.teacher.id)),
      ),
      _TeacherAction(
        'Parent Questions (${data.pendingQuestions})',
        Icons.question_answer_rounded,
        const Color(0xFFF59E0B),
        () =>
            _open(context, TeacherHomeworkQuestionsPage(teacher: data.teacher)),
      ),
      _TeacherAction(
        'Leave Status',
        Icons.event_busy_rounded,
        const Color(0xFFE14D5A),
        () => _open(context, const TeacherLeaveDutiesPage()),
      ),
      _TeacherAction(
        'Admin Chat',
        Icons.forum_rounded,
        const Color(0xFF0891B2),
        () => _openTeacherChat(data),
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth >= 1050
                  ? 6
                  : constraints.maxWidth >= 600
                  ? 3
                  : 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 122,
            ),
            itemBuilder: (_, index) => _TeacherActionCard(actions[index]),
          ),
        ),
      ),
    );
  }

  Future<void> _showAttendanceClasses(_TeacherDashboardData data) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark Attendance'),
        content: SizedBox(
          width: 520,
          child: data.uniqueClassSections.isEmpty
              ? const Text('No assigned class or section found.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.uniqueClassSections.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final assignment = data.uniqueClassSections[index];
                    return ListTile(
                      leading: const Icon(Icons.class_rounded),
                      title: Text(data.classSectionLabel(assignment)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _open(
                          context,
                          MarkAttendancePage(
                            classId: assignment.classId,
                            sectionId: assignment.sectionId,
                            teacherMode: true,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openTeacherChat(_TeacherDashboardData data) async {
    if (!widget.previewMode) {
      _open(context, const InAppChatPage(teacherMode: true));
      return;
    }
    try {
      final accounts = await UserAccountServiceImpl().listChatParticipants();
      final matches = accounts.where(
        (account) =>
            account.isActive &&
            !account.disabled &&
            account.linkedEntityType.toLowerCase() == 'teacher' &&
            account.linkedEntityId == data.teacher.id,
      );
      if (!mounted) return;
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This teacher does not have a linked active user account.',
            ),
          ),
        );
        return;
      }
      _open(
        context,
        InAppChatPage(
          userIdOverride: matches.first.uid,
          userNameOverride: data.teacher.fullName,
          teacherMode: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teacher chat could not be opened: $error')),
      );
    }
  }

  Widget _assignedClassesTable(_TeacherDashboardData data) {
    final rows = data.assignedClassRows;
    final subjectColumns = rows.fold<int>(
      1,
      (count, row) => row.$2.length > count ? row.$2.length : count,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final desiredWidth = 220.0 + (subjectColumns * 180.0);
        final tableWidth = desiredWidth > constraints.maxWidth
            ? desiredWidth
            : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Table(
              border: TableBorder.all(color: const Color(0xFFD7E0EE)),
              columnWidths: {
                0: const FixedColumnWidth(220),
                for (var index = 1; index <= subjectColumns; index++)
                  index: const FlexColumnWidth(),
              },
              children: [
                _tableRow([
                  'Class / Section',
                  for (var index = 1; index <= subjectColumns; index++)
                    'Subject $index',
                ], header: true),
                for (final row in rows)
                  _tableRow([
                    row.$1,
                    for (var index = 0; index < subjectColumns; index++)
                      index < row.$2.length ? row.$2[index] : '—',
                  ]),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _tableRow(List<String> values, {bool header = false}) => TableRow(
    decoration: BoxDecoration(
      color: header ? const Color(0xFFE8F0FF) : Colors.white,
    ),
    children: [
      for (final value in values)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: header ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
    ],
  );

  static Widget _dutyTile(_TodayTeacherDuty item) => ListTile(
    leading: const Icon(Icons.meeting_room_rounded, color: Color(0xFF2563EB)),
    title: Text(
      item.duty.isRest
          ? 'Rest Day'
          : item.duty.roomName.isEmpty
          ? 'Paper Support'
          : item.duty.roomName,
    ),
    subtitle: Text(
      '${item.duty.isRest
          ? 'Rest'
          : item.duty.isPaperSupport
          ? 'Paper Support'
          : 'Invigilator'} • ${item.plan.sessionLabel}',
    ),
  );

  static Widget _section(
    BuildContext context,
    String title,
    List<Widget> children,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ...children,
        ],
      ),
    ),
  );

  static void _open(BuildContext context, Widget page) => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => page));

  static bool _sameText(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _TeacherDashboardData {
  const _TeacherDashboardData({
    required this.teacher,
    required this.assignments,
    required this.timetable,
    required this.homework,
    required this.questions,
    required this.students,
    required this.attendance,
    required this.examPapers,
    required this.notices,
    required this.unreadNotifications,
    required this.classes,
    required this.sections,
    required this.todayDuties,
    required this.subjects,
    required this.subjectComponents,
  });

  final TeacherEntity teacher;
  final List<TeacherAssignmentEntity> assignments;
  final List<ClassTimetableEntryEntity> timetable;
  final List<HomeworkEntity> homework;
  final List<HomeworkQuestionEntity> questions;
  final List<StudentEntity> students;
  final List<AttendanceEntity> attendance;
  final List<ExamDateSheetPaperEntity> examPapers;
  final List<NoticeEntity> notices;
  final int unreadNotifications;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<_TodayTeacherDuty> todayDuties;
  final List<AcademicSubjectEntity> subjects;
  final List<SubjectComponentEntity> subjectComponents;

  String classSectionLabel(TeacherAssignmentEntity assignment) {
    final academicClass = classes.where((item) {
      return _same(item.id, assignment.classId) ||
          _same(item.name, assignment.classId);
    }).firstOrNull;
    final section = sections.where((item) {
      final belongsToClass =
          academicClass == null ||
          _same(item.classId, academicClass.id) ||
          _same(item.classId, assignment.classId);
      return belongsToClass &&
          (_same(item.id, assignment.sectionId) ||
              _same(item.name, assignment.sectionId));
    }).firstOrNull;
    final rawClass = academicClass?.name ?? assignment.classId;
    final className = RegExp(r'^\d+$').hasMatch(rawClass.trim())
        ? 'Class ${rawClass.trim()}'
        : rawClass.trim();
    final sectionName = (section?.name ?? assignment.sectionId).trim();
    return [
      className,
      sectionName,
    ].where((value) => value.isNotEmpty).join(' - ');
  }

  static bool _same(String first, String second) =>
      first.trim().toLowerCase() == second.trim().toLowerCase();

  List<(String, List<String>)> get assignedClassRows {
    final grouped = <String, Set<String>>{};
    for (final assignment in assignments) {
      grouped
          .putIfAbsent(classSectionLabel(assignment), () => <String>{})
          .add(subjectDisplayName(assignment));
    }
    final rows =
        grouped.entries
            .map(
              (entry) => (
                entry.key,
                entry.value.where((e) => e.isNotEmpty).toList()..sort(),
              ),
            )
            .toList()
          ..sort((a, b) => a.$1.compareTo(b.$1));
    return rows;
  }

  String subjectDisplayName(TeacherAssignmentEntity assignment) {
    return _parentSubjectName(
      assignment.subject,
      assignment.classId,
      assignment.sectionId,
    );
  }

  String periodSubjectName(ClassTimetableEntryEntity entry) =>
      _parentSubjectName(entry.subjectName, entry.classId, entry.sectionId);

  String _parentSubjectName(
    String value,
    String classReference,
    String sectionReference,
  ) {
    final assignedName = value.trim();
    final relevantSubjects = subjects.where(
      (subject) =>
          (_same(subject.classId, classReference) ||
              classes.any(
                (item) =>
                    _same(item.id, subject.classId) &&
                    _same(item.name, classReference),
              )) &&
          (subject.sectionId == null ||
              _same(subject.sectionId!, sectionReference)),
    );
    for (final subject in relevantSubjects) {
      if (_same(subject.name, assignedName)) return subject.name.trim();
      final components = subjectComponents.where(
        (component) =>
            component.isActive && component.parentSubjectId == subject.id,
      );
      for (final component in components) {
        final componentName = component.componentName.trim();
        final displayName =
            componentName.toLowerCase().startsWith(
              subject.name.trim().toLowerCase(),
            )
            ? componentName
            : '${subject.name.trim()} $componentName';
        if (_same(displayName, assignedName) ||
            _same(componentName, assignedName)) {
          return subject.name.trim();
        }
      }
    }
    return assignedName;
  }

  List<ClassTimetableEntryEntity> get todayTimetable {
    final values =
        timetable
            .where((item) => item.weekday == DateTime.now().weekday)
            .toList()
          ..sort((a, b) => a.periodOrder.compareTo(b.periodOrder));
    return values;
  }

  List<ExamDateSheetPaperEntity> get upcomingPapers {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final values =
        examPapers.where((item) => !item.examDate.isBefore(start)).toList()
          ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return values;
  }

  int get pendingQuestions => questions
      .where((item) => item.status == HomeworkQuestionStatus.newQuestion)
      .length;

  String get attendanceLabel => '${attendance.length}/${students.length}';

  List<TeacherAssignmentEntity> get uniqueClassSections {
    final seen = <String>{};
    return assignments
        .where(
          (item) => seen.add(
            '${item.classId.trim().toLowerCase()}|${item.sectionId.trim().toLowerCase()}',
          ),
        )
        .toList();
  }
}

class _TodayTeacherDuty {
  const _TodayTeacherDuty({required this.plan, required this.duty});

  final DailyExamPlanEntity plan;
  final TeacherDutyAssignmentEntity duty;
}

class _TeacherAction {
  const _TeacherAction(this.label, this.icon, this.color, this.onTap);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _TeacherActionCard extends StatelessWidget {
  const _TeacherActionCard(this.action);

  final _TeacherAction action;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: action.onTap,
    child: Ink(
      decoration: BoxDecoration(
        color: action.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: action.color.withValues(alpha: .24),
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
            Icon(action.icon, color: Colors.white, size: 34),
            const SizedBox(height: 9),
            Text(
              action.label,
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
  );
}
