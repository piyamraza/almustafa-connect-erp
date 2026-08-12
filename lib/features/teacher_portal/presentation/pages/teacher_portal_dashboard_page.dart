import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../authentication/domain/usecases/logout_usecase.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/pages/mark_attendance_page.dart';
import '../../../exams/domain/entities/exam_date_sheet_entity.dart';
import '../../../exams/domain/repositories/exam_date_sheet_repository.dart';
import '../../../exams/presentation/pages/question_paper_module_page.dart';
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
  const TeacherPortalDashboardPage({super.key});

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
    final teacher = await sl<TeacherRepository>().getTeacherByEmail(email);
    if (teacher == null) {
      throw StateError(
        'This login is not linked with a teacher profile. Ask Admin to use the same email on the teacher profile.',
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
      title: const Text('My Teaching'),
      actions: [
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
              _summary(data),
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
                                '${item.className}-${item.sectionName} • ${item.subjectName}',
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
                    : data.assignments
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.class_outlined),
                              title: Text('${item.classId}-${item.sectionId}'),
                              subtitle: Text(item.subject),
                            ),
                          )
                          .toList(),
              ),
              const SizedBox(height: 12),
              _section(
                context,
                'Upcoming Exams & Duties',
                data.upcomingPapers.isEmpty
                    ? const [Text('No upcoming assigned paper.')]
                    : data.upcomingPapers
                          .take(5)
                          .map(
                            (item) => ListTile(
                              leading: const Icon(Icons.event_note_outlined),
                              title: Text(
                                '${item.className}-${item.sectionName} • ${item.subjectName}',
                              ),
                              subtitle: Text(_date(item.examDate)),
                            ),
                          )
                          .toList(),
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

  Widget _summary(_TeacherDashboardData data) {
    final values = [
      ('Today', '${data.todayTimetable.length}', Icons.schedule),
      ('Students', '${data.students.length}', Icons.groups_outlined),
      ('Attendance', data.attendanceLabel, Icons.fact_check_outlined),
      ('Questions', '${data.pendingQuestions}', Icons.help_outline),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: .92,
      ),
      itemBuilder: (context, index) {
        final item = values[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$3, size: 22),
                const SizedBox(height: 4),
                Text(
                  item.$2,
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  item.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actions(BuildContext context, _TeacherDashboardData data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final assignment in data.uniqueClassSections)
            FilledButton.tonalIcon(
              onPressed: () => _open(
                context,
                MarkAttendancePage(
                  classId: assignment.classId,
                  sectionId: assignment.sectionId,
                  teacherMode: true,
                ),
              ),
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(
                'Attendance ${assignment.classId}-${assignment.sectionId}',
              ),
            ),
          FilledButton.tonalIcon(
            onPressed: () => _open(
              context,
              QuestionPaperModulePage(teacherAssignments: data.assignments),
            ),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Question Papers'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _open(
              context,
              HomeworkDashboardPage(teacherId: data.teacher.id),
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Homework & Syllabus'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _open(
              context,
              TeacherHomeworkQuestionsPage(teacher: data.teacher),
            ),
            icon: const Icon(Icons.question_answer_outlined),
            label: Text('Parent Questions (${data.pendingQuestions})'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _open(context, const TeacherLeaveDutiesPage()),
            icon: const Icon(Icons.event_busy_outlined),
            label: const Text('Leave Status'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _open(context, const InAppChatPage()),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Admin Chat'),
          ),
        ],
      ),
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

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
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

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
