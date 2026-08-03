import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/presentation/pages/class_section_management_page.dart';
import '../../../attendance/domain/entities/attendance_entity.dart';
import '../../../attendance/domain/repositories/attendance_repository.dart';
import '../../../attendance/presentation/pages/mark_attendance_page.dart';
import '../../../fees/domain/entities/fee_payment_entity.dart';
import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../fees/domain/repositories/fee_payment_repository.dart';
import '../../../fees/domain/repositories/monthly_fee_due_repository.dart';
import '../../../fees/presentation/pages/fee_management_dashboard_page.dart';
import '../../../notices/presentation/pages/notices_dashboard_page.dart';
import '../../../notices/domain/entities/notice_entity.dart';
import '../../../notices/domain/repositories/notice_repository.dart';
import '../../../staff/domain/entities/staff_entity.dart';
import '../../../staff/domain/entities/staff_attendance_entity.dart';
import '../../../staff/domain/repositories/staff_attendance_repository.dart';
import '../../../staff/domain/repositories/staff_repository.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/entities/teacher_attendance_entity.dart';
import '../../../teachers/domain/repositories/teacher_attendance_repository.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import 'sidebar.dart';

class DashboardLayout extends StatefulWidget {
  const DashboardLayout({super.key});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<List<T>> _safe<T>(Future<List<T>> request) async {
    try {
      return await request;
    } catch (_) {
      return <T>[];
    }
  }

  Future<_DashboardData> _loadDashboard() async {
    final now = DateTime.now();
    final values = await Future.wait<Object>([
      _safe(sl<StudentRepository>().getStudents()),
      _safe(sl<TeacherRepository>().getTeachers()),
      _safe(sl<StaffRepository>().getStaff()),
      _safe(sl<AcademicStructureRepository>().getClasses()),
      _safe(sl<AcademicStructureRepository>().getSections()),
      _safe(sl<AttendanceRepository>().getAttendanceByDate(now)),
      _safe(sl<FeePaymentRepository>().getPayments()),
      _safe(sl<MonthlyFeeDueRepository>().getMonthlyDues()),
      _safe(
        sl<NoticeRepository>().getNotices(
          academicSession: _academicSession(now),
        ),
      ),
      _safe(sl<TeacherAttendanceRepository>().getByDate(now)),
      _safe(sl<StaffAttendanceRepository>().getAttendanceByDate(now)),
    ]);
    return _DashboardData(
      students: values[0] as List<StudentEntity>,
      teachers: values[1] as List<TeacherEntity>,
      staff: values[2] as List<StaffEntity>,
      classes: values[3] as List<AcademicClassEntity>,
      sections: values[4] as List<SectionEntity>,
      todayAttendance: values[5] as List<AttendanceEntity>,
      payments: values[6] as List<FeePaymentEntity>,
      dues: values[7] as List<MonthlyFeeDueEntity>,
      notices: values[8] as List<NoticeEntity>,
      teacherAttendance: values[9] as List<TeacherAttendanceEntity>,
      staffAttendance: values[10] as List<StaffAttendanceEntity>,
      now: now,
    );
  }

  String _academicSession(DateTime date) {
    final startYear = date.month >= 7 ? date.year : date.year - 1;
    return '$startYear-${startYear + 1}';
  }

