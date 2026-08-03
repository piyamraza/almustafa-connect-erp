[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase3_$stamp"

function FullPath([string]$Path) { Join-Path $root $Path }
function ReadUtf8([string]$Path) {
  [IO.File]::ReadAllText((FullPath $Path))
}
function WriteUtf8([string]$Path,[string]$Text) {
  $full = FullPath $Path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  [IO.File]::WriteAllText(
    $full,
    $Text.Replace("`r`n","`n"),
    $utf8
  )
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
function InsertBefore(
  [string]$Path,
  [string]$Anchor,
  [string]$InsertText
) {
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
  'lib/features/school_store/data/models/store_item_model.dart',
  'lib/features/school_store/domain/usecases/manage_store_items.dart',
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (FullPath $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (FullPath 'lib/features/school_store/domain/entities/store_sale_entity.dart')) {
  throw 'EXISTING FILE ERROR: School Store Phase 3 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/school_store/domain/entities/store_student_option_entity.dart' @'
import 'package:equatable/equatable.dart';

class StoreStudentOptionEntity extends Equatable {
  const StoreStudentOptionEntity({
    required this.id,
    required this.admissionNo,
    required this.name,
    required this.classId,
    required this.sectionId,
  });

  final String id;
  final String admissionNo;
  final String name;
  final String classId;
  final String sectionId;

  String get displayName {
    final admission = admissionNo.trim();
    return admission.isEmpty ? name : '$name ($admission)';
  }

  @override
  List<Object?> get props => [
        id,
        admissionNo,
        name,
        classId,
        sectionId,
      ];
}
'@

WriteUtf8 'lib/features/school_store/domain/entities/store_sale_entity.dart' @'
import 'package:equatable/equatable.dart';

enum StoreSalePaymentStatus {
  paid,
  partial,
  credit,
}

class StoreSaleEntity extends Equatable {
  const StoreSaleEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.sectionId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.unitSalePrice,
    required this.unitPurchasePrice,
    required this.discount,
    required this.paidAmount,
    required this.saleDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String sectionId;
  final String itemId;
  final String itemName;
  final int quantity;
  final double unitSalePrice;
  final double unitPurchasePrice;
  final double discount;
  final double paidAmount;
  final DateTime saleDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String notes;

  double get grossAmount => quantity * unitSalePrice;

  double get netAmount {
    final value = grossAmount - discount;
    return value < 0 ? 0 : value;
  }

  double get outstandingAmount => netAmount - paidAmount;

  double get costAmount => quantity * unitPurchasePrice;

  double get profitAmount => netAmount - costAmount;

  StoreSalePaymentStatus get paymentStatus {
    if (paidAmount <= 0) {
      return StoreSalePaymentStatus.credit;
    }
    if (paidAmount < netAmount) {
      return StoreSalePaymentStatus.partial;
    }
    return StoreSalePaymentStatus.paid;
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        admissionNo,
        classId,
        sectionId,
        itemId,
        itemName,
        quantity,
        unitSalePrice,
        unitPurchasePrice,
        discount,
        paidAmount,
        saleDate,
        createdAt,
        updatedAt,
        notes,
      ];
}
'@

WriteUtf8 'lib/features/school_store/data/models/store_sale_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_sale_entity.dart';

class StoreSaleModel extends StoreSaleEntity {
  const StoreSaleModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.sectionId,
    required super.itemId,
    required super.itemName,
    required super.quantity,
    required super.unitSalePrice,
    required super.unitPurchasePrice,
    required super.discount,
    required super.paidAmount,
    required super.saleDate,
    required super.createdAt,
    required super.updatedAt,
    super.notes,
  });

  factory StoreSaleModel.fromEntity(StoreSaleEntity entity) {
    return StoreSaleModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      classId: entity.classId,
      sectionId: entity.sectionId,
      itemId: entity.itemId,
      itemName: entity.itemName,
      quantity: entity.quantity,
      unitSalePrice: entity.unitSalePrice,
      unitPurchasePrice: entity.unitPurchasePrice,
      discount: entity.discount,
      paidAmount: entity.paidAmount,
      saleDate: entity.saleDate,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      notes: entity.notes,
    );
  }

  factory StoreSaleModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSaleModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      sectionId: map['sectionId'] as String? ?? '',
      itemId: map['itemId'] as String? ?? '',
      itemName: map['itemName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      unitSalePrice:
          (map['unitSalePrice'] as num?)?.toDouble() ?? 0,
      unitPurchasePrice:
          (map['unitPurchasePrice'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      paidAmount:
          (map['paidAmount'] as num?)?.toDouble() ?? 0,
      saleDate: date(map['saleDate']),
      createdAt: date(map['createdAt']),
      updatedAt: date(map['updatedAt']),
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'admissionNo': admissionNo,
        'classId': classId,
        'sectionId': sectionId,
        'itemId': itemId,
        'itemName': itemName,
        'quantity': quantity,
        'unitSalePrice': unitSalePrice,
        'unitPurchasePrice': unitPurchasePrice,
        'discount': discount,
        'grossAmount': grossAmount,
        'netAmount': netAmount,
        'paidAmount': paidAmount,
        'outstandingAmount': outstandingAmount,
        'costAmount': costAmount,
        'profitAmount': profitAmount,
        'paymentStatus': paymentStatus.name,
        'saleDate': saleDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/school_store/domain/repositories/store_sale_repository.dart' @'
import '../entities/store_sale_entity.dart';
import '../entities/store_student_option_entity.dart';

abstract class StoreSaleRepository {
  Future<List<StoreStudentOptionEntity>> getStudents();
  Future<List<StoreSaleEntity>> getSales();
  Future<void> saveSale(StoreSaleEntity sale);
}
'@

WriteUtf8 'lib/features/school_store/data/datasources/store_sale_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../models/store_item_model.dart';
import '../models/store_sale_model.dart';

abstract class StoreSaleRemoteDataSource {
  Future<List<StoreStudentOptionEntity>> getStudents();
  Future<List<StoreSaleEntity>> getSales();
  Future<void> saveSale(StoreSaleEntity sale);
}

class StoreSaleRemoteDataSourceImpl
    implements StoreSaleRemoteDataSource {
  const StoreSaleRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

  @override
  Future<List<StoreStudentOptionEntity>> getStudents() async {
    final snapshot = await _service
        .collection(FirestorePaths.students)
        .get();

    final students = snapshot.docs.map((doc) {
      final map = doc.data();
      final firstName = map['firstName'] as String? ?? '';
      final lastName = map['lastName'] as String? ?? '';
      final name = '$firstName $lastName'.trim();

      return StoreStudentOptionEntity(
        id: doc.id,
        admissionNo: map['admissionNo'] as String? ?? '',
        name: name.isEmpty ? 'Unnamed Student' : name,
        classId: map['classId'] as String? ?? '',
        sectionId: map['sectionId'] as String? ?? '',
      );
    }).toList();

    students.sort((a, b) => a.name.compareTo(b.name));
    return students;
  }

  @override
  Future<List<StoreSaleEntity>> getSales() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeSales)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => StoreSaleModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return values;
  }

  @override
  Future<void> saveSale(StoreSaleEntity sale) async {
    final itemRef = _service
        .collection(FirestorePaths.storeItems)
        .doc(sale.itemId);

    final itemDoc = await itemRef.get();

    if (!itemDoc.exists) {
      throw StateError('Selected store item was not found.');
    }

    final item = StoreItemModel.fromMap({
      ...itemDoc.data()!,
      'id': itemDoc.id,
    });

    if (sale.quantity > item.currentStock) {
      throw StateError(
        'Only ${item.currentStock} units are available.',
      );
    }

    final updatedItem = StoreItemEntity(
      id: item.id,
      name: item.name,
      category: item.category,
      purchasePrice: item.purchasePrice,
      salePrice: item.salePrice,
      openingStock: item.openingStock,
      purchasedQuantity: item.purchasedQuantity,
      soldQuantity: item.soldQuantity + sale.quantity,
      lowStockLevel: item.lowStockLevel,
      isActive: item.isActive,
      createdAt: item.createdAt,
      updatedAt: DateTime.now(),
      itemCode: item.itemCode,
      notes: item.notes,
    );

    await _service
        .collection(FirestorePaths.storeSales)
        .doc(sale.id)
        .set(StoreSaleModel.fromEntity(sale).toMap());

    await itemRef.set(
      StoreItemModel.fromEntity(updatedItem).toMap(),
    );
  }
}
'@

WriteUtf8 'lib/features/school_store/data/repositories/store_sale_repository_impl.dart' @'
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../../domain/repositories/store_sale_repository.dart';
import '../datasources/store_sale_remote_datasource.dart';

class StoreSaleRepositoryImpl
    implements StoreSaleRepository {
  const StoreSaleRepositoryImpl(this._source);

  final StoreSaleRemoteDataSource _source;

  @override
  Future<List<StoreStudentOptionEntity>> getStudents() {
    return _source.getStudents();
  }

  @override
  Future<List<StoreSaleEntity>> getSales() {
    return _source.getSales();
  }

  @override
  Future<void> saveSale(StoreSaleEntity sale) {
    return _source.saveSale(sale);
  }
}
'@

WriteUtf8 'lib/features/school_store/domain/usecases/manage_store_sales.dart' @'
import '../entities/store_sale_entity.dart';
import '../entities/store_student_option_entity.dart';
import '../repositories/store_sale_repository.dart';

class GetStoreStudents {
  const GetStoreStudents(this._repository);

  final StoreSaleRepository _repository;

  Future<List<StoreStudentOptionEntity>> call() {
    return _repository.getStudents();
  }
}

class GetStoreSales {
  const GetStoreSales(this._repository);

  final StoreSaleRepository _repository;

  Future<List<StoreSaleEntity>> call() {
    return _repository.getSales();
  }
}

class SaveStoreSale {
  const SaveStoreSale(this._repository);

  final StoreSaleRepository _repository;

  Future<void> call(StoreSaleEntity sale) {
    if (sale.studentId.trim().isEmpty) {
      throw ArgumentError('Student is required.');
    }
    if (sale.itemId.trim().isEmpty) {
      throw ArgumentError('Item is required.');
    }
    if (sale.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }
    if (sale.unitSalePrice < 0) {
      throw ArgumentError('Sale price cannot be negative.');
    }
    if (sale.discount < 0 || sale.discount > sale.grossAmount) {
      throw ArgumentError('Discount is invalid.');
    }
    if (sale.paidAmount < 0 ||
        sale.paidAmount > sale.netAmount) {
      throw ArgumentError('Paid amount is invalid.');
    }
    return _repository.saveSale(sale);
  }
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_sale_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_sale_entity.dart';

sealed class StoreSaleEvent extends Equatable {
  const StoreSaleEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStoreSales extends StoreSaleEvent {
  const LoadStoreSales();
}

class SaveStoreSaleRequested extends StoreSaleEvent {
  const SaveStoreSaleRequested(this.sale);

  final StoreSaleEntity sale;

  @override
  List<Object?> get props => [sale];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_sale_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';

sealed class StoreSaleState extends Equatable {
  const StoreSaleState();

  @override
  List<Object?> get props => const [];
}

class StoreSaleInitial extends StoreSaleState {
  const StoreSaleInitial();
}

class StoreSaleLoading extends StoreSaleState {
  const StoreSaleLoading();
}

class StoreSaleLoaded extends StoreSaleState {
  const StoreSaleLoaded({
    required this.students,
    required this.items,
    required this.sales,
    this.message,
  });

  final List<StoreStudentOptionEntity> students;
  final List<StoreItemEntity> items;
  final List<StoreSaleEntity> sales;
  final String? message;

  double get totalSales => sales.fold<double>(
        0,
        (sum, sale) => sum + sale.netAmount,
      );

  double get totalReceived => sales.fold<double>(
        0,
        (sum, sale) => sum + sale.paidAmount,
      );

  double get totalOutstanding => sales.fold<double>(
        0,
        (sum, sale) => sum + sale.outstandingAmount,
      );

  double get totalProfit => sales.fold<double>(
        0,
        (sum, sale) => sum + sale.profitAmount,
      );

  @override
  List<Object?> get props => [
        students,
        items,
        sales,
        message,
      ];
}

class StoreSaleFailure extends StoreSaleState {
  const StoreSaleFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_sale_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../../domain/usecases/manage_store_items.dart';
import '../../domain/usecases/manage_store_sales.dart';
import 'store_sale_event.dart';
import 'store_sale_state.dart';

class StoreSaleBloc
    extends Bloc<StoreSaleEvent, StoreSaleState> {
  StoreSaleBloc({
    required GetStoreStudents getStudents,
    required GetStoreItems getItems,
    required GetStoreSales getSales,
    required SaveStoreSale saveSale,
  })  : _getStudents = getStudents,
        _getItems = getItems,
        _getSales = getSales,
        _saveSale = saveSale,
        super(const StoreSaleInitial()) {
    on<LoadStoreSales>(_load);
    on<SaveStoreSaleRequested>(_save);
  }

  final GetStoreStudents _getStudents;
  final GetStoreItems _getItems;
  final GetStoreSales _getSales;
  final SaveStoreSale _saveSale;

  Future<void> _load(
    LoadStoreSales event,
    Emitter<StoreSaleState> emit,
  ) async {
    emit(const StoreSaleLoading());
    await _reload(emit);
  }

  Future<void> _save(
    SaveStoreSaleRequested event,
    Emitter<StoreSaleState> emit,
  ) async {
    try {
      await _saveSale(event.sale);
      await _reload(
        emit,
        message: 'Student sale saved and stock updated.',
      );
    } catch (error) {
      emit(StoreSaleFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StoreSaleState> emit, {
    String? message,
  }) async {
    try {
      final values = await Future.wait<Object>([
        _getStudents(),
        _getItems(),
        _getSales(),
      ]);

      emit(
        StoreSaleLoaded(
          students:
              values[0] as List<StoreStudentOptionEntity>,
          items: values[1] as List<StoreItemEntity>,
          sales: values[2] as List<StoreSaleEntity>,
          message: message,
        ),
      );
    } catch (error) {
      emit(StoreSaleFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/school_store/presentation/pages/store_sales_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_item_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_option_entity.dart';
import '../bloc/store_sale_bloc.dart';
import '../bloc/store_sale_event.dart';
import '../bloc/store_sale_state.dart';

class StoreSalesPage extends StatelessWidget {
  const StoreSalesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StoreSaleBloc>()..add(const LoadStoreSales()),
      child: const _StoreSalesView(),
    );
  }
}

class _StoreSalesView extends StatelessWidget {
  const _StoreSalesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Sales'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StoreSaleBloc, StoreSaleState>(
        listener: (context, state) {
          if (state is StoreSaleLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is StoreSaleInitial ||
              state is StoreSaleLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is StoreSaleFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StoreSaleLoaded;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text(
                      'Sales Rs. ${data.totalSales.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Received Rs. ${data.totalReceived.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Credit Rs. ${data.totalOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Profit Rs. ${data.totalProfit.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: data.students.isEmpty ||
                            data.items
                                .where(
                                  (item) =>
                                      item.currentStock > 0 &&
                                      item.isActive,
                                )
                                .isEmpty
                        ? null
                        : () => _showSaleDialog(
                              context,
                              data,
                            ),
                    icon: const Icon(Icons.point_of_sale),
                    label: const Text('New Student Sale'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Student Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ..._studentLedgers(data.sales).entries.map(
                    (entry) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.school_outlined),
                        ),
                        title: Text(entry.value.name),
                        subtitle: Text(
                          entry.value.admissionNo.isEmpty
                              ? 'Student Ledger'
                              : entry.value.admissionNo,
                        ),
                        trailing: Text(
                          'Due Rs. ${entry.value.outstanding.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Sales History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (data.sales.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No student sales found.'),
                  ),
                ),
              ...data.sales.map(
                (sale) => Card(
                  child: ListTile(
                    title: Text(sale.itemName),
                    subtitle: Text(
                      '${sale.studentName} - '
                      '${sale.admissionNo} - '
                      'Qty ${sale.quantity} - '
                      '${sale.paymentStatus.name}',
                    ),
                    trailing: Text(
                      'Due Rs. ${sale.outstandingAmount.toStringAsFixed(0)}',
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

  static Map<String, _StudentLedger> _studentLedgers(
    List<StoreSaleEntity> sales,
  ) {
    final values = <String, _StudentLedger>{};

    for (final sale in sales) {
      if (sale.outstandingAmount <= 0) continue;

      final existing = values[sale.studentId];

      values[sale.studentId] = _StudentLedger(
        name: sale.studentName,
        admissionNo: sale.admissionNo,
        outstanding:
            (existing?.outstanding ?? 0) +
            sale.outstandingAmount,
      );
    }

    return values;
  }

  static Future<void> _showSaleDialog(
    BuildContext context,
    StoreSaleLoaded data,
  ) async {
    var student = data.students.first;
    final availableItems = data.items
        .where(
          (item) => item.currentStock > 0 && item.isActive,
        )
        .toList();
    var item = availableItems.first;

    final quantityController =
        TextEditingController(text: '1');
    final priceController = TextEditingController(
      text: item.salePrice.toString(),
    );
    final discountController =
        TextEditingController(text: '0');
    final paidController = TextEditingController(text: '0');

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Student Sale'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField<
                      StoreStudentOptionEntity>(
                    initialValue: student,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                    ),
                    items: data.students
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(
                          () => student = value,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StoreItemEntity>(
                    initialValue: item,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                    ),
                    items: availableItems
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              '${value.name} - Stock ${value.currentStock}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          item = value;
                          priceController.text =
                              value.salePrice.toString();
                        });
                      }
                    },
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
                      labelText: 'Unit Sale Price',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Discount',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: paidController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Paid Amount',
                      helperText:
                          'Enter 0 for full credit sale.',
                    ),
                  ),
                ],
              ),
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
              child: const Text('Save Sale'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StoreSaleBloc>().add(
            SaveStoreSaleRequested(
              StoreSaleEntity(
                id: 'store_sale_${now.microsecondsSinceEpoch}',
                studentId: student.id,
                studentName: student.name,
                admissionNo: student.admissionNo,
                classId: student.classId,
                sectionId: student.sectionId,
                itemId: item.id,
                itemName: item.name,
                quantity:
                    int.tryParse(quantityController.text) ?? 0,
                unitSalePrice:
                    double.tryParse(priceController.text) ?? 0,
                unitPurchasePrice: item.purchasePrice,
                discount:
                    double.tryParse(discountController.text) ?? 0,
                paidAmount:
                    double.tryParse(paidController.text) ?? 0,
                saleDate: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
          );
    }

    quantityController.dispose();
    priceController.dispose();
    discountController.dispose();
    paidController.dispose();
  }
}

class _StudentLedger {
  const _StudentLedger({
    required this.name,
    required this.admissionNo,
    required this.outstanding,
  });

  final String name;
  final String admissionNo;
  final double outstanding;
}
'@

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/school_store/data/datasources/store_sale_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_sale_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_sale_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_sales.dart';
import '../../features/school_store/presentation/bloc/store_sale_bloc.dart';
"@

if (-not $slText.Contains("store_sale_remote_datasource.dart")) {
  InsertBefore `
    $slFile `
    "import '../../features/school_store/data/datasources/store_purchase_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<StoreSaleRemoteDataSource>(
    () => StoreSaleRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<StoreSaleRepository>(
    () => StoreSaleRepositoryImpl(
      sl<StoreSaleRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetStoreStudents>(
    () => GetStoreStudents(
      sl<StoreSaleRepository>(),
    ),
  );
  sl.registerLazySingleton<GetStoreSales>(
    () => GetStoreSales(
      sl<StoreSaleRepository>(),
    ),
  );
  sl.registerLazySingleton<SaveStoreSale>(
    () => SaveStoreSale(
      sl<StoreSaleRepository>(),
    ),
  );
  sl.registerFactory<StoreSaleBloc>(
    () => StoreSaleBloc(
      getStudents: sl<GetStoreStudents>(),
      getItems: sl<GetStoreItems>(),
      getSales: sl<GetStoreSales>(),
      saveSale: sl<SaveStoreSale>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<StoreSaleRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<StorePurchaseRemoteDataSource>(' `
    $registrations
}

$dashboardFile = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'
$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  "import 'store_sales_page.dart';"
)) {
  $anchor = "import 'store_purchases_page.dart';"

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD IMPORT ANCHOR ERROR.'
  }

  BackupFile $dashboardFile
  WriteUtf8 $dashboardFile (
    $dashboardText.Replace(
      $anchor,
      "$anchor`nimport 'store_sales_page.dart';"
    )
  )
}

$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  'const StoreSalesPage()'
)) {
  $anchor = @"
            const SizedBox(height: 18),
            ...d.items.map(
"@

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD SALES BUTTON ANCHOR ERROR.'
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
                          const StoreSalesPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Student Sales'),
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
Write-Host 'School Store Phase 3 Student Sales installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
