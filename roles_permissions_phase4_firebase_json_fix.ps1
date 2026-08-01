$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
if (-not (Test-Path (Join-Path $root 'pubspec.yaml'))) {
    throw 'Run this script from the almustafa-connect-erp project root.'
}

$utf8 = New-Object System.Text.UTF8Encoding($false)
$firebaseJson = 'firebase.json'

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $path = Join-Path $root $RelativePath
    [IO.File]::WriteAllText($path, $Content, $utf8)
    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups/access_control_phase4_firebase_json_fix_$stamp"

$source = Join-Path $root $firebaseJson
$destination = Join-Path $backupRoot $firebaseJson

New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
Copy-Item $source $destination -Force

$firebaseConfig = Get-Content $source -Raw | ConvertFrom-Json

$hasFirestoreProperty =
    $firebaseConfig.PSObject.Properties.Name -contains 'firestore'

if (-not $hasFirestoreProperty) {
    $firebaseConfig | Add-Member `
        -NotePropertyName 'firestore' `
        -NotePropertyValue ([pscustomobject]@{
            rules = 'firestore.rules'
            indexes = 'firestore.indexes.json'
        })
} else {
    $firestoreConfig = $firebaseConfig.firestore

    $hasRulesProperty =
        $firestoreConfig.PSObject.Properties.Name -contains 'rules'

    if (-not $hasRulesProperty) {
        $firestoreConfig | Add-Member `
            -NotePropertyName 'rules' `
            -NotePropertyValue 'firestore.rules'
    } else {
        $firestoreConfig.rules = 'firestore.rules'
    }

    $hasIndexesProperty =
        $firestoreConfig.PSObject.Properties.Name -contains 'indexes'

    if (-not $hasIndexesProperty) {
        $firestoreConfig | Add-Member `
            -NotePropertyName 'indexes' `
            -NotePropertyValue 'firestore.indexes.json'
    } else {
        $firestoreConfig.indexes = 'firestore.indexes.json'
    }
}

$firebaseContent = $firebaseConfig | ConvertTo-Json -Depth 30
Write-ProjectFile -RelativePath $firebaseJson -Content ($firebaseContent + "`n")

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

Write-Host ''
Write-Host 'Running dart format...' -ForegroundColor Cyan

& dart format `
    'lib/features/access_control/data/repositories/user_role_assignment_repository_impl.dart' `
    'lib/features/access_control/presentation/pages/user_role_assignment_form_page.dart' `
    'lib/features/access_control/presentation/pages/roles_permissions_page.dart' `
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
Write-Host 'Roles and Permissions Phase 4 Firebase configuration repair completed successfully.' -ForegroundColor Green
Write-Host 'Firestore rules are staged but have NOT been deployed.' -ForegroundColor Yellow
Write-Host 'Run migration and Production Readiness validation before deployment.' -ForegroundColor Yellow
Write-Host "Backup: $backupRoot" -ForegroundColor DarkGray
