$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups/access_control_phase4_repair_$stamp"

$assignmentRepository = 'lib/features/access_control/data/repositories/user_role_assignment_repository_impl.dart'
$assignmentForm = 'lib/features/access_control/presentation/pages/user_role_assignment_form_page.dart'
$rolesPage = 'lib/features/access_control/presentation/pages/roles_permissions_page.dart'
$firebaseJson = 'firebase.json'

function Read-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $path = Join-Path $root $RelativePath

    if (-not (Test-Path $path)) {
        throw "Required file not found: $RelativePath"
    }

    return [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
}

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $root $RelativePath
    New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
    [IO.File]::WriteAllText($path, $Content, $utf8)
    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

function Backup-ProjectFile {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $source = Join-Path $root $RelativePath
    if (-not (Test-Path $source)) { return }

    $destination = Join-Path $backupRoot $RelativePath
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item $source $destination -Force
}

function Add-Import {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$ImportLine
    )

    if ($Content.Contains($ImportLine)) {
        return $Content
    }

    $matches = [regex]::Matches(
        $Content,
        "(?m)^import\s+['""].+?['""];\s*$"
    )

    if ($matches.Count -eq 0) {
        throw "Import block not found: $ImportLine"
    }

    $last = $matches[$matches.Count - 1]

    return $Content.Insert(
        $last.Index + $last.Length,
        "`n$ImportLine"
    )
}

foreach ($relativePath in @(
    $assignmentRepository,
    $assignmentForm,
    $rolesPage,
    $firebaseJson
)) {
    Backup-ProjectFile -RelativePath $relativePath
}

# =========================================================
# 1. Canonicalize role assignments to user_roles/{UID}
# =========================================================

$content = Read-ProjectFile -RelativePath $assignmentRepository

if (-not $content.Contains('.doc(assignment.userId.trim())')) {
    $pattern = '(?ms)(await\s+_service\s*\.collection\(FirestorePaths\.userRoleAssignments\)\s*)\.doc\(assignment\.id\)(\s*\.set\(\s*UserRoleAssignmentModel\.fromEntity\(assignment\)\.toMap\(\),?\s*\);)'

    if ([regex]::IsMatch($content, $pattern)) {
        $content = [regex]::Replace(
            $content,
            $pattern,
            '$1.doc(assignment.userId.trim())$2',
            1
        )
    } else {
        $simplePattern = '\.doc\(assignment\.id\)'

        if ([regex]::IsMatch($content, $simplePattern)) {
            $content = [regex]::Replace(
                $content,
                $simplePattern,
                '.doc(assignment.userId.trim())',
                1
            )
        } else {
            throw 'Could not locate assignment document ID write.'
        }
    }
}

if (-not $content.Contains(
    'if (assignment.id != assignment.userId.trim())'
)) {
    $setPattern = '(?ms)(await\s+_service\s*\.collection\(FirestorePaths\.userRoleAssignments\)\s*\.doc\(assignment\.userId\.trim\(\)\)\s*\.set\(.*?\);)'

    $match = [regex]::Match($content, $setPattern)

    if (-not $match.Success) {
        throw 'Could not locate canonical assignment save statement.'
    }

    $legacyCleanup = @'

    if (assignment.id != assignment.userId.trim()) {
      await _service
          .collection(FirestorePaths.userRoleAssignments)
          .doc(assignment.id)
          .delete();
    }
'@

    $content = $content.Insert(
        $match.Index + $match.Length,
        $legacyCleanup
    )
}

Write-ProjectFile `
    -RelativePath $assignmentRepository `
    -Content $content

# =========================================================
# 2. New assignment entity ID must be Firebase UID
# =========================================================

$content = Read-ProjectFile -RelativePath $assignmentForm

if (-not $content.Contains(
    'id: old?.id ?? _userId.text.trim()'
)) {
    $patterns = @(
        '(?ms)id:\s*old\?\.id\s*\?\?\s*sl<UserRoleAssignmentRepository>\(\)\.generateId\(\),',
        '(?ms)id:\s*old\?\.id\s*\?\?\s*[^\n,]+generateId\(\),'
    )

    $changed = $false

    foreach ($pattern in $patterns) {
        if ([regex]::IsMatch($content, $pattern)) {
            $content = [regex]::Replace(
                $content,
                $pattern,
                'id: old?.id ?? _userId.text.trim(),',
                1
            )
            $changed = $true
            break
        }
    }

    if (-not $changed) {
        throw 'Could not locate assignment form generated ID.'
    }
}

