[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase2_recovery_$stamp"

function Full([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) { [IO.File]::ReadAllText((Full $Path)) }
function WriteUtf8([string]$Path,[string]$Text) {
  $full = Full $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText($full,$Text.Replace("`r`n","`n"),$utf8)
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
function InsertBefore([string]$Path,[string]$Anchor,[string]$TextToInsert) {
  $text = ReadUtf8 $Path
  if ($text.Contains($TextToInsert.Trim())) { return }
  $index = $text.IndexOf($Anchor,[StringComparison]::Ordinal)
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
  'lib/features/school_store/domain/entities/store_item_entity.dart',
  'lib/features/school_store/data/models/store_item_model.dart',
  'lib/features/school_store/domain/usecases/manage_store_items.dart',
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/di/service_locator.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (Full $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/school_store/domain/entities/store_supplier_entity.dart' @'
import 'package:equatable/equatable.dart';

class StoreSupplierEntity extends Equatable {
  const StoreSupplierEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.contactPerson = '',
    this.mobileNumber = '',
    this.address = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String contactPerson;
  final String mobileNumber;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        contactPerson,
        mobileNumber,
        address,
        isActive,
        createdAt,
        updatedAt,
      ];
}
'@

WriteUtf8 'lib/features/school_store/domain/entities/store_purchase_entity.dart' @'
import 'package:equatable/equatable.dart';

class StorePurchaseEntity extends Equatable {
  const StorePurchaseEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.itemId,
    required this.itemName,
    required this.invoiceNumber,
    required this.quantity,
    required this.unitPrice,
    required this.paidAmount,
    required this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String itemId;
  final String itemName;
  final String invoiceNumber;
  final int quantity;
  final double unitPrice;
  final double paidAmount;
  final DateTime purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get totalAmount => quantity * unitPrice;
  double get outstandingAmount => totalAmount - paidAmount;

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        itemId,
        itemName,
        invoiceNumber,
        quantity,
        unitPrice,
        paidAmount,
        purchaseDate,
        createdAt,
        updatedAt,
      ];
}
'@

WriteUtf8 'lib/features/school_store/data/models/store_supplier_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_supplier_entity.dart';

class StoreSupplierModel extends StoreSupplierEntity {
  const StoreSupplierModel({
    required super.id,
    required super.name,
    required super.createdAt,
    required super.updatedAt,
    super.contactPerson,
    super.mobileNumber,
    super.address,
    super.isActive,
  });

  factory StoreSupplierModel.fromEntity(
    StoreSupplierEntity entity,
  ) {
    return StoreSupplierModel(
      id: entity.id,
      name: entity.name,
      contactPerson: entity.contactPerson,
      mobileNumber: entity.mobileNumber,
      address: entity.address,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StoreSupplierModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSupplierModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactPerson: map['contactPerson'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'contactPerson': contactPerson,
        'mobileNumber': mobileNumber,
        'address': address,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/school_store/data/models/store_purchase_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_purchase_entity.dart';

class StorePurchaseModel extends StorePurchaseEntity {
  const StorePurchaseModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.itemId,
    required super.itemName,
    required super.invoiceNumber,
    required super.quantity,
    required super.unitPrice,
    required super.paidAmount,
    required super.purchaseDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StorePurchaseModel.fromEntity(
    StorePurchaseEntity entity,
  ) {
    return StorePurchaseModel(
      id: entity.id,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      itemId: entity.itemId,
      itemName: entity.itemName,
      invoiceNumber: entity.invoiceNumber,
      quantity: entity.quantity,
      unitPrice: entity.unitPrice,
      paidAmount: entity.paidAmount,
      purchaseDate: entity.purchaseDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StorePurchaseModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StorePurchaseModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      purchaseDate: date(map['purchaseDate']),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'itemId': itemId,
        'itemName': itemName,
        'invoiceNumber': invoiceNumber,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'paidAmount': paidAmount,
        'totalAmount': totalAmount,
        'outstandingAmount': outstandingAmount,
        'purchaseDate': purchaseDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/school_store/domain/repositories/store_purchase_repository.dart' @'
import '../entities/store_purchase_entity.dart';
import '../entities/store_supplier_entity.dart';

abstract class StorePurchaseRepository {
  Future<List<StoreSupplierEntity>> getSuppliers();
  Future<void> saveSupplier(StoreSupplierEntity supplier);
  Future<List<StorePurchaseEntity>> getPurchases();
  Future<void> savePurchase(StorePurchaseEntity purchase);
}
'@

WriteUtf8 'lib/features/school_store/data/datasources/store_purchase_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../models/store_item_model.dart';
import '../models/store_purchase_model.dart';
import '../models/store_supplier_model.dart';

abstract class StorePurchaseRemoteDataSource {
  Future<List<StoreSupplierEntity>> getSuppliers();
  Future<void> saveSupplier(StoreSupplierEntity supplier);
  Future<List<StorePurchaseEntity>> getPurchases();
  Future<void> savePurchase(StorePurchaseEntity purchase);
}

class StorePurchaseRemoteDataSourceImpl
    implements StorePurchaseRemoteDataSource {
  const StorePurchaseRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreSupplierEntity>> getSuppliers() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeSuppliers)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => StoreSupplierModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => a.name.compareTo(b.name));
    return values;
  }

  @override
  Future<void> saveSupplier(StoreSupplierEntity supplier) {
    return _service
        .collection(FirestorePaths.storeSuppliers)
        .doc(supplier.id)
        .set(StoreSupplierModel.fromEntity(supplier).toMap());
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() async {
    final snapshot = await _service
        .collection(FirestorePaths.storePurchases)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => StorePurchaseModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort(
      (a, b) => b.purchaseDate.compareTo(a.purchaseDate),
    );

    return values;
  }

  @override
  Future<void> savePurchase(StorePurchaseEntity purchase) async {
    final itemRef = _service
        .collection(FirestorePaths.storeItems)
        .doc(purchase.itemId);

    final itemDoc = await itemRef.get();

    if (!itemDoc.exists) {
      throw StateError('Selected store item was not found.');
    }

    final item = StoreItemModel.fromMap({
      ...itemDoc.data()!,
      'id': itemDoc.id,
    });

    final updatedItem = StoreItemEntity(
      id: item.id,
      name: item.name,
      category: item.category,
      purchasePrice: purchase.unitPrice,
      salePrice: item.salePrice,
      openingStock: item.openingStock,
      purchasedQuantity:
          item.purchasedQuantity + purchase.quantity,
      soldQuantity: item.soldQuantity,
      lowStockLevel: item.lowStockLevel,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      itemCode: item.itemCode,
      notes: item.notes,
    );

    await _service
        .collection(FirestorePaths.storePurchases)
        .doc(purchase.id)
        .set(StorePurchaseModel.fromEntity(purchase).toMap());

    await itemRef.set(
      StoreItemModel.fromEntity(updatedItem).toMap(),
    );
  }
}
'@

WriteUtf8 'lib/features/school_store/data/repositories/store_purchase_repository_impl.dart' @'
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../../domain/repositories/store_purchase_repository.dart';
import '../datasources/store_purchase_remote_datasource.dart';

class StorePurchaseRepositoryImpl
    implements StorePurchaseRepository {
  const StorePurchaseRepositoryImpl(this._source);

  final StorePurchaseRemoteDataSource _source;

  @override
  Future<List<StoreSupplierEntity>> getSuppliers() {
    return _source.getSuppliers();
  }

  @override
  Future<void> saveSupplier(StoreSupplierEntity supplier) {
    return _source.saveSupplier(supplier);
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() {
    return _source.getPurchases();
  }

  @override
  Future<void> savePurchase(StorePurchaseEntity purchase) {
    return _source.savePurchase(purchase);
  }
}
'@

WriteUtf8 'lib/features/school_store/domain/usecases/manage_store_purchases.dart' @'
import '../entities/store_purchase_entity.dart';
import '../entities/store_supplier_entity.dart';
import '../repositories/store_purchase_repository.dart';

class GetStoreSuppliers {
  const GetStoreSuppliers(this._repository);

  final StorePurchaseRepository _repository;

  Future<List<StoreSupplierEntity>> call() {
    return _repository.getSuppliers();
  }
}

class SaveStoreSupplier {
  const SaveStoreSupplier(this._repository);

  final StorePurchaseRepository _repository;

  Future<void> call(StoreSupplierEntity supplier) {
    if (supplier.name.trim().isEmpty) {
      throw ArgumentError('Supplier name is required.');
    }
    return _repository.saveSupplier(supplier);
  }
}

class GetStorePurchases {
  const GetStorePurchases(this._repository);

  final StorePurchaseRepository _repository;

  Future<List<StorePurchaseEntity>> call() {
    return _repository.getPurchases();
  }
}

class SaveStorePurchase {
  const SaveStorePurchase(this._repository);

  final StorePurchaseRepository _repository;

  Future<void> call(StorePurchaseEntity purchase) {
    if (purchase.supplierId.trim().isEmpty) {
      throw ArgumentError('Supplier is required.');
    }
    if (purchase.itemId.trim().isEmpty) {
      throw ArgumentError('Item is required.');
    }
    if (purchase.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (purchase.unitPrice < 0) {
      throw ArgumentError('Purchase price cannot be negative.');
    }
    if (purchase.paidAmount < 0 ||
        purchase.paidAmount > purchase.totalAmount) {
      throw ArgumentError('Paid amount is invalid.');
    }
    return _repository.savePurchase(purchase);
  }
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_purchase_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';

sealed class StorePurchaseEvent extends Equatable {
  const StorePurchaseEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStorePurchases extends StorePurchaseEvent {
  const LoadStorePurchases();
}

class SaveStoreSupplierRequested extends StorePurchaseEvent {
  const SaveStoreSupplierRequested(this.supplier);

  final StoreSupplierEntity supplier;

  @override
  List<Object?> get props => [supplier];
}

class SaveStorePurchaseRequested extends StorePurchaseEvent {
  const SaveStorePurchaseRequested(this.purchase);

  final StorePurchaseEntity purchase;

  @override
  List<Object?> get props => [purchase];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_purchase_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';

sealed class StorePurchaseState extends Equatable {
  const StorePurchaseState();

  @override
  List<Object?> get props => const [];
}

class StorePurchaseInitial extends StorePurchaseState {
  const StorePurchaseInitial();
}

class StorePurchaseLoading extends StorePurchaseState {
  const StorePurchaseLoading();
}

class StorePurchaseLoaded extends StorePurchaseState {
  const StorePurchaseLoaded({
    required this.suppliers,
    required this.purchases,
    required this.items,
    this.message,
  });

  final List<StoreSupplierEntity> suppliers;
  final List<StorePurchaseEntity> purchases;
  final List<StoreItemEntity> items;
  final String? message;

  double get totalPurchases => purchases.fold<double>(
        0,
        (sum, item) => sum + item.totalAmount,
      );

  double get totalPaid => purchases.fold<double>(
        0,
        (sum, item) => sum + item.paidAmount,
      );

  double get outstanding => purchases.fold<double>(
        0,
        (sum, item) => sum + item.outstandingAmount,
      );

  @override
  List<Object?> get props => [
        suppliers,
        purchases,
        items,
        message,
      ];
}

class StorePurchaseFailure extends StorePurchaseState {
  const StorePurchaseFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_purchase_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../../domain/usecases/manage_store_items.dart';
import '../../domain/usecases/manage_store_purchases.dart';
import 'store_purchase_event.dart';
import 'store_purchase_state.dart';

class StorePurchaseBloc
    extends Bloc<StorePurchaseEvent, StorePurchaseState> {
  StorePurchaseBloc({
    required GetStoreSuppliers getSuppliers,
    required SaveStoreSupplier saveSupplier,
    required GetStorePurchases getPurchases,
    required SaveStorePurchase savePurchase,
    required GetStoreItems getItems,
  })  : _getSuppliers = getSuppliers,
        _saveSupplier = saveSupplier,
        _getPurchases = getPurchases,
        _savePurchase = savePurchase,
        _getItems = getItems,
        super(const StorePurchaseInitial()) {
    on<LoadStorePurchases>(_load);
    on<SaveStoreSupplierRequested>(_saveSupplierEvent);
    on<SaveStorePurchaseRequested>(_savePurchaseEvent);
  }

  final GetStoreSuppliers _getSuppliers;
  final SaveStoreSupplier _saveSupplier;
  final GetStorePurchases _getPurchases;
  final SaveStorePurchase _savePurchase;
  final GetStoreItems _getItems;

  Future<void> _load(
    LoadStorePurchases event,
    Emitter<StorePurchaseState> emit,
  ) async {
    emit(const StorePurchaseLoading());
    await _reload(emit);
  }

  Future<void> _saveSupplierEvent(
    SaveStoreSupplierRequested event,
    Emitter<StorePurchaseState> emit,
  ) async {
    try {
      await _saveSupplier(event.supplier);
      await _reload(
        emit,
        message: 'Supplier saved successfully.',
      );
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  Future<void> _savePurchaseEvent(
    SaveStorePurchaseRequested event,
    Emitter<StorePurchaseState> emit,
  ) async {
    try {
      await _savePurchase(event.purchase);
      await _reload(
        emit,
        message: 'Purchase saved and stock updated.',
      );
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StorePurchaseState> emit, {
    String? message,
  }) async {
    try {
      final values = await Future.wait<Object>([
        _getSuppliers(),
        _getPurchases(),
        _getItems(),
      ]);

      emit(
        StorePurchaseLoaded(
          suppliers:
              values[0] as List<StoreSupplierEntity>,
          purchases:
              values[1] as List<StorePurchaseEntity>,
          items: values[2] as List<StoreItemEntity>,
          message: message,
        ),
      );
    } catch (error) {
      emit(StorePurchaseFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/school_store/presentation/pages/store_purchases_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_supplier_entity.dart';
import '../bloc/store_purchase_bloc.dart';
import '../bloc/store_purchase_event.dart';
import '../bloc/store_purchase_state.dart';

class StorePurchasesPage extends StatelessWidget {
  const StorePurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StorePurchaseBloc>()..add(const LoadStorePurchases()),
      child: const _StorePurchasesView(),
    );
  }
}

class _StorePurchasesView extends StatelessWidget {
  const _StorePurchasesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers & Purchases'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StorePurchaseBloc, StorePurchaseState>(
        listener: (context, state) {
          if (state is StorePurchaseLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is StorePurchaseInitial ||
              state is StorePurchaseLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is StorePurchaseFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StorePurchaseLoaded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text(
                      'Suppliers: ${data.suppliers.length}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Purchases: Rs. ${data.totalPurchases.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Paid: Rs. ${data.totalPaid.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Due: Rs. ${data.outstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showSupplierDialog(context),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Supplier'),
                  ),
                  FilledButton.icon(
                    onPressed: data.suppliers.isEmpty ||
                            data.items.isEmpty
                        ? null
                        : () => _showPurchaseDialog(
                              context,
                              data,
                            ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('New Purchase'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Supplier Ledger',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.suppliers.map((supplier) {
                final purchases = data.purchases.where(
                  (item) => item.supplierId == supplier.id,
                );

                final total = purchases.fold<double>(
                  0,
                  (sum, item) => sum + item.totalAmount,
                );

                final paid = purchases.fold<double>(
                  0,
                  (sum, item) => sum + item.paidAmount,
                );

                return Card(
                  child: ListTile(
                    title: Text(supplier.name),
                    subtitle: Text(
                      'Purchase Rs. ${total.toStringAsFixed(0)} - '
                      'Paid Rs. ${paid.toStringAsFixed(0)}',
                    ),
                    trailing: Text(
                      'Due Rs. ${(total - paid).toStringAsFixed(0)}',
                    ),
                  ),
                );
              }),
              const SizedBox(height: 18),
              Text(
                'Purchase History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (data.purchases.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No purchases found.'),
                  ),
                ),
              ...data.purchases.map(
                (purchase) => Card(
                  child: ListTile(
                    title: Text(purchase.itemName),
                    subtitle: Text(
                      '${purchase.supplierName} - '
                      'Qty ${purchase.quantity} - '
                      '${purchase.invoiceNumber}',
                    ),
                    trailing: Text(
                      'Rs. ${purchase.totalAmount.toStringAsFixed(0)}',
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

  static Future<void> _showSupplierDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Supplier Name',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePurchaseBloc>().add(
            SaveStoreSupplierRequested(
              StoreSupplierEntity(
                id: 'supplier_${now.microsecondsSinceEpoch}',
                name: nameController.text.trim(),
                mobileNumber: mobileController.text.trim(),
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
    }

    nameController.dispose();
    mobileController.dispose();
  }

  static Future<void> _showPurchaseDialog(
    BuildContext context,
    StorePurchaseLoaded data,
  ) async {
    var supplier = data.suppliers.first;
    var item = data.items.first;

    final invoiceController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController(
      text: item.purchasePrice.toString(),
    );
    final paidController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Purchase'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StoreSupplierEntity>(
                  initialValue: supplier,
                  items: data.suppliers
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(
                        () => supplier = value,
                      );
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<StoreItemEntity>(
                  initialValue: item,
                  items: data.items
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        item = value;
                        priceController.text =
                            value.purchasePrice.toString();
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Item',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: invoiceController,
                  decoration: const InputDecoration(
                    labelText: 'Invoice Number',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: paidController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Paid Amount',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePurchaseBloc>().add(
            SaveStorePurchaseRequested(
              StorePurchaseEntity(
                id: 'purchase_${now.microsecondsSinceEpoch}',
                supplierId: supplier.id,
                supplierName: supplier.name,
                itemId: item.id,
                itemName: item.name,
                invoiceNumber:
                    invoiceController.text.trim(),
                quantity:
                    int.tryParse(quantityController.text) ?? 0,
                unitPrice:
                    double.tryParse(priceController.text) ?? 0,
                paidAmount:
                    double.tryParse(paidController.text) ?? 0,
                purchaseDate: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
    }

    invoiceController.dispose();
    quantityController.dispose();
    priceController.dispose();
    paidController.dispose();
  }
}
'@

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

# Repair accidental joined import from failed installer.
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

InsertBefore `
  $slFile `
  "import '../../features/school_store/data/datasources/school_store_remote_datasource.dart';" `
  $imports

$block = @"
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

InsertBefore `
  $slFile `
  '  sl.registerLazySingleton<SchoolStoreRemoteDataSource>(' `
  $block

$dashboardFile = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'
$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  "import 'store_purchases_page.dart';"
)) {
  $dashboardText = $dashboardText.Replace(
    "import '../bloc/school_store_state.dart';",
    "import '../bloc/school_store_state.dart';`nimport 'store_purchases_page.dart';"
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
    throw 'SCHOOL STORE DASHBOARD BUTTON ANCHOR ERROR.'
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

& flutter analyze `
  lib/features/school_store `
  --no-fatal-infos `
  --no-fatal-warnings

if ($LASTEXITCODE -ne 0) {
  throw "SCHOOL STORE ANALYZE ERROR. Backup: $backup"
}

Write-Host ''
Write-Host 'School Store Phase 2 recovery installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