  Future<void> _refresh() async {
    setState(() => _dashboardFuture = _loadDashboard());
    await _dashboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          const SizedBox(width: 250, child: Sidebar()),
          Expanded(
            child: SafeArea(
              child: FutureBuilder<_DashboardData>(
                future: _dashboardFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dashboard',
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Live overview of Almustafa Connect ERP',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _refresh,
                                tooltip: 'Refresh dashboard',
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _StatsGrid(data: data),
                          const SizedBox(height: 14),
                          _PendingAttendanceCard(
                            groups: data.pendingAttendanceGroups,
                            onOpen: (group) async {
                              final navigator = Navigator.of(context);
                              await navigator.push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => MarkAttendancePage(
                                    attendanceDate: data.now,
                                    classId: group.classId,
                                    sectionId: group.sectionId,
                                  ),
                                ),
                              );
                              if (!mounted) {
                                return;
                              }
                              await _refresh();
                            },
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final admissions = RecentAdmissionsCard(
                                students: data.recentStudents,
                                classes: data.classes,
                              );
                              if (constraints.maxWidth < 1000) {
                                return Column(
                                  children: [
                                    admissions,
                                    const SizedBox(height: 14),
                                    UpcomingBirthdaysCard(
                                      students: data.upcomingBirthdays,
                                    ),
                                    const SizedBox(height: 14),
                                    LatestNoticesCard(
                                      notices: data.latestNotices,
                                    ),
                                    const SizedBox(height: 14),
                                    const QuickActionsCard(),
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: admissions),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: UpcomingBirthdaysCard(
                                      students: data.upcomingBirthdays,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        LatestNoticesCard(
                                          notices: data.latestNotices,
                                        ),
                                        const SizedBox(height: 14),
                                        const QuickActionsCard(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});
  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 650
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : constraints.maxWidth < 1200
            ? 3
            : 5;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            DashboardStatCard(
              title: 'Total Active Students',
              value: '${data.activeStudents}',
              icon: Icons.school,
              color: Colors.blue,
            ),
            DashboardStatCard(
              title: 'Present Students',
              value: '${data.presentStudents}',
              icon: Icons.how_to_reg,
              color: Colors.cyan,
            ),
            DashboardStatCard(
              title: 'Attendance %',
              value: data.attendancePercentage,
              icon: Icons.fact_check,
              color: Colors.teal,
            ),
            DashboardStatCard(
              title: 'Pending Attendance',
              value: '${data.pendingAttendanceGroups.length}',
              detail: data.pendingAttendanceGroups.isNotEmpty
                  ? 'class sections need attention'
                  : null,
              icon: Icons.pending_actions_outlined,
              color: data.pendingAttendanceGroups.isNotEmpty
                  ? Colors.red
                  : Colors.green,
            ),
            DashboardStatCard(
              title: 'Total Teachers',
              value: '${data.teachers.length}',
              icon: Icons.person,
              color: Colors.green,
            ),
            DashboardStatCard(
              title: 'Present Teachers',
              value: '${data.presentTeachers}',
              icon: Icons.co_present_outlined,
              color: Colors.teal,
            ),
            DashboardStatCard(
              title: 'Total Staff',
              value: '${data.staff.length}',
              icon: Icons.groups,
              color: Colors.orange,
            ),
            DashboardStatCard(
              title: 'Present Staff',
              value: '${data.presentStaff}',
              icon: Icons.badge_outlined,
              color: Colors.deepOrange,
            ),
            DashboardStatCard(
              title: 'Active Classes',
              value: '${data.classes.where((item) => item.isActive).length}',
              icon: Icons.class_,
              color: Colors.purple,
            ),
            DashboardStatCard(
              title: "Today's Fee Collection",
              value: _money(data.todayCollection),
              detail: '${data.todayPaidStudents} students paid today',
              icon: Icons.payments,
              color: Colors.indigo,
            ),
            DashboardStatCard(
              title: 'Monthly Fee Collection',
              value: _money(data.monthCollection),
              detail: '${data.monthPaidStudents} students paid this month',
              icon: Icons.account_balance_wallet,
              color: Colors.deepPurple,
            ),
            DashboardStatCard(
              title: 'Pending Fees',
              value: _money(data.pendingFees),
              detail: '${data.pendingFeeStudents} students pending',
              icon: Icons.warning_amber,
              color: Colors.red,
            ),
          ],
        );
      },
    );
  }

  static String _money(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return 'Rs. $buffer';
  }
}

