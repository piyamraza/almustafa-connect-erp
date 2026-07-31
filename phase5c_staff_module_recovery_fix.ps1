$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

function Backup-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath
    )

    if (-not (Test-Path -LiteralPath $FullPath)) {
        throw "Required file not found: $FullPath"
    }

    $backupPath = "$FullPath.staff_final_recovery_$timestamp.bak"
    Copy-Item -LiteralPath $FullPath -Destination $backupPath -Force
    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
}

function Save-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullPath,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    [System.IO.File]::WriteAllText(
        $FullPath,
        $Content,
        $utf8NoBom
    )

    Write-Host "Updated: $FullPath" -ForegroundColor Green
}

function Add-ImportIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,

        [Parameter(Mandatory = $true)]
        [string]$ExistingImport,

        [Parameter(Mandatory = $true)]
        [string]$NewImport
    )

    if ($Content.Contains($NewImport)) {
        return $Content
    }

    if (-not $Content.Contains($ExistingImport)) {
        throw "Import marker not found: $ExistingImport"
    }

    return $Content.Replace(
        $ExistingImport,
        "$ExistingImport`r`n$NewImport"
    )
}

function Patch-AttendancePage {
    $relativePath =
        "lib\features\staff\presentation\pages\staff_attendance_page.dart"
    $fullPath = Join-Path $projectRoot $relativePath

    Backup-File $fullPath

    $content = [System.IO.File]::ReadAllText($fullPath)

    $content = Add-ImportIfMissing `
        -Content $content `
        -ExistingImport "import 'staff_attendance_history_page.dart';" `
        -NewImport "import 'staff_attendance_report_page.dart';"

    if (-not $content.Contains("void _openAttendanceReport()")) {
        $methodPattern = "(?m)^  void _openHistory\(\) \{"

        $methodReplacement = @'
  void _openAttendanceReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffAttendanceReportPage(),
      ),
    );
  }

  void _openHistory() {
'@

        $updated = [regex]::Replace(
            $content,
            $methodPattern,
            $methodReplacement,
            1
        )

        if ($updated -eq $content) {
            throw "Attendance _openHistory method marker was not found."
        }

        $content = $updated
    }

    if (-not $content.Contains("tooltip: 'Attendance Report'")) {
        $titleActionsPattern =
            "(?ms)(title:\s*const Text\('Staff Attendance'\),\s*" +
            "actions:\s*\[\s*)"

        $actionBlock = @'
            IconButton(
              tooltip: 'Attendance Report',
              onPressed: _openAttendanceReport,
              icon: const Icon(
                Icons.description_outlined,
              ),
            ),
'@

        $updated = [regex]::Replace(
            $content,
            $titleActionsPattern,
            "`${1}`r`n$actionBlock",
            1
        )

        if ($updated -eq $content) {
            $historyActionPattern =
                "(?ms)(\s*IconButton\(\s*" +
                "tooltip:\s*'Attendance History',)"

            $updated = [regex]::Replace(
                $content,
                $historyActionPattern,
                "`r`n$actionBlock`${1}",
                1
            )
        }

        if ($updated -eq $content) {
            throw "Unable to insert Attendance Report AppBar action."
        }

        $content = $updated
    }

    Save-File `
        -FullPath $fullPath `
        -Content $content
}

function Patch-LeavePage {
    $relativePath =
        "lib\features\staff\presentation\pages\staff_leave_page.dart"
    $fullPath = Join-Path $projectRoot $relativePath

    Backup-File $fullPath

    $content = [System.IO.File]::ReadAllText($fullPath)

    $content = Add-ImportIfMissing `
        -Content $content `
        -ExistingImport "import 'staff_leave_history_page.dart';" `
        -NewImport "import 'staff_leave_report_page.dart';"

    if (-not $content.Contains("void _openLeaveReport()")) {
        $methodPattern = "(?m)^  void _openHistory\(\) \{"

        $methodReplacement = @'
  void _openLeaveReport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            const StaffLeaveReportPage(),
      ),
    );
  }

  void _openHistory() {
'@

        $updated = [regex]::Replace(
            $content,
            $methodPattern,
            $methodReplacement,
            1
        )

        if ($updated -eq $content) {
            throw "Leave _openHistory method marker was not found."
        }

        $content = $updated
    }

    if (-not $content.Contains("tooltip: 'Leave Report'")) {
        $titleActionsPattern =
            "(?ms)(title:\s*const Text\('Staff Leave Management'\),\s*" +
            "actions:\s*\[\s*)"

        $actionBlock = @'
            IconButton(
              tooltip: 'Leave Report',
              onPressed: _openLeaveReport,
              icon: const Icon(
                Icons.description_outlined,
              ),
            ),
'@

        $updated = [regex]::Replace(
            $content,
            $titleActionsPattern,
            "`${1}`r`n$actionBlock",
            1
        )

        if ($updated -eq $content) {
            $approvalActionPattern =
                "(?ms)(\s*IconButton\(\s*" +
                "tooltip:\s*'Pending Approvals',)"

            $updated = [regex]::Replace(
                $content,
                $approvalActionPattern,
                "`r`n$actionBlock`${1}",
                1
            )
        }

        if ($updated -eq $content) {
            throw "Unable to insert Leave Report AppBar action."
        }

        $content = $updated
    }

    Save-File `
        -FullPath $fullPath `
        -Content $content
}