Write-ProjectFile `
    -RelativePath $assignmentForm `
    -Content $content

# =========================================================
# 3. Add Production Readiness action
# =========================================================

$content = Read-ProjectFile -RelativePath $rolesPage

$content = Add-Import `
    -Content $content `
    -ImportLine "import 'access_control_production_readiness_page.dart';"

if (-not $content.Contains(
    'const AccessControlProductionReadinessPage()'
)) {
    $actionsMatch = [regex]::Match(
        $content,
        '(?m)^\s*actions:\s*\[\s*$'
    )

    if (-not $actionsMatch.Success) {
        throw 'Roles page AppBar actions anchor not found.'
    }

    $indent = [regex]::Match(
        $actionsMatch.Value,
        '^\s*'
    ).Value

    $button = @"
$indent  TextButton.icon(
$indent    onPressed: () {
$indent      Navigator.of(context).push<void>(
$indent        MaterialPageRoute<void>(
$indent          builder: (_) =>
$indent              const AccessControlProductionReadinessPage(),
$indent        ),
$indent      );
$indent    },
$indent    icon: const Icon(Icons.security_outlined),
$indent    label: const Text('Production Readiness'),
$indent  ),
"@

    $content = $content.Insert(
        $actionsMatch.Index + $actionsMatch.Length,
        "`n$button"
    )
}

Write-ProjectFile `
    -RelativePath $rolesPage `
    -Content $content

# =========================================================
# 4. Add Firestore config without removing FlutterFire config
# =========================================================

$firebasePath = Join-Path $root $firebaseJson
$firebaseConfig = Get-Content $firebasePath -Raw |
    ConvertFrom-Json

if ($null -eq $firebaseConfig.firestore) {
    $firebaseConfig | Add-Member `
        -NotePropertyName 'firestore' `
        -NotePropertyValue ([pscustomobject]@{
            rules = 'firestore.rules'
            indexes = 'firestore.indexes.json'
        })
} else {
    if ($null -eq $firebaseConfig.firestore.rules) {
        $firebaseConfig.firestore |
            Add-Member `
                -NotePropertyName 'rules' `
                -NotePropertyValue 'firestore.rules'
    } else {
        $firebaseConfig.firestore.rules = 'firestore.rules'
    }

    if ($null -eq $firebaseConfig.firestore.indexes) {
        $firebaseConfig.firestore |
            Add-Member `
                -NotePropertyName 'indexes' `
                -NotePropertyValue 'firestore.indexes.json'
    } else {
        $firebaseConfig.firestore.indexes =
            'firestore.indexes.json'
    }
}

$firebaseContent = $firebaseConfig |
    ConvertTo-Json -Depth 30

Write-ProjectFile `
    -RelativePath $firebaseJson `
    -Content ($firebaseContent + "`n")

# =========================================================
# 5. Verify Phase 4 files from first run
# =========================================================

$requiredFiles = @(
    'firestore.rules',
    'firestore.indexes.json',
    'lib/features/access_control/data/services/access_control_migration_service.dart',
    'lib/features/access_control/presentation/pages/access_control_production_readiness_page.dart',
    'docs/roles_permissions_phase4_production_deployment.md'
)

foreach ($relativePath in $requiredFiles) {
    if (-not (Test-Path (Join-Path $root $relativePath))) {
        throw "Phase 4 required file is missing: $relativePath"
    }
}

# =========================================================
# Format and analyze
# =========================================================

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format `
    $assignmentRepository `
    $assignmentForm `
    $rolesPage `
    'lib/features/access_control/data/services/access_control_migration_service.dart' `
    'lib/features/access_control/presentation/pages/access_control_production_readiness_page.dart'

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
Write-Host 'Roles and Permissions Phase 4 repair completed successfully.' -ForegroundColor Green
Write-Host 'Firestore rules are staged but have NOT been deployed.' -ForegroundColor Yellow
Write-Host 'Run migration and validation from Production Readiness before deployment.' -ForegroundColor Yellow
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