class _DashboardData {
  const _DashboardData({
    required this.students,
    required this.teachers,
    required this.staff,
    required this.classes,
    required this.sections,
    required this.todayAttendance,
    required this.payments,
    required this.dues,
    required this.notices,
    required this.teacherAttendance,
    required this.staffAttendance,
    required this.now,
  });
  final List<StudentEntity> students;
  final List<TeacherEntity> teachers;
  final List<StaffEntity> staff;
  final List<AcademicClassEntity> classes;
  final List<SectionEntity> sections;
  final List<AttendanceEntity> todayAttendance;
  final List<FeePaymentEntity> payments;
  final List<MonthlyFeeDueEntity> dues;
  final List<NoticeEntity> notices;
  final List<TeacherAttendanceEntity> teacherAttendance;
  final List<StaffAttendanceEntity> staffAttendance;
  final DateTime now;

  int get activeStudents => students.where((student) => student.isActive).length;
  int get presentStudents => todayAttendance
      .where(
        (item) =>
            item.status == AttendanceStatus.present ||
            item.status == AttendanceStatus.late,
      )
      .map((item) => item.studentId)
      .toSet()
      .length;

  int get presentTeachers => teacherAttendance
      .where((item) => item.status == TeacherAttendanceStatus.present)
      .map((item) => item.teacherId)
      .toSet()
      .length;
  int get presentStaff => staffAttendance
      .where((item) => item.status == StaffAttendanceStatus.present)
      .map((item) => item.staffId)
      .toSet()
      .length;