function Replace-AttendanceReportPage {
    $relativePath =
        "lib\features\staff\presentation\pages\staff_attendance_report_page.dart"
    $fullPath = Join-Path $projectRoot $relativePath

    Backup-File $fullPath

    $content = @'
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../../domain/repositories/staff_repository.dart';
import '../services/staff_reports_pdf_service.dart';

class StaffAttendanceReportPage extends StatefulWidget {
  const StaffAttendanceReportPage({super.key});

  @override
  State<StaffAttendanceReportPage> createState() =>
      _StaffAttendanceReportPageState();
}

class _StaffAttendanceReportPageState
    extends State<StaffAttendanceReportPage> {
  late DateTime _selectedMonth;
  late Future<List<StaffAttendanceReportRow>>
      _reportFuture;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedMonth = DateTime(
      now.year,
      now.month,
      1,
    );

    _reportFuture = _loadReport();
  }

  bool get _canMoveNext {
    final now = DateTime.now();

    return _selectedMonth.year < now.year ||
        (_selectedMonth.year == now.year &&
            _selectedMonth.month < now.month);
  }

  DateTime get _monthEnd {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
  }

  Future<List<StaffAttendanceReportRow>>
      _loadReport() async {
    final attendanceRepository =
        sl<StaffAttendanceRepository>();

    final staffRepository = sl<StaffRepository>();

    final records =
        await attendanceRepository.getAttendanceByDateRange(
      startDate: _selectedMonth,
      endDate: _monthEnd,
    );

    final staff = await staffRepository.getStaff();

    return StaffReportsPdfService.buildAttendanceRows(
      staff: staff,
      records: records,
    );
  }

  void _refreshReport() {
    setState(() {
      _reportFuture = _loadReport();
    });
  }

  void _showPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );

      _reportFuture = _loadReport();
    });
  }

  void _showNextMonth() {
    if (!_canMoveNext) {
      return;
    }

    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );

      _reportFuture = _loadReport();
    });
  }

  void _showCurrentMonth() {
    final now = DateTime.now();

    setState(() {
      _selectedMonth = DateTime(
        now.year,
        now.month,
        1,
      );

      _reportFuture = _loadReport();
    });
  }

  String _fileName() {
    final month =
        _selectedMonth.month.toString().padLeft(2, '0');

    return 'Staff_Attendance_Report_'
        '${_selectedMonth.year}_$month.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Attendance Report'),
        actions: [
          IconButton(
            tooltip: 'Previous Month',
            onPressed: _showPreviousMonth,
            icon: const Icon(
              Icons.chevron_left_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Current Month',
            onPressed: _showCurrentMonth,
            icon: const Icon(
              Icons.today_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Next Month',
            onPressed:
                _canMoveNext ? _showNextMonth : null,
            icon: const Icon(
              Icons.chevron_right_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshReport,
            icon: const Icon(
              Icons.refresh_outlined,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          FutureBuilder<List<StaffAttendanceReportRow>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _ReportErrorView(
              title:
                  'Unable to load attendance report',
              message: snapshot.error.toString(),
              onRetry: _refreshReport,
            );
          }

          final rows = snapshot.data ??
              const <StaffAttendanceReportRow>[];

          final hasMarkedAttendance = rows.any(
            (row) => row.totalMarkedDays > 0,
          );

          if (!hasMarkedAttendance) {
            return const _EmptyReportView(
              title: 'No attendance records found',
              message:
                  'No staff attendance records are available for the selected month.',
              icon: Icons.fact_check_outlined,
            );
          }

          return PdfPreview(
            pdfFileName: _fileName(),
            initialPageFormat:
                PdfPageFormat.a4.landscape,
            canChangeOrientation: true,
            canChangePageFormat: true,
            allowPrinting: true,
            allowSharing: true,
            build: (pageFormat) {
              return StaffReportsPdfService
                  .buildAttendanceReportPdf(
                rows: rows,
                month: _selectedMonth,
                pageFormat: pageFormat,
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyReportView extends StatelessWidget {
  const _EmptyReportView({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              icon,
              size: 70,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportErrorView extends StatelessWidget {
  const _ReportErrorView({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_outlined,
              ),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
'@

    Save-File `
        -FullPath $fullPath `
        -Content $content
}

function Write-CompletionDocument {
    $relativePath = "DOCS\15_STAFF_MODULE_COMPLETION.md"
    $fullPath = Join-Path $projectRoot $relativePath
    $directory = Split-Path -Parent $fullPath

    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory `
            -Path $directory `
            -Force | Out-Null
    }

    if (Test-Path -LiteralPath $fullPath) {
        Backup-File $fullPath
    }

    $content = @'
# Almustafa Connect ERP - Staff Module Completion

## Status

The Staff Module is functionally complete.

## Completed Features

### Staff Profiles

- Add staff
- Edit staff
- Delete staff
- Search staff
- Active and inactive status
- Staff details and directory
- Employment and salary information

### Staff Attendance

- Daily attendance marking
- Present, Absent, Late and Leave statuses
- Mark all present
- Attendance remarks
- Attendance history
- Monthly staff attendance
- Monthly attendance PDF report
- PDF preview, print, share and download

### Staff Leave Management

- Casual, Sick, Annual, Unpaid and Other leave
- Full-day and half-day leave
- Pending, Approved, Rejected and Cancelled statuses
- Approval and rejection remarks
- Staff-wise leave history
- Monthly leave summary
- Monthly leave PDF report
- PDF preview, print, share and download

### Attendance and Leave Integration

- Approved leave automatically marks attendance as Leave
- Existing attendance is updated instead of duplicated
- Leave type and duration are stored in attendance remarks

### Staff Salary Management

- Monthly salary generation
- Basic salary from staff profile
- Attendance counts
- Allowance
- Other deduction
- Attendance and unpaid-leave deduction
- Gross and net salary
- Paid and Unpaid status
- Payment date, method and reference
- Salary details and history

### Salary and Leave Integration

- Approved Unpaid Leave calculates salary deduction
- Half-day unpaid leave deducts 0.5 day
- Paid salary records preserve saved deductions

### Payroll Reports

- Individual Salary Slip PDF
- Monthly Payroll PDF Report
- PDF preview, print, share and download
- Payroll Excel export
- Payroll Summary worksheet
- Payroll Details worksheet

## Validation

Run:

```cmd
cd /d D:\Projects\almustafa-connect-erp
flutter analyze
```

Runtime testing can be completed later from the Staff Dashboard.
'@

    Save-File `
        -FullPath $fullPath `
        -Content $content
}

Write-Host ""
Write-Host "Applying recovery patches..." -ForegroundColor Cyan

$requiredCreatedFiles = @(
    "lib\features\staff\presentation\services\staff_reports_pdf_service.dart",
    "lib\features\staff\presentation\pages\staff_attendance_report_page.dart",
    "lib\features\staff\presentation\pages\staff_leave_report_page.dart"
)

foreach ($relativePath in $requiredCreatedFiles) {
    $fullPath = Join-Path $projectRoot $relativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Previously generated file is missing: $relativePath"
    }
}

Replace-AttendanceReportPage
Patch-AttendancePage
Patch-LeavePage
Write-CompletionDocument

$dartFiles = @(
    "lib\features\staff\presentation\services\staff_reports_pdf_service.dart",
    "lib\features\staff\presentation\pages\staff_attendance_report_page.dart",
    "lib\features\staff\presentation\pages\staff_leave_report_page.dart",
    "lib\features\staff\presentation\pages\staff_attendance_page.dart",
    "lib\features\staff\presentation\pages\staff_leave_page.dart"
)

Push-Location $projectRoot

try {
    Write-Host ""
    Write-Host "Formatting Dart files..." -ForegroundColor Cyan

    & dart format $dartFiles

    if ($LASTEXITCODE -ne 0) {
        throw "dart format failed."
    }

    Write-Host ""
    Write-Host "Running flutter analyze..." -ForegroundColor Cyan

    & flutter analyze

    if ($LASTEXITCODE -ne 0) {
        throw "flutter analyze found issues. Review the output above."
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "STAFF MODULE FINALIZATION COMPLETED." -ForegroundColor Green
Write-Host "Attendance Report navigation completed." -ForegroundColor Green
Write-Host "Leave Report navigation completed." -ForegroundColor Green
Write-Host "Completion document created." -ForegroundColor Green
Write-Host "Flutter analyze completed successfully." -ForegroundColor Green
Write-Host ""
