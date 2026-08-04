[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\teacher_portal_phase1_$stamp"

function Full([string]$p) { Join-Path $root $p }
function WriteUtf8([string]$p,[string]$t) {
  $f = Full $p
  $d = Split-Path $f -Parent
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  [IO.File]::WriteAllText($f,$t.Replace("`r`n","`n"),$utf8)
}
function BackupFile([string]$p) {
  $s = Full $p
  if (-not (Test-Path $s)) { return }
  $t = Join-Path $backup $p
  $d = Split-Path $t -Parent
  if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
  Copy-Item $s $t -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$dashboard = 'lib/features/dashboard/presentation/pages/dashboard_page.dart'
$teacher = 'lib/features/teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart'

if (-not (Test-Path (Full $dashboard))) {
  throw "REQUIRED FILE ERROR: $dashboard"
}
if (Test-Path (Full $teacher)) {
  throw 'EXISTING FILE ERROR: Teacher Portal Phase 1 appears installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
BackupFile $dashboard

WriteUtf8 $teacher @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/entities/app_permission.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../communication/presentation/pages/communication_dashboard_page.dart';
import '../../../exams/presentation/pages/exam_date_sheet_dashboard_page.dart';
import '../../../homework/presentation/pages/homework_dashboard_page.dart';
import '../../../notices/presentation/pages/notices_dashboard_page.dart';
import '../../../results/presentation/pages/results_module_page.dart';
import '../../../settings/presentation/pages/security_sessions_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../../timetable/presentation/pages/timetable_dashboard_page.dart';

class TeacherPortalDashboardPage extends StatelessWidget {
  const TeacherPortalDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final access = sl<AccessControlService>();
    final name = access.currentUserEmail?.trim().isNotEmpty == true
        ? access.currentUserEmail!
        : 'Teacher';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          SizedBox(
            width: 250,
            child: _TeacherMenu(access: access),
          ),
          Expanded(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Welcome, $name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Teacher workspace for daily academic activities'),
                  const SizedBox(height: 18),
                  const _SummaryCards(),
                  const SizedBox(height: 18),
                  _QuickActions(access: access),
                  const SizedBox(height: 18),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Day',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.schedule),
                            title: Text('Today timetable'),
                            subtitle: Text(
                              'Live teacher assignments will be connected in Phase 2.',
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.pending_actions_outlined),
                            title: Text('Pending work'),
                            subtitle: Text(
                              'Attendance, homework and marks counters will be connected in Phase 2.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherMenu extends StatelessWidget {
  const _TeacherMenu({required this.access});

  final AccessControlService access;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF5FF), Color(0xFFCFE7FF)],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(10, 20, 10, 20),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'TEACHER PORTAL',
              style: TextStyle(
                color: Color(0xFF183B5B),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _tile(context, Icons.dashboard_outlined, 'Dashboard'),
          if (access.hasPermission(AppPermission.attendanceView))
            _tile(
              context,
              Icons.fact_check_outlined,
              'Attendance',
              const AttendancePage(),
            ),
          if (access.hasPermission(AppPermission.homeworkView))
            _tile(
              context,
              Icons.menu_book_outlined,
              'Homework',
              const HomeworkDashboardPage(),
            ),
          if (access.hasPermission(AppPermission.dateSheetsView))
            _tile(
              context,
              Icons.calendar_month_outlined,
              'Date Sheet',
              const ExamDateSheetDashboardPage(),
            ),
          if (access.hasPermission(AppPermission.resultsView))
            _tile(
              context,
              Icons.grade_outlined,
              'Results',
              const ResultsModulePage(),
            ),
          if (access.hasPermission(AppPermission.studentsView))
            _tile(
              context,
              Icons.groups_outlined,
              'My Students',
              const StudentsPage(),
            ),
          if (access.hasPermission(AppPermission.timetableView))
            _tile(
              context,
              Icons.schedule_outlined,
              'My Timetable',
              const TimetableDashboardPage(),
            ),
          if (access.hasPermission(AppPermission.noticesView))
            _tile(
              context,
              Icons.campaign_outlined,
              'Notices',
              const NoticesDashboardPage(),
            ),
          if (access.hasPermission(AppPermission.noticesView))
            _tile(
              context,
              Icons.forum_outlined,
              'Communication',
              const CommunicationDashboardPage(),
            ),
          _tile(
            context,
            Icons.security_outlined,
            'Profile & Security',
            const SecuritySessionsPage(),
          ),
        ],
      ),
    );
  }

  static Widget _tile(
    BuildContext context,
    IconData icon,
    String title, [
    Widget? page,
  ]) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF24557A)),
      title: Text(title),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      onTap: page == null
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => page),
              );
            },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    const values = [
      ('Today Classes', Icons.class_outlined),
      ('Attendance Pending', Icons.pending_actions_outlined),
      ('Homework Pending', Icons.assignment_outlined),
      ('Unread Messages', Icons.mark_chat_unread_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 600
                ? 2
                : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: values
              .map(
                (item) => SizedBox(
                  width: width,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(child: Icon(item.$2)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.$1),
                                const Text(
                                  '--',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.access});

  final AccessControlService access;

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, Widget)>[
      if (access.hasPermission(AppPermission.attendanceMark))
        ('Mark Attendance', Icons.how_to_reg_outlined, const AttendancePage()),
      if (access.hasPermission(AppPermission.homeworkCreate))
        ('Add Homework', Icons.post_add_outlined, const HomeworkDashboardPage()),
      if (access.hasPermission(AppPermission.resultsEnter))
        ('Enter Marks', Icons.edit_note_outlined, const ResultsModulePage()),
      if (access.hasPermission(AppPermission.noticesManage))
        ('Class Notice', Icons.campaign_outlined, const NoticesDashboardPage()),
      if (access.hasPermission(AppPermission.noticesView))
        ('Parent Message', Icons.chat_outlined, const CommunicationDashboardPage()),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 14),
            if (actions.isEmpty)
              const Text('No teacher action permissions are assigned yet.'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: actions
                  .map(
                    (action) => FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => action.$3,
                          ),
                        );
                      },
                      icon: Icon(action.$2),
                      label: Text(action.$1),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
'@

WriteUtf8 $dashboard @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../teacher_portal/presentation/pages/teacher_portal_dashboard_page.dart';
import '../widgets/dashboard_layout.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final AccessControlService _access;

  @override
  void initState() {
    super.initState();
    _access = sl<AccessControlService>();
    _access.addListener(_refresh);
    _access.loadCurrentAccess();
  }

  @override
  void dispose() {
    _access.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _isTeacher {
    final name = _access.role?.name.trim().toLowerCase() ?? '';
    final id = _access.role?.id.trim().toLowerCase() ?? '';
    return name.contains('teacher') || id.contains('teacher');
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isLoading || !_access.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isTeacher) {
      return const TeacherPortalDashboardPage();
    }

    return const DashboardLayout();
  }
}
'@

& dart format lib/features/teacher_portal $dashboard
if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/teacher_portal `
  $dashboard `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "TEACHER PORTAL ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'Teacher Portal Phase 1 installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Teacher-role users now receive a dedicated dashboard and restricted menu.' -ForegroundColor Yellow
Write-Host 'Phase 2 will connect teacher assignments and live My Day data.' -ForegroundColor Yellow
