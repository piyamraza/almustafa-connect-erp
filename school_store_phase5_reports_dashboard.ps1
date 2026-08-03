[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase5_$stamp"

function FullPath([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((FullPath $Path)) }
function WriteUtf8([string]$Path,[string]$Text) {
  $full = FullPath $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText($full,$Text.Replace("`r`n","`n"),$utf8)
}
function BackupFile([string]$Path) {
  $source = FullPath $Path
  if (-not (Test-Path $source)) { return }
  $target = Join-Path $backup $Path
  $dir = Split-Path $target -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  Copy-Item $source $target -Force
}
function InsertBefore([string]$Path,[string]$Anchor,[string]$InsertText) {
  $text = ReadUtf8 $Path
  if ($text.Contains($InsertText.Trim())) { return }
  $index = $text.IndexOf($Anchor,[StringComparison]::Ordinal)
  if ($index -lt 0) {
    throw "ANCHOR ERROR in $Path : $Anchor"
  }
  BackupFile $Path
  WriteUtf8 $Path (
    $text.Substring(0,$index) +
    $InsertText +
    $text.Substring($index)
  )
}

if (-not (Test-Path (FullPath 'pubspec.yaml'))) {
  throw 'PROJECT ROOT ERROR: Run from Flutter project root.'
}

$required = @(
  'lib/features/school_store/domain/entities/store_item_entity.dart',
  'lib/features/school_store/domain/entities/store_purchase_entity.dart',
  'lib/features/school_store/domain/entities/store_sale_entity.dart',
  'lib/features/school_store/domain/entities/store_student_payment_entity.dart',
  'lib/features/school_store/domain/entities/store_supplier_payment_entity.dart',
  'lib/features/school_store/domain/repositories/school_store_repository.dart',
  'lib/features/school_store/domain/repositories/store_purchase_repository.dart',
  'lib/features/school_store/domain/repositories/store_sale_repository.dart',
  'lib/features/school_store/domain/repositories/store_payment_repository.dart',
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/di/service_locator.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (FullPath $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (FullPath 'lib/features/school_store/domain/entities/store_report_entity.dart')) {
  throw 'EXISTING FILE ERROR: School Store Phase 5 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in @(
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/di/service_locator.dart'
)) {
  BackupFile $path
}

WriteUtf8 'lib/features/school_store/domain/entities/store_report_entity.dart' @'
import 'package:equatable/equatable.dart';

class StoreItemMovementEntity extends Equatable {
  const StoreItemMovementEntity({
    required this.itemId,
    required this.itemName,
    required this.openingStock,
    required this.purchasedQuantity,
    required this.soldQuantity,
    required this.currentStock,
    required this.stockValue,
    required this.salesAmount,
    required this.profitAmount,
  });

  final String itemId;
  final String itemName;
  final int openingStock;
  final int purchasedQuantity;
  final int soldQuantity;
  final int currentStock;
  final double stockValue;
  final double salesAmount;
  final double profitAmount;

  @override
  List<Object?> get props => [
        itemId,
        itemName,
        openingStock,
        purchasedQuantity,
        soldQuantity,
        currentStock,
        stockValue,
        salesAmount,
        profitAmount,
      ];
}

class StorePartyBalanceEntity extends Equatable {
  const StorePartyBalanceEntity({
    required this.id,
    required this.name,
    required this.reference,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  final String id;
  final String name;
  final String reference;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  @override
  List<Object?> get props => [
        id,
        name,
        reference,
        totalAmount,
        paidAmount,
        outstandingAmount,
      ];
}

class StoreReportEntity extends Equatable {
  const StoreReportEntity({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalProfit,
    required this.stockValue,
    required this.studentReceivable,
    required this.supplierPayable,
    required this.lowStockCount,
    required this.itemMovements,
    required this.studentBalances,
    required this.supplierBalances,
  });

  final double totalSales;
  final double totalPurchases;
  final double totalProfit;
  final double stockValue;
  final double studentReceivable;
  final double supplierPayable;
  final int lowStockCount;
  final List<StoreItemMovementEntity> itemMovements;
  final List<StorePartyBalanceEntity> studentBalances;
  final List<StorePartyBalanceEntity> supplierBalances;

  @override
  List<Object?> get props => [
        totalSales,
        totalPurchases,
        totalProfit,
        stockValue,
        studentReceivable,
        supplierPayable,
        lowStockCount,
        itemMovements,
        studentBalances,
        supplierBalances,
      ];
}
'@

WriteUtf8 'lib/features/school_store/domain/usecases/get_store_reports.dart' @'
import '../entities/store_item_entity.dart';
import '../entities/store_purchase_entity.dart';
import '../entities/store_report_entity.dart';
import '../entities/store_sale_entity.dart';
import '../repositories/school_store_repository.dart';
import '../repositories/store_payment_repository.dart';
import '../repositories/store_purchase_repository.dart';
import '../repositories/store_sale_repository.dart';

class GetStoreReports {
  const GetStoreReports({
    required SchoolStoreRepository storeRepository,
    required StorePurchaseRepository purchaseRepository,
    required StoreSaleRepository saleRepository,
    required StorePaymentRepository paymentRepository,
  })  : _storeRepository = storeRepository,
        _purchaseRepository = purchaseRepository,
        _saleRepository = saleRepository,
        _paymentRepository = paymentRepository;

  final SchoolStoreRepository _storeRepository;
  final StorePurchaseRepository _purchaseRepository;
  final StoreSaleRepository _saleRepository;
  final StorePaymentRepository _paymentRepository;

  Future<StoreReportEntity> call() async {
    final values = await Future.wait<Object>([
      _storeRepository.getItems(),
      _purchaseRepository.getPurchases(),
      _saleRepository.getSales(),
      _paymentRepository.getStudentPayments(),
      _paymentRepository.getSupplierPayments(),
    ]);

    final items = values[0] as List<StoreItemEntity>;
    final purchases = values[1] as List<StorePurchaseEntity>;
    final sales = values[2] as List<StoreSaleEntity>;

    final totalSales = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.netAmount,
    );

    final totalPurchases = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.totalAmount,
    );

    final totalProfit = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.profitAmount,
    );

    final stockValue = items.fold<double>(
      0,
      (sum, item) => sum + item.stockValue,
    );

    final studentReceivable = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.outstandingAmount,
    );

    final supplierPayable = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.outstandingAmount,
    );

    final itemMovements = items.map((item) {
      final itemSales = sales.where(
        (sale) => sale.itemId == item.id,
      );

      return StoreItemMovementEntity(
        itemId: item.id,
        itemName: item.name,
        openingStock: item.openingStock,
        purchasedQuantity: item.purchasedQuantity,
        soldQuantity: item.soldQuantity,
        currentStock: item.currentStock,
        stockValue: item.stockValue,
        salesAmount: itemSales.fold<double>(
          0,
          (sum, sale) => sum + sale.netAmount,
        ),
        profitAmount: itemSales.fold<double>(
          0,
          (sum, sale) => sum + sale.profitAmount,
        ),
      );
    }).toList()
      ..sort((a, b) => b.soldQuantity.compareTo(a.soldQuantity));

    final studentMap = <String, StorePartyBalanceEntity>{};

    for (final sale in sales) {
      final existing = studentMap[sale.studentId];

      studentMap[sale.studentId] = StorePartyBalanceEntity(
        id: sale.studentId,
        name: sale.studentName,
        reference: sale.admissionNo,
        totalAmount:
            (existing?.totalAmount ?? 0) + sale.netAmount,
        paidAmount:
            (existing?.paidAmount ?? 0) + sale.paidAmount,
        outstandingAmount:
            (existing?.outstandingAmount ?? 0) +
            sale.outstandingAmount,
      );
    }

    final supplierMap = <String, StorePartyBalanceEntity>{};

    for (final purchase in purchases) {
      final existing = supplierMap[purchase.supplierId];

      supplierMap[purchase.supplierId] =
          StorePartyBalanceEntity(
        id: purchase.supplierId,
        name: purchase.supplierName,
        reference: '',
        totalAmount:
            (existing?.totalAmount ?? 0) +
            purchase.totalAmount,
        paidAmount:
            (existing?.paidAmount ?? 0) +
            purchase.paidAmount,
        outstandingAmount:
            (existing?.outstandingAmount ?? 0) +
            purchase.outstandingAmount,
      );
    }

    final studentBalances = studentMap.values.toList()
      ..sort(
        (a, b) =>
            b.outstandingAmount.compareTo(a.outstandingAmount),
      );

    final supplierBalances = supplierMap.values.toList()
      ..sort(
        (a, b) =>
            b.outstandingAmount.compareTo(a.outstandingAmount),
      );

    return StoreReportEntity(
      totalSales: totalSales,
      totalPurchases: totalPurchases,
      totalProfit: totalProfit,
      stockValue: stockValue,
      studentReceivable: studentReceivable,
      supplierPayable: supplierPayable,
      lowStockCount:
          items.where((item) => item.isLowStock).length,
      itemMovements: itemMovements,
      studentBalances: studentBalances,
      supplierBalances: supplierBalances,
    );
  }
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_reports_event.dart' @'
import 'package:equatable/equatable.dart';

