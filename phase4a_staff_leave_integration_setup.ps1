$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    Join-Path $projectRoot $RelativePath
}

function Read-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $fullPath = Get-FullPath $RelativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Required file not found: $fullPath"
    }

    [System.IO.File]::ReadAllText($fullPath)
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $fullPath = Get-FullPath $RelativePath
    [System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

function Backup-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $fullPath = Get-FullPath $RelativePath
    $backupPath = "$fullPath.phase4a_$timestamp.bak"
    Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
}

function Ensure-ImportBefore {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ImportLine,
        [Parameter(Mandatory = $true)][string[]]$MarkerImports
    )

    if ($Content.Contains($ImportLine)) {
        return $Content
    }

    foreach ($marker in $MarkerImports) {
        if ($Content.Contains($marker)) {
            return $Content.Replace(
                $marker,
                "$ImportLine`r`n$marker"
            )
        }
    }

    throw "No suitable import marker found for: $ImportLine"
}

function Ensure-BlockBeforeRegex {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$AlreadyPresentToken,
        [Parameter(Mandatory = $true)][string[]]$MarkerPatterns,
        [Parameter(Mandatory = $true)][string]$Block
    )

    if ($Content.Contains($AlreadyPresentToken)) {
        return $Content
    }

    foreach ($pattern in $MarkerPatterns) {
        $match = [regex]::Match(
            $Content,
            $pattern,
            [System.Text.RegularExpressions.RegexOptions]::Multiline
        )

        if ($match.Success) {
            return $Content.Insert($match.Index, $Block)
        }
    }

    throw "No suitable registration marker found for: $AlreadyPresentToken"
}

function Ensure-StaffLeavesFirestorePath {
    param([Parameter(Mandatory = $true)][string]$Content)

    if ($Content -match "static\s+const\s+String\s+staffLeaves\s*=") {
        return $Content
    }

    $patterns = @(
        "(?m)^(?<indent>\s*)static\s+const\s+String\s+staffSalaries\s*=\s*['""][^'""]+['""]\s*;\s*$",
        "(?m)^(?<indent>\s*)static\s+const\s+String\s+staffAttendance\s*=\s*['""][^'""]+['""]\s*;\s*$",
        "(?m)^(?<indent>\s*)static\s+const\s+String\s+employees\s*=\s*['""][^'""]+['""]\s*;\s*$"
    )

    foreach ($pattern in $patterns) {
        $match = [regex]::Match($Content, $pattern)

        if ($match.Success) {
            $indent = $match.Groups["indent"].Value
            $line = "${indent}static const String staffLeaves = 'staff_leaves';"

            return $Content.Insert(
                $match.Index + $match.Length,
                "`r`n$line"
            )
        }
    }

    $lastBraceIndex = $Content.LastIndexOf("}")

    if ($lastBraceIndex -lt 0) {
        throw "Could not locate closing brace in firestore_paths.dart"
    }

    return $Content.Insert(
        $lastBraceIndex,
        "  static const String staffLeaves = 'staff_leaves';`r`n"
    )
}

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Staff Leave Phase 4A Integration" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

$firestorePathFile = "lib\core\constants\firestore_paths.dart"
$firestoreContent = Read-ProjectFile $firestorePathFile
$updatedFirestoreContent =
    Ensure-StaffLeavesFirestorePath -Content $firestoreContent

if ($updatedFirestoreContent -ne $firestoreContent) {
    Backup-ProjectFile $firestorePathFile
    Write-ProjectFile $firestorePathFile $updatedFirestoreContent
} else {
    Write-Host "Already configured: $firestorePathFile" -ForegroundColor Yellow
}

$serviceLocatorFile = "lib\core\di\service_locator.dart"
$serviceLocatorContent = Read-ProjectFile $serviceLocatorFile
$originalServiceLocatorContent = $serviceLocatorContent

$serviceLocatorContent = Ensure-ImportBefore `
    -Content $serviceLocatorContent `
    -ImportLine "import '../../features/staff/data/datasources/staff_leave_remote_datasource.dart';" `
    -MarkerImports @(
        "import '../../features/staff/data/datasources/staff_salary_remote_datasource.dart';",
        "import '../../features/staff/data/datasources/staff_remote_datasource.dart';"
    )

$serviceLocatorContent = Ensure-ImportBefore `
    -Content $serviceLocatorContent `
    -ImportLine "import '../../features/staff/data/repositories/staff_leave_repository_impl.dart';" `
    -MarkerImports @(
        "import '../../features/staff/data/repositories/staff_salary_repository_impl.dart';",
        "import '../../features/staff/data/repositories/staff_repository_impl.dart';"
    )

