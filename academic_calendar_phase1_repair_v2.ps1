$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$serviceLocator = 'lib/core/di/service_locator.dart'
$sidebar = 'lib/features/dashboard/presentation/widgets/sidebar.dart'
$calendarPage = 'lib/features/academic_calendar/presentation/pages/academic_calendar_page.dart'
$calendarBloc = 'lib/features/academic_calendar/presentation/bloc/academic_calendar_bloc.dart'
$calendarRepo = 'lib/features/academic_calendar/domain/repositories/academic_calendar_repository.dart'
$calendarRepoImpl = 'lib/features/academic_calendar/data/repositories/academic_calendar_repository_impl.dart'

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath
    if (-not (Test-Path $path)) {
        throw "Required file not found: $RelativePath"
    }

    return [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
}

function Write-ProjectFileSafe {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $root $RelativePath
    $lastError = $null

    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            [IO.File]::WriteAllText($path, $Content, $utf8)
            Write-Host "Updated: $RelativePath" -ForegroundColor Green
            return
        } catch {
            $lastError = $_
            Write-Host "File busy, retry $attempt/10: $RelativePath" -ForegroundColor Yellow
            Start-Sleep -Milliseconds 700
        }
    }

    throw "Unable to update $RelativePath. Last error: $lastError"
}

function Insert-Import {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ImportLine
    )

    if ($Content.Contains($ImportLine)) {
        return $Content
    }

    $matches = [regex]::Matches($Content, "(?m)^import\s+['""].+?['""];\s*$")
    if ($matches.Count -eq 0) {
        throw "No import block found for: $ImportLine"
    }

    $insertAt = $matches[$matches.Count - 1].Index + $matches[$matches.Count - 1].Length
    return $Content.Insert($insertAt, "`n$ImportLine")
}

function Insert-Before-FirstMatch {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$UniqueMarker,
        [Parameter(Mandatory = $true)][string[]]$Patterns,
        [Parameter(Mandatory = $true)][string]$Block
    )

    if ($Content.Contains($UniqueMarker)) {
        return $Content
    }

    foreach ($pattern in $Patterns) {
        $match = [regex]::Match($Content, $pattern)
        if ($match.Success) {
            return $Content.Insert($match.Index, $Block)
        }
    }

    throw "Could not locate registration anchor for: $UniqueMarker"
}

foreach ($required in @(
    $serviceLocator,
    $sidebar,
    $calendarPage,
    $calendarBloc,
    $calendarRepo,
    $calendarRepoImpl
)) {
    if (-not (Test-Path (Join-Path $root $required))) {
        throw "Missing required Phase 1 file: $required"
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups/academic_calendar_phase1_repair_$timestamp"

foreach ($relativePath in @($serviceLocator, $sidebar)) {
    $source = Join-Path $root $relativePath
    $destination = Join-Path $backupRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item $source $destination -Force
}

# =========================================================
# Service locator imports
# =========================================================

$content = Read-ProjectFile -RelativePath $serviceLocator

$content = Insert-Import `
    -Content $content `
    -ImportLine "import '../../features/academic_calendar/data/repositories/academic_calendar_repository_impl.dart';"

$content = Insert-Import `
    -Content $content `
    -ImportLine "import '../../features/academic_calendar/domain/repositories/academic_calendar_repository.dart';"

$content = Insert-Import `
    -Content $content `
    -ImportLine "import '../../features/academic_calendar/presentation/bloc/academic_calendar_bloc.dart';"

# =========================================================
# Service locator registrations
# =========================================================

$repositoryRegistration = @'
  sl.registerLazySingleton<AcademicCalendarRepository>(
    () => AcademicCalendarRepositoryImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );

'@

$content = Insert-Before-FirstMatch `
    -Content $content `
    -UniqueMarker 'registerLazySingleton<AcademicCalendarRepository>' `
    -Patterns @(
        '(?m)^\s*sl\.registerLazySingleton<AcademicStructureRepository>',
        '(?m)^\s*sl\.registerLazySingleton<[^>]+>',
        '(?m)^\s*sl\.registerSingleton<',
        '(?m)^\s*sl\.registerFactory<'
    ) `
    -Block $repositoryRegistration

$blocRegistration = @'
  sl.registerFactory<AcademicCalendarBloc>(
    () => AcademicCalendarBloc(
      sl<AcademicCalendarRepository>(),
    ),
  );

'@

$content = Insert-Before-FirstMatch `
    -Content $content `
    -UniqueMarker 'registerFactory<AcademicCalendarBloc>' `
    -Patterns @(
        '(?m)^\s*sl\.registerFactory<AcademicStructureBloc>',
        '(?m)^\s*sl\.registerFactory<',
        '(?m)^\s*sl\.registerLazySingleton<'
    ) `
    -Block $blocRegistration

Write-ProjectFileSafe -RelativePath $serviceLocator -Content $content

# =========================================================
# Sidebar integration
# =========================================================

$content = Read-ProjectFile -RelativePath $sidebar

if (-not $content.Contains(
    "import '../../../academic_calendar/presentation/pages/academic_calendar_page.dart';"
)) {
    $matches = [regex]::Matches($content, "(?m)^import\s+['""].+?['""];\s*$")
    if ($matches.Count -eq 0) {
        throw 'Sidebar import block was not found.'
    }

    $insertAt = $matches[$matches.Count - 1].Index + $matches[$matches.Count - 1].Length
    $content = $content.Insert(
        $insertAt,
        "`nimport '../../../academic_calendar/presentation/pages/academic_calendar_page.dart';"
    )
}

if (-not $content.Contains('const AcademicCalendarPage()')) {
    $pattern = "(?s)_menuTile\(\s*context,\s*icon:\s*Icons\.calendar_today_outlined,\s*title:\s*'Academic Calendar',\s*onTap:\s*\(\)\s*\{.*?\n\s*\},\s*\),"

    $replacement = @'
_menuTile(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'Academic Calendar',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AcademicCalendarPage(),
                ),
              );
            },
          ),
'@

    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content,
            $pattern,
            $replacement,
            1
        )
    } else {
        throw 'Could not locate the Academic Calendar sidebar item.'
    }
}

Write-ProjectFileSafe -RelativePath $sidebar -Content $content

# =========================================================
# Format and analyze
# =========================================================

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan
& dart format $serviceLocator $sidebar `
    'lib/features/academic_calendar'
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
Write-Host 'Academic Calendar Phase 1 repair completed successfully.' -ForegroundColor Green
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
