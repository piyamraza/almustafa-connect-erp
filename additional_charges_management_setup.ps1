[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Get-Location).Path
$pubspec = Join-Path $projectRoot 'pubspec.yaml'
if (-not (Test-Path -LiteralPath $pubspec)) {
    throw 'Run this installer from the Almustafa Connect ERP project root.'
}

$requiredFiles = @(
    'lib/core/constants/firestore_paths.dart',
    'lib/core/di/service_locator.dart',
    'lib/features/fees/domain/entities/additional_charge_entity.dart',
    'lib/features/fees/domain/entities/student_additional_charge_due_entity.dart',
    'lib/features/fees/domain/entities/fee_payment_entity.dart',
    'lib/features/fees/domain/repositories/additional_charge_repository.dart',
    'lib/features/fees/domain/repositories/student_additional_charge_due_repository.dart',
    'lib/features/fees/domain/repositories/fee_payment_repository.dart',
    'lib/features/fees/domain/services/additional_charge_generation_service.dart',
    'lib/features/fees/data/models/additional_charge_model.dart',
    'lib/features/fees/data/models/student_additional_charge_due_model.dart',
    'lib/features/fees/data/models/fee_payment_model.dart',
    'lib/features/fees/data/repositories/additional_charge_repository_impl.dart',
    'lib/features/fees/data/repositories/student_additional_charge_due_repository_impl.dart',
    'lib/features/fees/data/repositories/fee_payment_repository_impl.dart',
    'lib/features/fees/presentation/bloc/additional_charges_bloc.dart',
    'lib/features/fees/presentation/bloc/fee_collection_bloc.dart',
    'lib/features/fees/presentation/pages/additional_charges_management_page.dart',
    'lib/features/fees/presentation/pages/additional_charge_reports_page.dart',
    'lib/features/fees/presentation/pages/fee_management_dashboard_page.dart',
    'lib/features/fees/presentation/pages/fee_collection_page.dart',
    'lib/features/fees/presentation/pages/fee_reports_page.dart',
    'firestore.rules'
)

foreach ($relativePath in $requiredFiles) {
    $absolutePath = Join-Path $projectRoot $relativePath
    if (-not (Test-Path -LiteralPath $absolutePath)) {
        throw "Required module file is missing: $relativePath"
    }
}

$anchors = @{
    'lib/core/constants/firestore_paths.dart' = 'studentAdditionalChargeDues'
    'lib/core/di/service_locator.dart' = 'AdditionalChargesBloc'
    'lib/features/fees/presentation/pages/fee_management_dashboard_page.dart' = 'Additional Charges'
    'lib/features/fees/presentation/pages/fee_collection_page.dart' = 'Additional Charge Dues'
    'lib/features/fees/presentation/pages/fee_reports_page.dart' = 'Additional Charges Reports'
    'firestore.rules' = 'student_additional_charge_dues'
}

foreach ($entry in $anchors.GetEnumerator()) {
    $absolutePath = Join-Path $projectRoot $entry.Key
    $content = Get-Content -LiteralPath $absolutePath -Raw
    if (-not $content.Contains($entry.Value)) {
        throw "Integration anchor '$($entry.Value)' was not found in $($entry.Key). No files were changed."
    }
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path $projectRoot ".additional_charges_backups\$stamp"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
foreach ($relativePath in $requiredFiles) {
    $source = Join-Path $projectRoot $relativePath
    $destination = Join-Path $backupRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

$dart = Get-Command dart -ErrorAction SilentlyContinue
if ($null -eq $dart) {
    throw 'Dart was not found on PATH. Backups were created; source files were not formatted.'
}
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutter) {
    throw 'Flutter was not found on PATH. Backups were created; analysis was not run.'
}

& dart format lib/features/fees lib/core/constants/firestore_paths.dart lib/core/di/service_locator.dart
if ($LASTEXITCODE -ne 0) { throw 'dart format failed.' }
& flutter analyze --no-fatal-warnings --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed. Review the output above.' }

Write-Host ''
Write-Host 'Additional Charges Management installed and verified successfully.' -ForegroundColor Green
Write-Host "Backup: $backupRoot"
Write-Host 'Firestore rules were updated locally but were NOT deployed.' -ForegroundColor Yellow
