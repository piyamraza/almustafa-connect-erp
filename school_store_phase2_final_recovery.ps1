[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase2_final_recovery_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }

function WriteUtf8([string]$Path,[string]$Text) {
  [IO.File]::WriteAllText(
    (Full $Path),
    $Text.Replace("`r`n","`n"),
    $utf8
  )
}

function BackupFile([string]$Path) {
  $source = Full $Path
  if (-not (Test-Path $source)) { return }

  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent

  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }

  Copy-Item $source $target -Force
}

function InsertBefore(
  [string]$Path,
  [string]$Anchor,
  [string]$TextToInsert
) {
  $text = ReadUtf8 $Path

  if ($text.Contains($TextToInsert.Trim())) {
    return
  }

  $index = $text.IndexOf(
    $Anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw "ANCHOR ERROR: Anchor not found in $Path.`n$Anchor"
  }

  BackupFile $Path

  WriteUtf8 $Path (
    $text.Substring(0,$index) +
    $TextToInsert +
    $text.Substring($index)
  )
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/school_store/data/datasources/store_purchase_remote_datasource.dart',
  'lib/features/school_store/data/repositories/store_purchase_repository_impl.dart',
  'lib/features/school_store/domain/repositories/store_purchase_repository.dart',
  'lib/features/school_store/domain/usecases/manage_store_purchases.dart',
  'lib/features/school_store/presentation/bloc/store_purchase_bloc.dart',
  'lib/features/school_store/presentation/pages/store_purchases_page.dart',
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/di/service_locator.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null

$slFile = 'lib/core/di/service_locator.dart'
$dashboardFile = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'

BackupFile $slFile
BackupFile $dashboardFile

# Repair any accidental joined import.
$slText = ReadUtf8 $slFile
$slText = $slText.Replace(
  "store_purchase_bloc.dart';import '../../features/school_store/data/datasources/school_store_remote_datasource.dart';",
  "store_purchase_bloc.dart';`nimport '../../features/school_store/data/datasources/school_store_remote_datasource.dart';"
)
WriteUtf8 $slFile $slText

$imports = @"
import '../../features/school_store/data/datasources/store_purchase_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_purchase_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_purchase_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_purchases.dart';
import '../../features/school_store/presentation/bloc/store_purchase_bloc.dart';
"@

if (-not (ReadUtf8 $slFile).Contains(
  "store_purchase_remote_datasource.dart"
)) {
  InsertBefore `
    $slFile `
    "import '../../features/school_store/data/datasources/school_store_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<StorePurchaseRemoteDataSource>(
    () => StorePurchaseRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<StorePurchaseRepository>(
    () => StorePurchaseRepositoryImpl(
      sl<StorePurchaseRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetStoreSuppliers>(
    () => GetStoreSuppliers(
      sl<StorePurchaseRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveStoreSupplier>(
    () => SaveStoreSupplier(
      sl<StorePurchaseRepository>(),
    ),
  );
  sl.registerLazySingleton<GetStorePurchases>(
    () => GetStorePurchases(
      sl<StorePurchaseRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveStorePurchase>(
    () => SaveStorePurchase(
      sl<StorePurchaseRepository>(),
    ),
  );
  sl.registerFactory<StorePurchaseBloc>(
    () => StorePurchaseBloc(
      getSuppliers: sl<GetStoreSuppliers>(),
      saveSupplier: sl<SaveStoreSupplier>(),
      getPurchases: sl<GetStorePurchases>(),
      savePurchase: sl<SaveStorePurchase>(),
      getItems: sl<GetStoreItems>(),
    ),
  );

"@

if (-not (ReadUtf8 $slFile).Contains(
  'sl.registerLazySingleton<StorePurchaseRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<SchoolStoreRemoteDataSource>(' `
    $registrations
}

$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  "import 'store_purchases_page.dart';"
)) {
  $anchor = "import '../bloc/school_store_state.dart';"

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD IMPORT ANCHOR ERROR.'
  }

  $dashboardText = $dashboardText.Replace(
    $anchor,
    "$anchor`nimport 'store_purchases_page.dart';"
  )

  WriteUtf8 $dashboardFile $dashboardText
}

$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  'const StorePurchasesPage()'
)) {
  $anchor = '              const SizedBox(height: 20),'
  $index = $dashboardText.IndexOf(
    $anchor,
    [StringComparison]::Ordinal
  )

  if ($index -lt 0) {
    throw 'DASHBOARD BUTTON ANCHOR ERROR.'
  }

  $button = @"
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const StorePurchasesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping_outlined),
                label: const Text('Suppliers & Purchases'),
              ),
              const SizedBox(height: 20),
"@

  WriteUtf8 $dashboardFile (
    $dashboardText.Substring(0,$index) +
    $button +
    $dashboardText.Substring(
      $index + $anchor.Length
    )
  )
}

& dart format `
  lib/features/school_store `
  lib/core/di/service_locator.dart

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'School Store Phase 2 final recovery completed.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Now run:' -ForegroundColor Yellow
Write-Host 'flutter analyze lib\features\school_store --no-fatal-infos --no-fatal-warnings' -ForegroundColor Cyan
