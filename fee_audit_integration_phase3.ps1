[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\fee_audit_integration_$stamp"

function Full([string]$path) {
  Join-Path $root $path
}

function BackupFile([string]$path) {
  $source = Full $path
  if (-not (Test-Path $source)) {
    throw "Required file not found: $path"
  }

  $target = Join-Path $backup $path
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item $source $target -Force
}

function WriteFile([string]$path, [string]$text) {
  $target = Full $path
  $temp = "$target.audit_tmp"

  [IO.File]::WriteAllText(
    $temp,
    $text.Replace("`r`n", "`n"),
    $utf8
  )

  Copy-Item $temp $target -Force
  Remove-Item $temp -Force
}

if (-not (Test-Path (Full 'pubspec.yaml'))) {
  throw 'Run this script from the project root.'
}

$repository = 'lib/features/fees/data/repositories/fee_payment_repository_impl.dart'
$serviceLocator = 'lib/core/di/service_locator.dart'

BackupFile $repository
BackupFile $serviceLocator

$text = [IO.File]::ReadAllText((Full $repository)).Replace("`r`n", "`n")

$auditImport = "import '../../../../core/audit/domain/entities/audit_log_entity.dart';`nimport '../../../../core/audit/domain/services/audit_service.dart';`n"
$importAnchor = "import '../../../../core/constants/firestore_paths.dart';"

if (-not $text.Contains("core/audit/domain/services/audit_service.dart")) {
  if (-not $text.Contains($importAnchor)) {
    throw 'Fee repository import anchor not found.'
  }

  $text = $text.Replace(
    $importAnchor,
    $auditImport + $importAnchor
  )
}

$oldConstructor = @'
class FeePaymentRepositoryImpl implements FeePaymentRepository {
  const FeePaymentRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;
'@

$newConstructor = @'
class FeePaymentRepositoryImpl implements FeePaymentRepository {
  FeePaymentRepositoryImpl({
    required FirebaseFirestoreService firestoreService,
    required AuditService auditService,
  })  : _firestoreService = firestoreService,
        _auditService = auditService;

  final FirebaseFirestoreService _firestoreService;
  final AuditService _auditService;
'@

if ($text.Contains($oldConstructor)) {
  $text = $text.Replace($oldConstructor, $newConstructor)
} elseif (-not $text.Contains('final AuditService _auditService;')) {
  throw 'Fee repository constructor block not found.'
}

$collectAnchor = @'
    await batch.commit();
    return payment;
  }

  @override
  Future<void> cancelPayment({
'@

$collectReplacement = @'
    await batch.commit();

    await _auditService.log(
      module: 'Fees',
      action: AuditAction.collectPayment,
      recordId: payment.id,
      description:
          'Fee payment collected: ${payment.receiptNumber} for $studentName',
      newValues: {
        'receiptNumber': payment.receiptNumber,
        'studentId': payment.studentId,
        'studentName': payment.studentName,
        'admissionNo': payment.admissionNo,
        'academicSession': payment.academicSession,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'referenceNumber': payment.referenceNumber,
        'totalPaid': payment.totalPaid,
        'advanceAmount': payment.advanceAmount,
        'monthlyDueIds': dueIds,
        'additionalChargeDueIds': additionalChargeDueIds,
        'notes': payment.notes,
      },
    );

    return payment;
  }

  @override
  Future<void> cancelPayment({
'@

if (-not $text.Contains("description:`n          'Fee payment collected:")) {
  if (-not $text.Contains($collectAnchor)) {
    throw 'Fee collection completion block not found.'
  }
  $text = $text.Replace($collectAnchor, $collectReplacement)
}

$cancelAnchor = @'
    await batch.commit();
  }

  @override
  String generateId() {
'@

$cancelReplacement = @'
    await batch.commit();

    await _auditService.log(
      module: 'Fees',
      action: AuditAction.delete,
      recordId: payment.id,
      description:
          'Fee payment cancelled: ${payment.receiptNumber}. Reason: ${reason.trim()}',
      oldValues: {
        'receiptNumber': payment.receiptNumber,
        'studentId': payment.studentId,
        'studentName': payment.studentName,
        'admissionNo': payment.admissionNo,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'referenceNumber': payment.referenceNumber,
        'totalPaid': payment.totalPaid,
        'advanceAmount': payment.advanceAmount,
        'status': payment.status.name,
      },
      newValues: {
        'status': FeePaymentStatus.cancelled.name,
        'cancellationReason': reason.trim(),
        'cancelledAt': now.toIso8601String(),
      },
    );
  }

  @override
  String generateId() {
'@

if (-not $text.Contains("description:`n          'Fee payment cancelled:")) {
  $lastIndex = $text.LastIndexOf($cancelAnchor)
  if ($lastIndex -lt 0) {
    throw 'Fee cancellation completion block not found.'
  }

  $text = $text.Remove($lastIndex, $cancelAnchor.Length)
  $text = $text.Insert($lastIndex, $cancelReplacement)
}

WriteFile $repository $text

$di = [IO.File]::ReadAllText((Full $serviceLocator)).Replace("`r`n", "`n")

if (-not $di.Contains('auditService: sl<AuditService>()')) {
  $patterns = @(
    @'
  sl.registerLazySingleton<FeePaymentRepository>(
    () => FeePaymentRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
'@,
    @'
  sl.registerLazySingleton<FeePaymentRepository>(
    () => FeePaymentRepositoryImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
'@
  )

  $replacement = @'
  sl.registerLazySingleton<FeePaymentRepository>(
    () => FeePaymentRepositoryImpl(
      firestoreService: sl<FirebaseFirestoreService>(),
      auditService: sl<AuditService>(),
    ),
  );
'@

  $replaced = $false
  foreach ($pattern in $patterns) {
    if ($di.Contains($pattern)) {
      $di = $di.Replace($pattern, $replacement)
      $replaced = $true
      break
    }
  }

  if (-not $replaced) {
    $regex = 'sl\.registerLazySingleton<FeePaymentRepository>\(\s*\(\)\s*=>\s*FeePaymentRepositoryImpl\([\s\S]*?\),\s*\);'
    $match = [regex]::Match($di, $regex)

    if (-not $match.Success) {
      throw 'FeePaymentRepository DI registration was not found.'
    }

    $di = $di.Remove($match.Index, $match.Length)
    $di = $di.Insert($match.Index, $replacement.Trim())
  }

  WriteFile $serviceLocator $di
}

Write-Host ''
Write-Host 'Fee Audit Integration completed successfully.' -ForegroundColor Green
Write-Host 'Fee collection and payment cancellation now create audit logs.' -ForegroundColor Green
Write-Host 'Payment method, receipt, amount, student and allocation references are recorded.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
Write-Host ''
Write-Host 'Now run:' -ForegroundColor Yellow
Write-Host 'dart format .\lib\features\fees\data\repositories\fee_payment_repository_impl.dart .\lib\core\di\service_locator.dart'
Write-Host 'flutter analyze lib\features\fees lib\core\audit lib\core\di --no-fatal-infos --no-fatal-warnings'