sealed class StoreReportsEvent extends Equatable {
  const StoreReportsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStoreReports extends StoreReportsEvent {
  const LoadStoreReports();
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_reports_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_report_entity.dart';

sealed class StoreReportsState extends Equatable {
  const StoreReportsState();

  @override
  List<Object?> get props => const [];
}

class StoreReportsInitial extends StoreReportsState {
  const StoreReportsInitial();
}

class StoreReportsLoading extends StoreReportsState {
  const StoreReportsLoading();
}

class StoreReportsLoaded extends StoreReportsState {
  const StoreReportsLoaded(this.report);

  final StoreReportEntity report;

  @override
  List<Object?> get props => [report];
}

class StoreReportsFailure extends StoreReportsState {
  const StoreReportsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_reports_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_store_reports.dart';
import 'store_reports_event.dart';
import 'store_reports_state.dart';

class StoreReportsBloc
    extends Bloc<StoreReportsEvent, StoreReportsState> {
  StoreReportsBloc(this._getReports)
      : super(const StoreReportsInitial()) {
    on<LoadStoreReports>(_load);
  }

  final GetStoreReports _getReports;

  Future<void> _load(
    LoadStoreReports event,
    Emitter<StoreReportsState> emit,
  ) async {
    emit(const StoreReportsLoading());

    try {
      emit(
        StoreReportsLoaded(
          await _getReports(),
        ),
      );
    } catch (error) {
      emit(
        StoreReportsFailure(
          error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
'@

WriteUtf8 'lib/features/school_store/presentation/pages/store_reports_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../bloc/store_reports_bloc.dart';
import '../bloc/store_reports_event.dart';
import '../bloc/store_reports_state.dart';

class StoreReportsPage extends StatelessWidget {
  const StoreReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StoreReportsBloc>()..add(const LoadStoreReports()),
      child: const _StoreReportsView(),
    );
  }
}

class _StoreReportsView extends StatelessWidget {
  const _StoreReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('School Store Reports'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocBuilder<StoreReportsBloc, StoreReportsState>(
        builder: (context, state) {
          if (state is StoreReportsInitial ||
              state is StoreReportsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is StoreReportsFailure) {
            return Center(child: Text(state.message));
          }

          final report =
              (state as StoreReportsLoaded).report;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Total Sales',
                    value:
                        'Rs. ${report.totalSales.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Total Purchases',
                    value:
                        'Rs. ${report.totalPurchases.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Profit',
                    value:
                        'Rs. ${report.totalProfit.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Stock Value',
                    value:
                        'Rs. ${report.stockValue.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Student Receivable',
                    value:
                        'Rs. ${report.studentReceivable.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Supplier Payable',
                    value:
                        'Rs. ${report.supplierPayable.toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Low Stock Items',
                    value: '${report.lowStockCount}',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Stock Movement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.itemMovements.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.itemName),
                    subtitle: Text(
                      'Opening ${item.openingStock} - '
                      'Purchased ${item.purchasedQuantity} - '
                      'Sold ${item.soldQuantity} - '
                      'Balance ${item.currentStock}',
                    ),
                    trailing: Text(
                      'Profit Rs. ${item.profitAmount.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Student Outstanding Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.studentBalances
                  .where(
                    (value) => value.outstandingAmount > 0,
                  )
                  .map(
                    (value) => Card(
                      child: ListTile(
                        title: Text(value.name),
                        subtitle: Text(value.reference),
                        trailing: Text(
                          'Due Rs. ${value.outstandingAmount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 22),
              Text(
                'Supplier Outstanding Report',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...report.supplierBalances
                  .where(
                    (value) => value.outstandingAmount > 0,
                  )
                  .map(
                    (value) => Card(
                      child: ListTile(
                        title: Text(value.name),
                        trailing: Text(
                          'Due Rs. ${value.outstandingAmount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/school_store/domain/usecases/get_store_reports.dart';
import '../../features/school_store/presentation/bloc/store_reports_bloc.dart';
"@

if (-not $slText.Contains('get_store_reports.dart')) {
  InsertBefore `
    $slFile `
    "import '../../features/school_store/domain/usecases/manage_store_payments.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<GetStoreReports>(
    () => GetStoreReports(
      storeRepository: sl<SchoolStoreRepository>(),
      purchaseRepository: sl<StorePurchaseRepository>(),
      saleRepository: sl<StoreSaleRepository>(),
      paymentRepository: sl<StorePaymentRepository>(),
    ),
  );
  sl.registerFactory<StoreReportsBloc>(
    () => StoreReportsBloc(
      sl<GetStoreReports>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<GetStoreReports>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<StorePaymentRemoteDataSource>(' `
    $registrations
}

$dashboardFile = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'
$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  "import 'store_reports_page.dart';"
)) {
  $anchor = "import 'store_payments_page.dart';"

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD IMPORT ANCHOR ERROR.'
  }

  BackupFile $dashboardFile
  WriteUtf8 $dashboardFile (
    $dashboardText.Replace(
      $anchor,
      "$anchor`nimport 'store_reports_page.dart';"
    )
  )
}

$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  'const StoreReportsPage()'
)) {
  $anchor = @"
            const SizedBox(height: 18),
            ...d.items.map(
"@

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD REPORT BUTTON ANCHOR ERROR.'
  }

  $replacement = @"
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(c).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const StoreReportsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Reports'),
              ),
            ),
            const SizedBox(height: 18),
            ...d.items.map(
"@

  BackupFile $dashboardFile
  WriteUtf8 $dashboardFile (
    $dashboardText.Replace($anchor,$replacement)
  )
}

& dart format `
  lib/features/school_store `
  lib/core/di/service_locator.dart

if ($LASTEXITCODE -ne 0) {
  throw "DART FORMAT ERROR. Backup: $backup"
}

& flutter analyze `
  lib/features/school_store `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "SCHOOL STORE ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'School Store Phase 5 Reports installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
