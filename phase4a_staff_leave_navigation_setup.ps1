$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

function Read-TextFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Required file not found: $Path"
    }

    return [System.IO.File]::ReadAllText($Path)
}

function Write-TextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
    Write-Host "Updated: $Path" -ForegroundColor Green
}

function Backup-TextFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $backupPath = "$Path.phase4a_navigation_$timestamp.bak"
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
}

function Insert-AfterRegexMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Insertion,
        [Parameter(Mandatory = $true)][string]$AlreadyPresentToken,
        [Parameter(Mandatory = $true)][string]$ErrorMessage
    )

    if ($Content.Contains($AlreadyPresentToken)) {
        return $Content
    }

    $match = [regex]::Match(
        $Content,
        $Pattern,
        [System.Text.RegularExpressions.RegexOptions]::Multiline
    )

    if (-not $match.Success) {
        throw $ErrorMessage
    }

    return $Content.Insert(
        $match.Index + $match.Length,
        $Insertion
    )
}

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Phase 4A Leave Navigation Setup" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# STAFF DASHBOARD
# ============================================================

$dashboardPath = Join-Path $projectRoot `
    "lib\features\staff\presentation\pages\staff_dashboard_page.dart"

$dashboardContent = Read-TextFile $dashboardPath
$originalDashboardContent = $dashboardContent

$dashboardContent = Insert-AfterRegexMatch `
    -Content $dashboardContent `
    -Pattern "^\s*required\s+this\.onSalary,\s*$" `
    -Insertion "`r`n    required this.onLeave," `
    -AlreadyPresentToken "required this.onLeave," `
    -ErrorMessage "Staff Dashboard constructor marker 'required this.onSalary' was not found."

$dashboardContent = Insert-AfterRegexMatch `
    -Content $dashboardContent `
    -Pattern "^\s*final\s+VoidCallback\s+onSalary;\s*$" `
    -Insertion "`r`n  final VoidCallback onLeave;" `
    -AlreadyPresentToken "final VoidCallback onLeave;" `
    -ErrorMessage "Staff Dashboard field marker 'final VoidCallback onSalary' was not found."

if (-not $dashboardContent.Contains("onTap: onLeave")) {
    $salaryCardPattern =
        "(?s)(?<card>\s*_StaffDashboardCard\(\s*" +
        "title:\s*'Salary Management',.*?" +
        "onTap:\s*onSalary,\s*" +
        "\),)"

    $salaryCardMatch = [regex]::Match(
        $dashboardContent,
        $salaryCardPattern
    )

    if (-not $salaryCardMatch.Success) {
        throw "Salary Management card was not found in Staff Dashboard."
    }

    $leaveCard = @"
                                _StaffDashboardCard(
                                  title: 'Leave Management',
                                  description:
                                      'Create, approve and review staff leave requests.',
                                  icon: Icons.event_available_outlined,
                                  actionLabel: 'Open Leave',
                                  onTap: onLeave,
                                ),
"@

    $dashboardContent = $dashboardContent.Insert(
        $salaryCardMatch.Index + $salaryCardMatch.Length,
        "`r`n$leaveCard"
    )
}

if ($dashboardContent -ne $originalDashboardContent) {
    Backup-TextFile $dashboardPath
    Write-TextFile $dashboardPath $dashboardContent
} else {
    Write-Host "Already configured: $dashboardPath" -ForegroundColor Yellow
}

# ============================================================
# LOCATE SIDEBAR
# ============================================================

$libPath = Join-Path $projectRoot "lib"

$sidebarCandidates = Get-ChildItem `
    -LiteralPath $libPath `
    -Filter "sidebar.dart" `
    -File `
    -Recurse |
    Where-Object {
        $candidateContent =
            [System.IO.File]::ReadAllText($_.FullName)

        $candidateContent.Contains("class Sidebar") -and
        $candidateContent.Contains("StaffDashboardPage(")
    }

if ($sidebarCandidates.Count -eq 0) {
    throw "No sidebar.dart containing StaffDashboardPage was found under lib."
}

if ($sidebarCandidates.Count -gt 1) {
    Write-Host "Multiple Sidebar files found:" -ForegroundColor Red

    foreach ($candidate in $sidebarCandidates) {
        Write-Host " - $($candidate.FullName)" -ForegroundColor Red
    }

    throw "Navigation was not changed because more than one matching Sidebar file exists."
}

$sidebarPath = $sidebarCandidates[0].FullName
$sidebarContent = Read-TextFile $sidebarPath
$originalSidebarContent = $sidebarContent

Write-Host "Sidebar found: $sidebarPath" -ForegroundColor Cyan

# ============================================================
# SIDEBAR IMPORT
# ============================================================

if (-not $sidebarContent.Contains("staff_leave_page.dart")) {
    $salaryImportPattern =
        "(?m)^(?<indent>\s*)import\s+['""]" +
        "(?<prefix>[^'""]*staff/presentation/pages/)" +
        "staff_salary_page\.dart['""];\s*$"

    $salaryImportMatch =
        [regex]::Match($sidebarContent, $salaryImportPattern)

    if (-not $salaryImportMatch.Success) {
        throw "Staff Salary import marker was not found in Sidebar."
    }

    $indent = $salaryImportMatch.Groups["indent"].Value
    $prefix = $salaryImportMatch.Groups["prefix"].Value
    $leaveImport =
        "${indent}import '${prefix}staff_leave_page.dart';"

    $sidebarContent = $sidebarContent.Insert(
        $salaryImportMatch.Index + $salaryImportMatch.Length,
        "`r`n$leaveImport"
    )
}

# ============================================================
# SIDEBAR CALLBACK
# ============================================================

if (-not $sidebarContent.Contains("onLeave:")) {
    $onSalaryPattern =
        "(?m)^(?<indent>\s*)onSalary:\s*\(\)\s*\{"

    $onSalaryMatch =
        [regex]::Match($sidebarContent, $onSalaryPattern)

    if (-not $onSalaryMatch.Success) {
        throw "StaffDashboardPage onSalary callback marker was not found in Sidebar."
    }

    $indent = $onSalaryMatch.Groups["indent"].Value

    $leaveCallback = @"
${indent}onLeave: () {
${indent}  Navigator.of(staffDashboardContext).push(
${indent}    MaterialPageRoute<void>(
${indent}      builder: (_) => const StaffLeavePage(),
${indent}    ),
${indent}  );
${indent}},
"@

    $sidebarContent = $sidebarContent.Insert(
        $onSalaryMatch.Index,
        "$leaveCallback`r`n"
    )
}

if ($sidebarContent -ne $originalSidebarContent) {
    Backup-TextFile $sidebarPath
    Write-TextFile $sidebarPath $sidebarContent
} else {
    Write-Host "Already configured: $sidebarPath" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Phase 4A Leave dashboard and Sidebar navigation completed." -ForegroundColor Cyan
Write-Host "Leave Management is now enabled in Staff Dashboard." -ForegroundColor Green
Write-Host ""