  List<StudentEntity> get recentStudents =>
      (students.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
          .take(4)
          .toList();
  List<StudentEntity> get upcomingBirthdays {
    int days(StudentEntity student) {
      var birthday = DateTime(
        now.year,
        student.dateOfBirth.month,
        student.dateOfBirth.day,
      );
      if (birthday.isBefore(DateTime(now.year, now.month, now.day))) {
        birthday = DateTime(
          now.year + 1,
          student.dateOfBirth.month,
          student.dateOfBirth.day,
        );
      }
      return birthday.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    final values =
        students
            .where((student) => student.isActive && days(student) <= 30)
            .toList()
          ..sort((a, b) => days(a).compareTo(days(b)));
    return values.take(2).toList();
  }

  List<NoticeEntity> get latestNotices {
    final values =
        notices
            .where(
              (notice) =>
                  notice.status == NoticeStatus.published && !notice.isExpired,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return values.take(2).toList();
  }

  String get attendancePercentage {
    if (todayAttendance.isEmpty) return 'No data';
    final present = todayAttendance
        .where(
          (item) =>
              item.status == AttendanceStatus.present ||
              item.status == AttendanceStatus.late,
        )
        .length;
    return '${(present * 100 / todayAttendance.length).toStringAsFixed(1)}%';
  }

  List<_PendingAttendanceGroup> get pendingAttendanceGroups {
    final activeClasses = classes.where((item) => item.isActive).toList();
    final activeSections = sections.where((item) => item.isActive).toList();
    final builders = <String, _PendingAttendanceGroupBuilder>{};

    for (final student in students.where((item) => item.isActive)) {
      final academicClass = _classFor(student.classId, activeClasses);
      if (academicClass == null) {
        continue;
      }

      final section = _sectionFor(
        classId: academicClass.id,
        value: student.sectionId,
        values: activeSections,
      );
      final key = _attendanceGroupKey(academicClass.id, section?.id);
      final builder = builders.putIfAbsent(
        key,
        () => _PendingAttendanceGroupBuilder(
          classId: academicClass.id,
          className: academicClass.name,
          sectionId: section?.id,
          sectionName: section?.name,
        ),
      );
      builder.studentIds.add(student.id);
    }

    for (final record in todayAttendance.where(
      (item) => _sameDay(item.attendanceDate, now),
    )) {
      final academicClass = _classFor(record.classId, activeClasses);
      if (academicClass == null) {
        continue;
      }

      final section = _sectionFor(
        classId: academicClass.id,
        value: record.sectionId,
        values: activeSections,
      );
      final key = _attendanceGroupKey(academicClass.id, section?.id);
      final builder = builders[key];
      if (builder != null) {
        builder.recordedStudentIds.add(record.studentId);
      }
    }

    final pending = builders.values
        .map(
          (builder) => _PendingAttendanceGroup(
            classId: builder.classId,
            className: builder.className,
            sectionId: builder.sectionId,
            sectionName: builder.sectionName,
            totalStudents: builder.studentIds.length,
            markedStudents: builder.recordedStudentIds
                .intersection(builder.studentIds)
                .length,
          ),
        )
        .where((group) => group.markedStudents < group.totalStudents)
        .toList();

    pending.sort((first, second) {
      final classComparison = first.className.toLowerCase().compareTo(
        second.className.toLowerCase(),
      );
      if (classComparison != 0) {
        return classComparison;
      }
      return first.sectionNameOrEmpty.toLowerCase().compareTo(
        second.sectionNameOrEmpty.toLowerCase(),
      );
    });
    return pending;
  }

  static AcademicClassEntity? _classFor(
    String value,
    List<AcademicClassEntity> values,
  ) {
    final normalized = value.trim().toLowerCase();
    for (final item in values) {
      if (item.id.trim().toLowerCase() == normalized ||
          item.name.trim().toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  static SectionEntity? _sectionFor({
    required String classId,
    required String value,
    required List<SectionEntity> values,
  }) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    for (final item in values) {
      if (item.classId == classId &&
          (item.id.trim().toLowerCase() == normalized ||
              item.name.trim().toLowerCase() == normalized)) {
        return item;
      }
    }
    return null;
  }

  static String _attendanceGroupKey(String classId, String? sectionId) {
    return '$classId|${sectionId ?? ''}';
  }

  double get todayCollection => payments
      .where(
        (item) =>
            item.status == FeePaymentStatus.completed &&
            _sameDay(item.paymentDate, now),
      )
      .fold(0, (sum, item) => sum + item.totalPaid);
  int get todayPaidStudents => payments
      .where(
        (item) =>
            item.status == FeePaymentStatus.completed &&
            _sameDay(item.paymentDate, now),
      )
      .map((item) => item.studentId)
      .toSet()
      .length;
  double get monthCollection => payments
      .where(
        (item) =>
            item.status == FeePaymentStatus.completed &&
            item.paymentDate.year == now.year &&
            item.paymentDate.month == now.month,
      )
      .fold(0, (sum, item) => sum + item.totalPaid);
  int get monthPaidStudents => payments
      .where(
        (item) =>
            item.status == FeePaymentStatus.completed &&
            item.paymentDate.year == now.year &&
            item.paymentDate.month == now.month,
      )
      .map((item) => item.studentId)
      .toSet()
      .length;
  double get pendingFees => dues
      .where((item) => item.status != MonthlyFeeDueStatus.cancelled)
      .fold(0, (sum, item) => sum + item.outstandingAmount);
  int get pendingFeeStudents => dues
      .where(
        (item) =>
            item.status != MonthlyFeeDueStatus.cancelled &&
            item.outstandingAmount > 0,
      )
      .map((item) => item.studentId)
      .toSet()
      .length;
  static bool _sameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class _PendingAttendanceGroupBuilder {
  _PendingAttendanceGroupBuilder({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
  });

  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final Set<String> studentIds = <String>{};
  final Set<String> recordedStudentIds = <String>{};
}

class _PendingAttendanceGroup {
  const _PendingAttendanceGroup({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.totalStudents,
    required this.markedStudents,
  });

  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final int totalStudents;
  final int markedStudents;

  String get sectionNameOrEmpty => sectionName ?? '';
  String get title => sectionName == null || sectionName!.isEmpty
      ? className
      : '$className - ${sectionName!}';
  bool get hasNoAttendance => markedStudents == 0;
  int get remainingStudents => totalStudents - markedStudents;
}

class _PendingAttendanceCard extends StatelessWidget {
  const _PendingAttendanceCard({required this.groups, required this.onOpen});

  final List<_PendingAttendanceGroup> groups;
  final ValueChanged<_PendingAttendanceGroup> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: groups.isEmpty
                      ? Colors.green.withValues(alpha: 0.12)
                      : colorScheme.errorContainer,
                  child: Icon(
                    groups.isEmpty
                        ? Icons.task_alt_outlined
                        : Icons.warning_amber_rounded,
                    color: groups.isEmpty
                        ? Colors.green.shade700
                        : colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Pending Attendance",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        groups.isEmpty
                            ? 'All active class sections are up to date.'
                            : '${groups.length} class section(s) still need attendance.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (groups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No pending student attendance for today.'),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoColumns = constraints.maxWidth >= 760;
                  final tileWidth = twoColumns
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: groups
                        .map(
                          (group) => SizedBox(
                            width: tileWidth,
                            child: _PendingAttendanceTile(
                              group: group,
                              onOpen: () => onOpen(group),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PendingAttendanceTile extends StatelessWidget {
  const _PendingAttendanceTile({required this.group, required this.onOpen});

  final _PendingAttendanceGroup group;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final incomplete = !group.hasNoAttendance;

    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: incomplete
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.38)
            : colorScheme.errorContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            incomplete ? Icons.timelapse_outlined : Icons.event_busy_outlined,
            color: incomplete
                ? colorScheme.onTertiaryContainer
                : colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  incomplete
                      ? '${group.markedStudents}/${group.totalStudents} marked - ${group.remainingStudents} remaining'
                      : '${group.totalStudents} students - not marked yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onOpen,
            child: const Text('Mark'),
          ),
        ],
      ),
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? detail;
  final IconData icon;
  final Color color;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    this.detail,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 18),
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(title, style: const TextStyle(fontSize: 12.5)),
                  if (detail != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecentAdmissionsCard extends StatelessWidget {
  const RecentAdmissionsCard({
    super.key,
    required this.students,
    required this.classes,
  });
  final List<StudentEntity> students;
  final List<AcademicClassEntity> classes;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Admissions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No student admissions found.')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Admission #')),
                    DataColumn(label: Text('Student')),
                    DataColumn(label: Text('Class')),
                  ],
                  rows: students.map((student) {
                    var className = student.classId;
                    for (final academicClass in classes) {
                      if (academicClass.id == student.classId ||
                          academicClass.name == student.classId) {
                        className = academicClass.name;
                      }
                    }
                    return DataRow(
                      cells: [
                        DataCell(Text(student.admissionNo)),
                        DataCell(Text(student.fullName)),
                        DataCell(Text(className)),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class UpcomingBirthdaysCard extends StatelessWidget {
  const UpcomingBirthdaysCard({super.key, required this.students});
  final List<StudentEntity> students;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Upcoming Birthdays',
      children: students.isEmpty
          ? const [Text('No birthdays in the next 30 days.')]
          : students
                .map(
                  (student) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFE8EF),
                      child: Icon(Icons.cake, color: Color(0xFFE54868)),
                    ),
                    title: Text(student.fullName),
                    subtitle: Text(
                      '${student.dateOfBirth.day}/${student.dateOfBirth.month}',
                    ),
                  ),
                )
                .toList(),
    );
  }
}

class LatestNoticesCard extends StatelessWidget {
  const LatestNoticesCard({super.key, required this.notices});
  final List<NoticeEntity> notices;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Latest Notices',
      children: notices.isEmpty
          ? const [Text('No published notices found.')]
          : notices
                .map(
                  (notice) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.notifications,
                      color: notice.priority == NoticePriority.emergency
                          ? Colors.red
                          : Colors.blue,
                    ),
                    title: Text(
                      notice.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
    );
  }
}

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StudentsPage()),
              ),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Student'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ClassSectionManagementPage(),
                ),
              ),
              icon: const Icon(Icons.class_),
              label: const Text('Classes'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FeeManagementDashboardPage(),
                ),
              ),
              icon: const Icon(Icons.payments),
              label: const Text('Fee'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NoticesDashboardPage(),
                ),
              ),
              icon: const Icon(Icons.campaign),
              label: const Text('Notice'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
