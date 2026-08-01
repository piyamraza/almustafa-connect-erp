$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$target = 'lib/features/fees/presentation/pages/monthly_fee_generation_page.dart'
$targetPath = Join-Path $root $target

if (-not (Test-Path $targetPath)) {
    throw "Required file not found: $target"
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path `
    (Split-Path $root -Parent) `
    "almustafa-connect-erp_backups/monthly_fee_status_row_colors_$stamp"

$backupFile = Join-Path $backupRoot $target
New-Item -ItemType Directory -Path (Split-Path $backupFile -Parent) -Force | Out-Null
Copy-Item $targetPath $backupFile -Force

$content = [IO.File]::ReadAllText($targetPath).Replace("`r`n", "`n")

if ($content.Contains('color: WidgetStatePropertyAll(_dueRowColor(due))')) {
    Write-Host 'Monthly fee row status colors are already present.' -ForegroundColor Yellow
} else {
    $oldRow = @'
                    DataRow(
                      cells: [
'@

    $newRow = @'
                    DataRow(
                      color: WidgetStatePropertyAll(_dueRowColor(due)),
                      cells: [
'@

    if (-not $content.Contains($oldRow)) {
        throw 'Monthly fee DataRow anchor not found.'
    }

    $content = $content.Replace($oldRow, $newRow)

    $oldStatusCell = @'
                        DataCell(Text(due.status.name.toUpperCase())),
'@

    $newStatusCell = @'
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _dueStatusColor(
                                due,
                              ).withValues(alpha: .14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _dueStatusColor(
                                  due,
                                ).withValues(alpha: .35),
                              ),
                            ),
                            child: Text(
                              due.status.name.toUpperCase(),
                              style: TextStyle(
                                color: _dueStatusColor(due),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
'@

    if (-not $content.Contains($oldStatusCell)) {
        throw 'Monthly fee status cell anchor not found.'
    }

    $content = $content.Replace($oldStatusCell, $newStatusCell)

    $helperAnchor = @'
  static String _scopeLabel(FeeGenerationScope scope) => switch (scope) {
'@

    $helpers = @'
  Color _dueRowColor(MonthlyFeeDueEntity due) {
    if (due.status == MonthlyFeeDueStatus.paid) {
      return const Color(0xFFE8F7EE);
    }

    if (due.status == MonthlyFeeDueStatus.cancelled) {
      return const Color(0xFFF1F3F5);
    }

    if (due.paidAmount > 0) {
      return const Color(0xFFFFF5DB);
    }

    return const Color(0xFFFFECEC);
  }

  Color _dueStatusColor(MonthlyFeeDueEntity due) {
    if (due.status == MonthlyFeeDueStatus.paid) {
      return const Color(0xFF15803D);
    }

    if (due.status == MonthlyFeeDueStatus.cancelled) {
      return const Color(0xFF64748B);
    }

    if (due.paidAmount > 0) {
      return const Color(0xFFB45309);
    }

    return const Color(0xFFDC2626);
  }

'@

    if (-not $content.Contains($helperAnchor)) {
        throw 'Monthly fee helper insertion anchor not found.'
    }

    $content = $content.Replace(
        $helperAnchor,
        $helpers + $helperAnchor
    )

    [IO.File]::WriteAllText($targetPath, $content, $utf8)
    Write-Host "Updated: $target" -ForegroundColor Green
}

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format $target

if ($LASTEXITCODE -ne 0) {
    throw 'dart format failed.'
}

Write-Host ''
Write-Host 'Running flutter analyze...' -ForegroundColor Cyan

& flutter analyze

if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found issues. Copy the complete output into ChatGPT.'
}

Write-Host ''
Write-Host 'Monthly fee status row colors added successfully.' -ForegroundColor Green
Write-Host 'Paid rows are green, unpaid rows red, partial rows amber and cancelled rows grey.' -ForegroundColor Cyan
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