$serviceLocatorContent = Ensure-ImportBefore `
    -Content $serviceLocatorContent `
    -ImportLine "import '../../features/staff/domain/repositories/staff_leave_repository.dart';" `
    -MarkerImports @(
        "import '../../features/staff/domain/repositories/staff_salary_repository.dart';",
        "import '../../features/staff/domain/repositories/staff_repository.dart';"
    )

$leaveUseCaseImports = @(
    "import '../../features/staff/domain/usecases/delete_staff_leave.dart';",
    "import '../../features/staff/domain/usecases/get_pending_staff_leaves.dart';",
    "import '../../features/staff/domain/usecases/get_staff_leaves_by_date_range.dart';",
    "import '../../features/staff/domain/usecases/get_staff_leaves_by_staff.dart';",
    "import '../../features/staff/domain/usecases/save_staff_leave.dart';",
    "import '../../features/staff/domain/usecases/update_staff_leave_status.dart';"
)

foreach ($importLine in $leaveUseCaseImports) {
    $serviceLocatorContent = Ensure-ImportBefore `
        -Content $serviceLocatorContent `
        -ImportLine $importLine `
        -MarkerImports @(
            "import '../../features/staff/domain/usecases/generate_staff_monthly_salaries.dart';",
            "import '../../features/staff/domain/usecases/get_staff.dart';"
        )
}

$serviceLocatorContent = Ensure-ImportBefore `
    -Content $serviceLocatorContent `
    -ImportLine "import '../../features/staff/presentation/bloc/staff_leave_bloc.dart';" `
    -MarkerImports @(
        "import '../../features/staff/presentation/bloc/staff_salary_bloc.dart';",
        "import '../../features/staff/presentation/bloc/staff_bloc.dart';"
    )

$serviceLocatorContent = Ensure-BlockBeforeRegex `
    -Content $serviceLocatorContent `
    -AlreadyPresentToken "registerLazySingleton<StaffLeaveRemoteDataSource>" `
    -MarkerPatterns @(
        "^\s*sl\.registerLazySingleton<StaffSalaryRemoteDataSource>\(",
        "^\s*sl\.registerLazySingleton<TeacherAssignmentRemoteDataSource>\(",
        "^\s*//\s*Repositories\s*$"
    ) `
    -Block @"
  sl.registerLazySingleton<StaffLeaveRemoteDataSource>(
    () => StaffLeaveRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );

"@

$serviceLocatorContent = Ensure-BlockBeforeRegex `
    -Content $serviceLocatorContent `
    -AlreadyPresentToken "registerLazySingleton<StaffLeaveRepository>" `
    -MarkerPatterns @(
        "^\s*sl\.registerLazySingleton<StaffSalaryRepository>\(",
        "^\s*sl\.registerLazySingleton<TeacherAssignmentRepository>\(",
        "^\s*//\s*Use Cases\s*$"
    ) `
    -Block @"
  sl.registerLazySingleton<StaffLeaveRepository>(
    () => StaffLeaveRepositoryImpl(
      sl<StaffLeaveRemoteDataSource>(),
    ),
  );

"@

$serviceLocatorContent = Ensure-BlockBeforeRegex `
    -Content $serviceLocatorContent `
    -AlreadyPresentToken "registerLazySingleton<GetStaffLeavesByDateRange>" `
    -MarkerPatterns @(
        "^\s*sl\.registerLazySingleton<GetStaffSalariesByMonth>\(",
        "^\s*//\s*BLoCs\s*$"
    ) `
    -Block @"
  sl.registerLazySingleton<GetStaffLeavesByDateRange>(
    () => GetStaffLeavesByDateRange(
      sl<StaffLeaveRepository>(),
    ),
  );

  sl.registerLazySingleton<GetStaffLeavesByStaff>(
    () => GetStaffLeavesByStaff(
      sl<StaffLeaveRepository>(),
    ),
  );

  sl.registerLazySingleton<GetPendingStaffLeaves>(
    () => GetPendingStaffLeaves(
      sl<StaffLeaveRepository>(),
    ),
  );

  sl.registerLazySingleton<SaveStaffLeave>(
    () => SaveStaffLeave(
      sl<StaffLeaveRepository>(),
    ),
  );

  sl.registerLazySingleton<DeleteStaffLeave>(
    () => DeleteStaffLeave(
      sl<StaffLeaveRepository>(),
    ),
  );

  sl.registerLazySingleton<UpdateStaffLeaveStatus>(
    () => UpdateStaffLeaveStatus(
      sl<StaffLeaveRepository>(),
    ),
  );

"@

$serviceLocatorContent = Ensure-BlockBeforeRegex `
    -Content $serviceLocatorContent `
    -AlreadyPresentToken "registerFactory<StaffLeaveBloc>" `
    -MarkerPatterns @(
        "^\s*sl\.registerFactory<StaffSalaryBloc>\(",
        "^\s*sl\.registerFactory<TeacherAttendanceBloc>\(",
        "^\s*}\s*$"
    ) `
    -Block @"
  sl.registerFactory<StaffLeaveBloc>(
    () => StaffLeaveBloc(
      sl<GetStaffLeavesByDateRange>(),
      sl<GetStaffLeavesByStaff>(),
      sl<GetPendingStaffLeaves>(),
      sl<SaveStaffLeave>(),
      sl<DeleteStaffLeave>(),
      sl<UpdateStaffLeaveStatus>(),
    ),
  );

"@

if ($serviceLocatorContent -ne $originalServiceLocatorContent) {
    Backup-ProjectFile $serviceLocatorFile
    Write-ProjectFile $serviceLocatorFile $serviceLocatorContent
} else {
    Write-Host "Already configured: $serviceLocatorFile" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Phase 4A Firestore and Dependency Injection integration completed." -ForegroundColor Cyan
Write-Host "UI pages and navigation were not changed yet." -ForegroundColor Yellow
Write-Host ""
