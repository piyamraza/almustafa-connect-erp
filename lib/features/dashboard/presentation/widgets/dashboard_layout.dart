import 'package:flutter/material.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
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
  bool _isRefreshing = false;

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
    if (_isRefreshing) return;

    final refreshFuture = _loadDashboard();
    setState(() {
      _isRefreshing = true;
      _dashboardFuture = refreshFuture;
    });

    try {
      await refreshFuture;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Dashboard refreshed.'),
            duration: Duration(seconds: 2),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: isMobile
          ? AppBar(
              title: const Text('School Dashboard'),
              actions: [
                IconButton(
                  onPressed: _isRefreshing ? null : _refresh,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded, size: 21),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? const Drawer(width: 286, child: SafeArea(child: Sidebar()))
          : null,
      body: Row(
        children: [
          if (!isMobile) const SizedBox(width: 250, child: Sidebar()),
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
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 12 : 20,
                        isMobile ? 12 : 16,
                        isMobile ? 12 : 20,
                        16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 16 : 24,
                              vertical: isMobile ? 16 : 22,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: isMobile ? 42 : 52,
                                  height: isMobile ? 42 : 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.20,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.dashboard_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'School Dashboard',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      if (!isMobile) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'A live overview of students, attendance and school operations',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.82,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!isMobile)
                                  IconButton.filledTonal(
                                    onPressed: _isRefreshing ? null : _refresh,
                                    tooltip: 'Refresh dashboard',
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                      foregroundColor: Colors.white,
                                      disabledForegroundColor: Colors.white70,
                                    ),
                                    icon: _isRefreshing
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.refresh_rounded),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          _StatsGrid(data: data),
                          const SizedBox(height: 14),
                          _DashboardCharts(data: data),
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
                                    _UpcomingBirthdaysCard(
                                      birthdays: data.upcomingBirthdays,
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
                                    child: _UpcomingBirthdaysCard(
                                      birthdays: data.upcomingBirthdays,
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
        final featuredColumns = constraints.maxWidth < 650
            ? 1
            : constraints.maxWidth < 1050
            ? 2
            : 4;
        final operationalColumns = constraints.maxWidth < 650
            ? 1
            : constraints.maxWidth < 900
            ? 2
            : 5;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today at a glance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'The most important indicators for today',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: featuredColumns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              mainAxisExtent: featuredColumns == 1 ? 170 : 180,
              children: [
                _FeaturedStatCard(
                  title: 'Active Students',
                  value: '${data.activeStudents}',
                  detail: '${data.presentStudents} present today',
                  icon: Icons.school_rounded,
                  color: AppColors.primary,
                ),
                _FeaturedStatCard(
                  title: 'Present Students',
                  value: '${data.presentStudents}',
                  detail: 'Present today',
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.info,
                ),
                _FeaturedStatCard(
                  title: 'Attendance %',
                  value: data.attendancePercentage,
                  detail: 'Student attendance today',
                  icon: Icons.fact_check_rounded,
                  color: AppColors.success,
                ),
                _FeaturedStatCard(
                  title: 'Pending Attendance',
                  value: '${data.pendingAttendanceGroups.length}',
                  detail: data.pendingAttendanceGroups.isEmpty
                      ? 'All sections up to date'
                      : '${data.pendingAttendanceGroups.length} sections pending',
                  icon: Icons.pending_actions_rounded,
                  color: data.pendingAttendanceGroups.isEmpty
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Operations overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: operationalColumns,
              crossAxisSpacing: 14,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
              children: [
                DashboardStatCard(
                  title: 'Total Teachers',
                  value: '${data.teachers.length}',
                  icon: Icons.person_rounded,
                  color: const Color(0xFF42A54B),
                ),
                DashboardStatCard(
                  title: 'Teachers Present',
                  value: '${data.presentTeachers}',
                  icon: Icons.co_present_rounded,
                  color: AppColors.info,
                ),
                DashboardStatCard(
                  title: 'Total Staff',
                  value: '${data.staff.length}',
                  icon: Icons.groups_rounded,
                  color: const Color(0xFFE58A19),
                ),
                DashboardStatCard(
                  title: 'Staff Present',
                  value: '${data.presentStaff}',
                  icon: Icons.badge_rounded,
                  color: const Color(0xFFFF6B4A),
                ),
                DashboardStatCard(
                  title: 'Active Classes',
                  value:
                      '${data.classes.where((item) => item.isActive).length}',
                  icon: Icons.class_rounded,
                  color: const Color(0xFF8B5BD6),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Fee overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth < 650
                  ? 1
                  : constraints.maxWidth < 1050
                  ? 2
                  : 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 12,
              mainAxisExtent: 110,
              children: [
                DashboardStatCard(
                  title: "Today's Fee Collection",
                  value: _money(data.todayCollection),
                  detail: '${data.todayPaidStudents} students paid today',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.info,
                ),
                DashboardStatCard(
                  title: 'Monthly Fee Collection',
                  value: _money(data.monthCollection),
                  detail: '${data.monthPaidStudents} students paid this month',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF6657D9),
                ),
                DashboardStatCard(
                  title: 'Pending Fees',
                  value: _money(data.pendingFees),
                  detail: '${data.pendingFeeStudents} students pending',
                  icon: Icons.warning_amber_rounded,
                  color: data.pendingFees > 0
                      ? AppColors.error
                      : AppColors.success,
                ),
              ],
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

class _FeaturedStatCard extends StatelessWidget {
  const _FeaturedStatCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.10), Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
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

  Set<String> get _activeStudentIds => students
      .where((student) => student.isActive)
      .map((student) => student.id)
      .toSet();

  Set<String> get _presentActiveStudentIds => todayAttendance
      .where(
        (item) =>
            _activeStudentIds.contains(item.studentId) &&
            (item.status == AttendanceStatus.present ||
                item.status == AttendanceStatus.late),
      )
      .map((item) => item.studentId)
      .toSet();

  int get activeStudents => _activeStudentIds.length;
  int get presentStudents => _presentActiveStudentIds.length;

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
  List<_DashboardBirthday> get upcomingBirthdays {
    int days(DateTime dateOfBirth) {
      var birthday = DateTime(now.year, dateOfBirth.month, dateOfBirth.day);
      if (birthday.isBefore(DateTime(now.year, now.month, now.day))) {
        birthday = DateTime(now.year + 1, dateOfBirth.month, dateOfBirth.day);
      }
      return birthday.difference(DateTime(now.year, now.month, now.day)).inDays;
    }

    final classNames = {for (final item in classes) item.id: item.name};
    final values =
        <_DashboardBirthday>[
          ...students
              .where((item) => item.isActive)
              .map(
                (item) => _DashboardBirthday(
                  id: item.id,
                  name: item.fullName,
                  dateOfBirth: item.dateOfBirth,
                  type: _BirthdayPersonType.student,
                  details: [
                    if (item.fatherName.trim().isNotEmpty)
                      'Father: ${item.fatherName.trim()}',
                    'Class: ${classNames[item.classId] ?? item.classId}',
                  ].join('  •  '),
                ),
              ),
          ...teachers
              .where((item) => item.isActive)
              .map(
                (item) => _DashboardBirthday(
                  id: item.id,
                  name: item.fullName,
                  dateOfBirth: item.dateOfBirth,
                  type: _BirthdayPersonType.teacher,
                  details: item.designation.trim(),
                ),
              ),
          ...staff
              .where((item) => item.isActive && item.dateOfBirth != null)
              .map(
                (item) => _DashboardBirthday(
                  id: item.id,
                  name: item.fullName,
                  dateOfBirth: item.dateOfBirth!,
                  type: _BirthdayPersonType.staff,
                  details: item.designation.trim(),
                ),
              ),
        ].where((item) => days(item.dateOfBirth) <= 10).toList()..sort((a, b) {
          final dateOrder = days(a.dateOfBirth).compareTo(days(b.dateOfBirth));
          return dateOrder != 0 ? dateOrder : a.name.compareTo(b.name);
        });
    return List.unmodifiable(values);
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
    final activeIds = _activeStudentIds;
    final hasActiveStudentAttendance = todayAttendance.any(
      (item) => activeIds.contains(item.studentId),
    );
    if (activeIds.isEmpty || !hasActiveStudentAttendance) return 'No data';

    return '${(presentStudents * 100 / activeIds.length).toStringAsFixed(1)}%';
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
      final classComparison = compareAcademicClassNames(
        first.className,
        second.className,
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
          TextButton(onPressed: onOpen, child: const Text('Mark')),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: 0.24),
                            color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: color.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(title, style: const TextStyle(fontSize: 12.5)),
                          if (detail != null)
                            Text(
                              detail!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCharts extends StatelessWidget {
  const _DashboardCharts({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final attendance = _ClassAttendanceChart(data: data);
        final fees = _ClassFeeCollectionChart(data: data);
        if (constraints.maxWidth < 1050) {
          return Column(
            children: [attendance, const SizedBox(height: 14), fees],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: attendance),
            const SizedBox(width: 14),
            Expanded(child: fees),
          ],
        );
      },
    );
  }
}

class _ClassAttendanceChart extends StatelessWidget {
  const _ClassAttendanceChart({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final points = _points();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Class Attendance",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Present and absent students by class',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const _ChartLegend(color: AppColors.primary, label: 'Present'),
              const SizedBox(width: 14),
              const _ChartLegend(color: Color(0xFFFF8A5B), label: 'Absent'),
            ],
          ),
          const SizedBox(height: 18),
          if (points.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 34),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.query_stats_rounded,
                    color: AppColors.primary,
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Class attendance will appear after attendance is marked.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 250,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 100,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.75),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 25,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 9,
                                child: Text(
                                  points[index].className,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.ink,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = points[group.x];
                            return BarTooltipItem(
                              '${point.className}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${point.present} present • ${point.absent} absent',
                                  style: const TextStyle(
                                    color: Color(0xFFD8E6FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      barGroups: [
                        for (var index = 0; index < points.length; index++)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: 100,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    points[index].presentPercentage,
                                    AppColors.primary,
                                  ),
                                  BarChartRodStackItem(
                                    points[index].presentPercentage,
                                    100,
                                    const Color(0xFFFF8A5B),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ClassAttendancePoint> _points() {
    final activeClasses = data.classes.where((item) => item.isActive).toList()
      ..sort(
        (first, second) => compareAcademicClassNames(first.name, second.name),
      );
    final result = <_ClassAttendancePoint>[];

    for (final academicClass in activeClasses) {
      final recordsByStudent = <String, AttendanceStatus>{};
      for (final record in data.todayAttendance) {
        final sameClass =
            record.classId == academicClass.id ||
            record.classId.trim().toLowerCase() ==
                academicClass.name.trim().toLowerCase();
        final sameDay =
            record.attendanceDate.year == data.now.year &&
            record.attendanceDate.month == data.now.month &&
            record.attendanceDate.day == data.now.day;
        if (sameClass && sameDay) {
          recordsByStudent[record.studentId] = record.status;
        }
      }
      if (recordsByStudent.isEmpty) continue;

      final present = recordsByStudent.values
          .where(
            (status) =>
                status == AttendanceStatus.present ||
                status == AttendanceStatus.late,
          )
          .length;
      result.add(
        _ClassAttendancePoint(
          className: academicClass.name,
          present: present,
          absent: recordsByStudent.length - present,
        ),
      );
    }
    return result;
  }
}

class _ClassFeeCollectionChart extends StatelessWidget {
  const _ClassFeeCollectionChart({required this.data});

  final _DashboardData data;

  @override
  Widget build(BuildContext context) {
    final points = _points();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0F9D74).withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D74).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Class Fee Collection',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Paid and pending students this month',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const _ChartLegend(color: Color(0xFF10B981), label: 'Paid'),
              const SizedBox(width: 12),
              const _ChartLegend(color: Color(0xFFFFB020), label: 'Pending'),
            ],
          ),
          const SizedBox(height: 18),
          if (points.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 34),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF0F9D74),
                    size: 34,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Current month fee dues have not been generated yet.',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 250,
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth,
                  child: BarChart(
                    BarChartData(
                      minY: 0,
                      maxY: 100,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.75),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: 25,
                            getTitlesWidget: (value, meta) => Text(
                              '${value.toInt()}%',
                              style: const TextStyle(
                                color: AppColors.inkMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 9,
                                child: Text(
                                  points[index].className,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.ink,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final point = points[group.x];
                            return BarTooltipItem(
                              '${point.className}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      '${point.paid} paid • ${point.pending} pending',
                                  style: const TextStyle(
                                    color: Color(0xFFDDF8ED),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      barGroups: [
                        for (var index = 0; index < points.length; index++)
                          BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: 100,
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                                rodStackItems: [
                                  BarChartRodStackItem(
                                    0,
                                    points[index].paidPercentage,
                                    const Color(0xFF10B981),
                                  ),
                                  BarChartRodStackItem(
                                    points[index].paidPercentage,
                                    100,
                                    const Color(0xFFFFB020),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_ClassFeePoint> _points() {
    final activeClasses = data.classes.where((item) => item.isActive).toList()
      ..sort((a, b) => compareAcademicClassNames(a.name, b.name));
    final result = <_ClassFeePoint>[];
    for (final academicClass in activeClasses) {
      final duesByStudent = <String, MonthlyFeeDueEntity>{};
      for (final due in data.dues) {
        final sameClass =
            due.classId == academicClass.id ||
            due.classId.trim().toLowerCase() ==
                academicClass.name.trim().toLowerCase();
        if (sameClass &&
            due.year == data.now.year &&
            due.month == data.now.month &&
            due.status != MonthlyFeeDueStatus.cancelled) {
          duesByStudent[due.studentId] = due;
        }
      }
      if (duesByStudent.isEmpty) continue;
      final paid = duesByStudent.values
          .where((due) => due.outstandingAmount <= 0)
          .length;
      result.add(
        _ClassFeePoint(
          className: academicClass.name,
          paid: paid,
          pending: duesByStudent.length - paid,
        ),
      );
    }
    return result;
  }
}

class _ClassFeePoint {
  const _ClassFeePoint({
    required this.className,
    required this.paid,
    required this.pending,
  });

  final String className;
  final int paid;
  final int pending;

  double get paidPercentage {
    final total = paid + pending;
    return total == 0 ? 0 : paid * 100 / total;
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ClassAttendancePoint {
  const _ClassAttendancePoint({
    required this.className,
    required this.present,
    required this.absent,
  });

  final String className;
  final int present;
  final int absent;

  double get presentPercentage {
    final total = present + absent;
    return total == 0 ? 0 : present * 100 / total;
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionHeading(
              title: 'Recent Admissions',
              subtitle: 'Newest students enrolled in school',
              icon: Icons.person_add_alt_1_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            if (students.isEmpty)
              const _DashboardEmptyState(
                icon: Icons.school_outlined,
                color: AppColors.primary,
                message: 'No student admissions found.',
              )
            else
              ...students.indexed.map((entry) {
                final index = entry.$1;
                final student = entry.$2;
                var className = student.classId;
                for (final academicClass in classes) {
                  if (academicClass.id == student.classId ||
                      academicClass.name == student.classId) {
                    className = academicClass.name;
                  }
                }
                final rowColor = index.isEven
                    ? AppColors.primary.withValues(alpha: 0.035)
                    : Colors.white;
                return Container(
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: rowColor,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          student.fullName.trim().isEmpty
                              ? '?'
                              : student.fullName.trim()[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              student.admissionNo,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          className,
                          style: const TextStyle(
                            color: AppColors.info,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _UpcomingBirthdaysCard extends StatelessWidget {
  const _UpcomingBirthdaysCard({required this.birthdays});
  final List<_DashboardBirthday> birthdays;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Upcoming Birthdays',
      subtitle: 'Celebrations in the next 10 days',
      icon: Icons.cake_rounded,
      color: const Color(0xFFE54868),
      children: birthdays.isEmpty
          ? const [
              _DashboardEmptyState(
                icon: Icons.cake_outlined,
                color: Color(0xFFE54868),
                message: 'No birthdays in the next 10 days.',
              ),
            ]
          : birthdays
                .map(
                  (birthday) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFE8EF),
                      child: Icon(Icons.cake, color: Color(0xFFE54868)),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            birthday.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _BirthdayTypeBadge(type: birthday.type),
                      ],
                    ),
                    subtitle: Text(
                      [
                        '${birthday.dateOfBirth.day}/${birthday.dateOfBirth.month}',
                        if (birthday.details.isNotEmpty) birthday.details,
                      ].join('  •  '),
                    ),
                  ),
                )
                .toList(),
    );
  }
}

enum _BirthdayPersonType { student, teacher, staff }

class _DashboardBirthday {
  const _DashboardBirthday({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    required this.type,
    required this.details,
  });

  final String id;
  final String name;
  final DateTime dateOfBirth;
  final _BirthdayPersonType type;
  final String details;
}

class _BirthdayTypeBadge extends StatelessWidget {
  const _BirthdayTypeBadge({required this.type});

  final _BirthdayPersonType type;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (type) {
      _BirthdayPersonType.student => ('Student', const Color(0xFF2563EB)),
      _BirthdayPersonType.teacher => ('Teacher', const Color(0xFF7C3AED)),
      _BirthdayPersonType.staff => ('Staff', const Color(0xFF0F9D74)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
      subtitle: 'Recently published announcements',
      icon: Icons.campaign_rounded,
      color: const Color(0xFFE58A19),
      children: notices.isEmpty
          ? const [
              _DashboardEmptyState(
                icon: Icons.notifications_none_rounded,
                color: Color(0xFFE58A19),
                message: 'No published notices found.',
              ),
            ]
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
  final String? subtitle;
  final IconData? icon;
  final Color color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.08), Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeading(
              title: title,
              subtitle: subtitle,
              icon: icon ?? Icons.dashboard_customize_rounded,
              color: color,
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.72)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
