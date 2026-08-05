[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

$root=(Get-Location).Path
$utf8=New-Object System.Text.UTF8Encoding($false)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backup=Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\parent_login_integration_$stamp"

function Full([string]$p){Join-Path $root $p}
function BackupFile([string]$p){
  $source=Full $p
  if(Test-Path $source){
    $target=Join-Path $backup $p
    New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent)|Out-Null
    Copy-Item $source $target -Force
  }
}
function WriteText([string]$p,[string]$text){
  $file=Full $p
  New-Item -ItemType Directory -Force -Path (Split-Path $file -Parent)|Out-Null
  [IO.File]::WriteAllText($file,$text.Replace("`r`n","`n"),$utf8)
}

if(-not(Test-Path (Full 'pubspec.yaml'))){throw 'Run from project root.'}

$dashboard='lib/features/dashboard/presentation/pages/dashboard_page.dart'
$workspace='lib/features/parent_portal/presentation/pages/parent_workspace_page.dart'

BackupFile $dashboard
BackupFile $workspace

WriteText $workspace @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../authentication/domain/usecases/logout_usecase.dart';
import '../../../authentication/presentation/pages/login_page.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../domain/services/parent_context_service.dart';
import '../widgets/parent_portal_access_gate.dart';
import 'parent_academic_dashboard_page.dart';

class ParentWorkspacePage extends StatelessWidget {
  const ParentWorkspacePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ParentPortalAccessGate(
      builder: (context, parentContext) {
        final parent = parentContext.currentParent!;
        final student = parentContext.currentStudent!;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Parent Portal'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () {
                  parentContext.loadCurrentParent(forceRefresh: true);
                },
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: () => _logout(context, parentContext),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 14,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.family_restroom, size: 30),
                      ),
                      SizedBox(
                        width: 320,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              parent.fullName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              parent.mobileNumber.trim().isEmpty
                                  ? 'Parent Account'
                                  : parent.mobileNumber,
                            ),
                          ],
                        ),
                      ),
                      if (parentContext.linkedStudents.length > 1)
                        SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<String>(
                            value: student.id,
                            decoration: const InputDecoration(
                              labelText: 'Select Child',
                              border: OutlineInputBorder(),
                            ),
                            items: parentContext.linkedStudents
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.id,
                                    child: Text(item.fullName),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              if (value != null) {
                                parentContext.selectStudent(value);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StudentCard(student: student),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.school_outlined),
                  ),
                  title: const Text('Open Complete Parent Dashboard'),
                  subtitle: const Text(
                    'Attendance, homework, results, notices and academic progress.',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ParentAcademicDashboardPage(student: student),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout(
    BuildContext context,
    ParentContextService parentContext,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !context.mounted) return;

    await parentContext.clear();
    await sl<LogoutUseCase>()();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student});

  final StudentEntity student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _Info(label: 'Student', value: student.fullName),
            _Info(label: 'Admission No.', value: student.admissionNo),
            _Info(label: 'Class', value: student.classId),
            _Info(label: 'Section', value: student.sectionId),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(
            value.trim().isEmpty ? '-' : value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
'@

WriteText $dashboard @'
import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../access_control/domain/services/access_control_service.dart';
import '../../../parent_portal/presentation/pages/parent_workspace_page.dart';
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
    if (mounted) {
      setState(() {});
    }
  }

  bool get _isParentWorkspace {
    if (_access.isBootstrapAccess) return false;
    return _access.hasRole('parent');
  }

  bool get _isTeacherWorkspace {
    if (_access.isBootstrapAccess) return false;
    return _access.hasRole('teacher');
  }

  @override
  Widget build(BuildContext context) {
    if (_access.isLoading || !_access.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isParentWorkspace) {
      return const ParentWorkspacePage();
    }

    if (_isTeacherWorkspace) {
      return const TeacherPortalDashboardPage();
    }

    return const DashboardLayout();
  }
}
'@

dart format $dashboard $workspace
if($LASTEXITCODE -ne 0){throw "FORMAT ERROR. Backup: $backup"}

flutter analyze lib/features/dashboard lib/features/parent_portal lib/features/authentication --no-fatal-infos --no-fatal-warnings
if($LASTEXITCODE -ne 0){throw "ANALYZE ERROR. Backup: $backup"}

Write-Host ''
Write-Host 'Parent login integration completed successfully.' -ForegroundColor Green
Write-Host 'Parent role now opens Parent Workspace.' -ForegroundColor Green
Write-Host 'Teacher role still opens Teacher Portal.' -ForegroundColor Green
Write-Host 'Admin and other authorized roles still open Main Dashboard.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
