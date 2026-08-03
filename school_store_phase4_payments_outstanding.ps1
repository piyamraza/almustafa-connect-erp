[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Get-Location).Path
$utf8 = New-Object System.Text.UTF8Encoding($false)
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = Join-Path (Split-Path $root -Parent) "almustafa-connect-erp_backups\school_store_phase4_$stamp"

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

  if ($text.Contains($InsertText.Trim())) {
    return
  }

  $index = $text.IndexOf(
    $Anchor,
    [StringComparison]::Ordinal
  )

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
  'lib/features/school_store/domain/entities/store_sale_entity.dart',
  'lib/features/school_store/data/models/store_sale_model.dart',
  'lib/features/school_store/domain/entities/store_purchase_entity.dart',
  'lib/features/school_store/data/models/store_purchase_model.dart',
  'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart',
  'lib/core/constants/firestore_paths.dart',
  'lib/core/di/service_locator.dart'
)

foreach ($path in $required) {
  if (-not (Test-Path (FullPath $path))) {
    throw "REQUIRED FILE ERROR: $path"
  }
}

if (Test-Path (FullPath 'lib/features/school_store/domain/entities/store_student_payment_entity.dart')) {
  throw 'EXISTING FILE ERROR: School Store Phase 4 appears already installed.'
}

New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach ($path in $required) { BackupFile $path }

WriteUtf8 'lib/features/school_store/domain/entities/store_student_payment_entity.dart' @'
import 'package:equatable/equatable.dart';

class StoreStudentPaymentEntity extends Equatable {
  const StoreStudentPaymentEntity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    this.receiptNumber = '',
    this.notes = '',
  });

  final String id;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String receiptNumber;
  final String notes;

  @override
  List<Object?> get props => [
        id,
        studentId,
        studentName,
        admissionNo,
        amount,
        paymentDate,
        createdAt,
        receiptNumber,
        notes,
      ];
}
'@

WriteUtf8 'lib/features/school_store/domain/entities/store_supplier_payment_entity.dart' @'
import 'package:equatable/equatable.dart';

class StoreSupplierPaymentEntity extends Equatable {
  const StoreSupplierPaymentEntity({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentDate,
    required this.createdAt,
    this.referenceNumber = '',
    this.notes = '',
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final double amount;
  final DateTime paymentDate;
  final DateTime createdAt;
  final String referenceNumber;
  final String notes;

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        amount,
        paymentDate,
        createdAt,
        referenceNumber,
        notes,
      ];
}
'@

WriteUtf8 'lib/features/school_store/data/models/store_student_payment_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_student_payment_entity.dart';

class StoreStudentPaymentModel extends StoreStudentPaymentEntity {
  const StoreStudentPaymentModel({
    required super.id,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.amount,
    required super.paymentDate,
    required super.createdAt,
    super.receiptNumber,
    super.notes,
  });

  factory StoreStudentPaymentModel.fromEntity(
    StoreStudentPaymentEntity entity,
  ) {
    return StoreStudentPaymentModel(
      id: entity.id,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      createdAt: entity.createdAt,
      receiptNumber: entity.receiptNumber,
      notes: entity.notes,
    );
  }

  factory StoreStudentPaymentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreStudentPaymentModel(
      id: map['id'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: date(map['paymentDate']),
      createdAt: date(map['createdAt']),
      receiptNumber: map['receiptNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'studentId': studentId,
        'studentName': studentName,
        'admissionNo': admissionNo,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'receiptNumber': receiptNumber,
        'notes': notes,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/school_store/data/models/store_supplier_payment_model.dart' @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/store_supplier_payment_entity.dart';

class StoreSupplierPaymentModel extends StoreSupplierPaymentEntity {
  const StoreSupplierPaymentModel({
    required super.id,
    required super.supplierId,
    required super.supplierName,
    required super.amount,
    required super.paymentDate,
    required super.createdAt,
    super.referenceNumber,
    super.notes,
  });

  factory StoreSupplierPaymentModel.fromEntity(
    StoreSupplierPaymentEntity entity,
  ) {
    return StoreSupplierPaymentModel(
      id: entity.id,
      supplierId: entity.supplierId,
      supplierName: entity.supplierName,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      createdAt: entity.createdAt,
      referenceNumber: entity.referenceNumber,
      notes: entity.notes,
    );
  }

  factory StoreSupplierPaymentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return StoreSupplierPaymentModel(
      id: map['id'] as String? ?? '',
      supplierId: map['supplierId'] as String? ?? '',
      supplierName: map['supplierName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paymentDate: date(map['paymentDate']),
      createdAt: date(map['createdAt']),
      referenceNumber: map['referenceNumber'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'amount': amount,
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'referenceNumber': referenceNumber,
        'notes': notes,
        'schemaVersion': 1,
      };
}
'@

WriteUtf8 'lib/features/school_store/domain/repositories/store_payment_repository.dart' @'
import '../entities/store_purchase_entity.dart';
import '../entities/store_sale_entity.dart';
import '../entities/store_student_payment_entity.dart';
import '../entities/store_supplier_payment_entity.dart';

abstract class StorePaymentRepository {
  Future<List<StoreSaleEntity>> getSales();
  Future<List<StorePurchaseEntity>> getPurchases();

  Future<List<StoreStudentPaymentEntity>>
      getStudentPayments();

  Future<List<StoreSupplierPaymentEntity>>
      getSupplierPayments();

  Future<void> receiveStudentPayment(
    StoreStudentPaymentEntity payment,
  );

  Future<void> paySupplier(
    StoreSupplierPaymentEntity payment,
  );
}
'@

WriteUtf8 'lib/features/school_store/data/datasources/store_payment_remote_datasource.dart' @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../models/store_purchase_model.dart';
import '../models/store_sale_model.dart';
import '../models/store_student_payment_model.dart';
import '../models/store_supplier_payment_model.dart';

abstract class StorePaymentRemoteDataSource {
  Future<List<StoreSaleEntity>> getSales();
  Future<List<StorePurchaseEntity>> getPurchases();

  Future<List<StoreStudentPaymentEntity>>
      getStudentPayments();

  Future<List<StoreSupplierPaymentEntity>>
      getSupplierPayments();

  Future<void> receiveStudentPayment(
    StoreStudentPaymentEntity payment,
  );

  Future<void> paySupplier(
    StoreSupplierPaymentEntity payment,
  );
}

class StorePaymentRemoteDataSourceImpl
    implements StorePaymentRemoteDataSource {
  const StorePaymentRemoteDataSourceImpl(this._service);

  final FirebaseFirestoreService _service;

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

    values.sort((a, b) => a.saleDate.compareTo(b.saleDate));
    return values;
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
      (a, b) => a.purchaseDate.compareTo(b.purchaseDate),
    );

    return values;
  }

  @override
  Future<List<StoreStudentPaymentEntity>>
      getStudentPayments() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeStudentPayments)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => StoreStudentPaymentModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort(
      (a, b) => b.paymentDate.compareTo(a.paymentDate),
    );

    return values;
  }

  @override
  Future<List<StoreSupplierPaymentEntity>>
      getSupplierPayments() async {
    final snapshot = await _service
        .collection(FirestorePaths.storeSupplierPayments)
        .get();

    final values = snapshot.docs
        .map(
          (doc) => StoreSupplierPaymentModel.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    values.sort(
      (a, b) => b.paymentDate.compareTo(a.paymentDate),
    );

    return values;
  }

  @override
  Future<void> receiveStudentPayment(
    StoreStudentPaymentEntity payment,
  ) async {
    final sales = (await getSales())
        .where(
          (sale) =>
              sale.studentId == payment.studentId &&
              sale.outstandingAmount > 0,
        )
        .toList();

    final due = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.outstandingAmount,
    );

    if (payment.amount <= 0 || payment.amount > due) {
      throw ArgumentError(
        'Payment must be above zero and not exceed outstanding.',
      );
    }

    var balance = payment.amount;

    for (final sale in sales) {
      if (balance <= 0) break;

      final allocation = balance >= sale.outstandingAmount
          ? sale.outstandingAmount
          : balance;

      final updated = StoreSaleEntity(
        id: sale.id,
        studentId: sale.studentId,
        studentName: sale.studentName,
        admissionNo: sale.admissionNo,
        classId: sale.classId,
        sectionId: sale.sectionId,
        itemId: sale.itemId,
        itemName: sale.itemName,
        quantity: sale.quantity,
        unitSalePrice: sale.unitSalePrice,
        unitPurchasePrice: sale.unitPurchasePrice,
        discount: sale.discount,
        paidAmount: sale.paidAmount + allocation,
        saleDate: sale.saleDate,
        createdAt: sale.createdAt,
        updatedAt: DateTime.now(),
        notes: sale.notes,
      );

      await _service
          .collection(FirestorePaths.storeSales)
          .doc(sale.id)
          .set(StoreSaleModel.fromEntity(updated).toMap());

      balance -= allocation;
    }

    await _service
        .collection(FirestorePaths.storeStudentPayments)
        .doc(payment.id)
        .set(
          StoreStudentPaymentModel.fromEntity(
            payment,
          ).toMap(),
        );
  }

  @override
  Future<void> paySupplier(
    StoreSupplierPaymentEntity payment,
  ) async {
    final purchases = (await getPurchases())
        .where(
          (purchase) =>
              purchase.supplierId == payment.supplierId &&
              purchase.outstandingAmount > 0,
        )
        .toList();

    final due = purchases.fold<double>(
      0,
      (sum, purchase) =>
          sum + purchase.outstandingAmount,
    );

    if (payment.amount <= 0 || payment.amount > due) {
      throw ArgumentError(
        'Payment must be above zero and not exceed supplier due.',
      );
    }

    var balance = payment.amount;

    for (final purchase in purchases) {
      if (balance <= 0) break;

      final allocation =
          balance >= purchase.outstandingAmount
              ? purchase.outstandingAmount
              : balance;

      final updated = StorePurchaseEntity(
        id: purchase.id,
        supplierId: purchase.supplierId,
        supplierName: purchase.supplierName,
        itemId: purchase.itemId,
        itemName: purchase.itemName,
        invoiceNumber: purchase.invoiceNumber,
        quantity: purchase.quantity,
        unitPrice: purchase.unitPrice,
        paidAmount: purchase.paidAmount + allocation,
        purchaseDate: purchase.purchaseDate,
        createdAt: purchase.createdAt,
        updatedAt: DateTime.now(),
      );

      await _service
          .collection(FirestorePaths.storePurchases)
          .doc(purchase.id)
          .set(
            StorePurchaseModel.fromEntity(updated).toMap(),
          );

      balance -= allocation;
    }

    await _service
        .collection(FirestorePaths.storeSupplierPayments)
        .doc(payment.id)
        .set(
          StoreSupplierPaymentModel.fromEntity(
            payment,
          ).toMap(),
        );
  }
}
'@

WriteUtf8 'lib/features/school_store/data/repositories/store_payment_repository_impl.dart' @'
import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../../domain/repositories/store_payment_repository.dart';
import '../datasources/store_payment_remote_datasource.dart';

class StorePaymentRepositoryImpl
    implements StorePaymentRepository {
  const StorePaymentRepositoryImpl(this._source);

  final StorePaymentRemoteDataSource _source;

  @override
  Future<List<StoreSaleEntity>> getSales() {
    return _source.getSales();
  }

  @override
  Future<List<StorePurchaseEntity>> getPurchases() {
    return _source.getPurchases();
  }

  @override
  Future<List<StoreStudentPaymentEntity>>
      getStudentPayments() {
    return _source.getStudentPayments();
  }

  @override
  Future<List<StoreSupplierPaymentEntity>>
      getSupplierPayments() {
    return _source.getSupplierPayments();
  }

  @override
  Future<void> receiveStudentPayment(
    StoreStudentPaymentEntity payment,
  ) {
    return _source.receiveStudentPayment(payment);
  }

  @override
  Future<void> paySupplier(
    StoreSupplierPaymentEntity payment,
  ) {
    return _source.paySupplier(payment);
  }
}
'@

WriteUtf8 'lib/features/school_store/domain/usecases/manage_store_payments.dart' @'
import '../entities/store_purchase_entity.dart';
import '../entities/store_sale_entity.dart';
import '../entities/store_student_payment_entity.dart';
import '../entities/store_supplier_payment_entity.dart';
import '../repositories/store_payment_repository.dart';

class StorePaymentData {
  const StorePaymentData({
    required this.sales,
    required this.purchases,
    required this.studentPayments,
    required this.supplierPayments,
  });

  final List<StoreSaleEntity> sales;
  final List<StorePurchaseEntity> purchases;
  final List<StoreStudentPaymentEntity> studentPayments;
  final List<StoreSupplierPaymentEntity> supplierPayments;
}

class GetStorePaymentData {
  const GetStorePaymentData(this._repository);

  final StorePaymentRepository _repository;

  Future<StorePaymentData> call() async {
    final values = await Future.wait<Object>([
      _repository.getSales(),
      _repository.getPurchases(),
      _repository.getStudentPayments(),
      _repository.getSupplierPayments(),
    ]);

    return StorePaymentData(
      sales: values[0] as List<StoreSaleEntity>,
      purchases: values[1] as List<StorePurchaseEntity>,
      studentPayments:
          values[2] as List<StoreStudentPaymentEntity>,
      supplierPayments:
          values[3] as List<StoreSupplierPaymentEntity>,
    );
  }
}

class ReceiveStoreStudentPayment {
  const ReceiveStoreStudentPayment(this._repository);

  final StorePaymentRepository _repository;

  Future<void> call(StoreStudentPaymentEntity payment) {
    return _repository.receiveStudentPayment(payment);
  }
}

class PayStoreSupplier {
  const PayStoreSupplier(this._repository);

  final StorePaymentRepository _repository;

  Future<void> call(StoreSupplierPaymentEntity payment) {
    return _repository.paySupplier(payment);
  }
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_payment_event.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';

sealed class StorePaymentEvent extends Equatable {
  const StorePaymentEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStorePayments extends StorePaymentEvent {
  const LoadStorePayments();
}

class ReceiveStudentPaymentRequested
    extends StorePaymentEvent {
  const ReceiveStudentPaymentRequested(this.payment);

  final StoreStudentPaymentEntity payment;

  @override
  List<Object?> get props => [payment];
}

class PaySupplierRequested extends StorePaymentEvent {
  const PaySupplierRequested(this.payment);

  final StoreSupplierPaymentEntity payment;

  @override
  List<Object?> get props => [payment];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_payment_state.dart' @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/store_purchase_entity.dart';
import '../../domain/entities/store_sale_entity.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';

sealed class StorePaymentState extends Equatable {
  const StorePaymentState();

  @override
  List<Object?> get props => const [];
}

class StorePaymentInitial extends StorePaymentState {
  const StorePaymentInitial();
}

class StorePaymentLoading extends StorePaymentState {
  const StorePaymentLoading();
}

class StorePaymentLoaded extends StorePaymentState {
  const StorePaymentLoaded({
    required this.sales,
    required this.purchases,
    required this.studentPayments,
    required this.supplierPayments,
    this.message,
  });

  final List<StoreSaleEntity> sales;
  final List<StorePurchaseEntity> purchases;
  final List<StoreStudentPaymentEntity> studentPayments;
  final List<StoreSupplierPaymentEntity> supplierPayments;
  final String? message;

  double get studentOutstanding => sales.fold<double>(
        0,
        (sum, sale) => sum + sale.outstandingAmount,
      );

  double get supplierOutstanding =>
      purchases.fold<double>(
        0,
        (sum, purchase) =>
            sum + purchase.outstandingAmount,
      );

  double get studentPaymentsReceived =>
      studentPayments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );

  double get supplierPaymentsMade =>
      supplierPayments.fold<double>(
        0,
        (sum, payment) => sum + payment.amount,
      );

  @override
  List<Object?> get props => [
        sales,
        purchases,
        studentPayments,
        supplierPayments,
        message,
      ];
}

class StorePaymentFailure extends StorePaymentState {
  const StorePaymentFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
'@

WriteUtf8 'lib/features/school_store/presentation/bloc/store_payment_bloc.dart' @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_store_payments.dart';
import 'store_payment_event.dart';
import 'store_payment_state.dart';

class StorePaymentBloc
    extends Bloc<StorePaymentEvent, StorePaymentState> {
  StorePaymentBloc({
    required GetStorePaymentData getData,
    required ReceiveStoreStudentPayment receiveStudentPayment,
    required PayStoreSupplier paySupplier,
  })  : _getData = getData,
        _receiveStudentPayment = receiveStudentPayment,
        _paySupplier = paySupplier,
        super(const StorePaymentInitial()) {
    on<LoadStorePayments>(_load);
    on<ReceiveStudentPaymentRequested>(_receive);
    on<PaySupplierRequested>(_pay);
  }

  final GetStorePaymentData _getData;
  final ReceiveStoreStudentPayment _receiveStudentPayment;
  final PayStoreSupplier _paySupplier;

  Future<void> _load(
    LoadStorePayments event,
    Emitter<StorePaymentState> emit,
  ) async {
    emit(const StorePaymentLoading());
    await _reload(emit);
  }

  Future<void> _receive(
    ReceiveStudentPaymentRequested event,
    Emitter<StorePaymentState> emit,
  ) async {
    try {
      await _receiveStudentPayment(event.payment);
      await _reload(
        emit,
        message: 'Student payment received.',
      );
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  Future<void> _pay(
    PaySupplierRequested event,
    Emitter<StorePaymentState> emit,
  ) async {
    try {
      await _paySupplier(event.payment);
      await _reload(
        emit,
        message: 'Supplier payment saved.',
      );
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StorePaymentState> emit, {
    String? message,
  }) async {
    try {
      final data = await _getData();

      emit(
        StorePaymentLoaded(
          sales: data.sales,
          purchases: data.purchases,
          studentPayments: data.studentPayments,
          supplierPayments: data.supplierPayments,
          message: message,
        ),
      );
    } catch (error) {
      emit(StorePaymentFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
'@

WriteUtf8 'lib/features/school_store/presentation/pages/store_payments_page.dart' @'
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/dashboard_navigation_button.dart';
import '../../domain/entities/store_student_payment_entity.dart';
import '../../domain/entities/store_supplier_payment_entity.dart';
import '../bloc/store_payment_bloc.dart';
import '../bloc/store_payment_event.dart';
import '../bloc/store_payment_state.dart';

class StorePaymentsPage extends StatelessWidget {
  const StorePaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StorePaymentBloc>()..add(const LoadStorePayments()),
      child: const _StorePaymentsView(),
    );
  }
}

class _StorePaymentsView extends StatelessWidget {
  const _StorePaymentsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Outstanding'),
        actions: const [DashboardNavigationButton()],
      ),
      body: BlocConsumer<StorePaymentBloc, StorePaymentState>(
        listener: (context, state) {
          if (state is StorePaymentLoaded &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state is StorePaymentInitial ||
              state is StorePaymentLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is StorePaymentFailure) {
            return Center(child: Text(state.message));
          }

          final data = state as StorePaymentLoaded;
          final studentDue = _studentDue(data);
          final supplierDue = _supplierDue(data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  Chip(
                    label: Text(
                      'Student Due Rs. ${data.studentOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  Chip(
                    label: Text(
                      'Supplier Due Rs. ${data.supplierOutstanding.toStringAsFixed(0)}',
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: studentDue.isEmpty
                        ? null
                        : () => _receiveStudent(
                              context,
                              studentDue,
                            ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Receive Student Payment'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: supplierDue.isEmpty
                        ? null
                        : () => _paySupplier(
                              context,
                              supplierDue,
                            ),
                    icon: const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Pay Supplier'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Student Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...studentDue.values.map(
                (value) => Card(
                  child: ListTile(
                    title: Text(value.name),
                    subtitle: Text(value.admissionNo),
                    trailing: Text(
                      'Rs. ${value.amount.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Supplier Outstanding',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...supplierDue.values.map(
                (value) => Card(
                  child: ListTile(
                    title: Text(value.name),
                    trailing: Text(
                      'Rs. ${value.amount.toStringAsFixed(0)}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Recent Student Payments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.studentPayments.take(20).map(
                    (payment) => Card(
                      child: ListTile(
                        title: Text(payment.studentName),
                        subtitle: Text(payment.receiptNumber),
                        trailing: Text(
                          'Rs. ${payment.amount.toStringAsFixed(0)}',
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Recent Supplier Payments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ...data.supplierPayments.take(20).map(
                    (payment) => Card(
                      child: ListTile(
                        title: Text(payment.supplierName),
                        subtitle: Text(payment.referenceNumber),
                        trailing: Text(
                          'Rs. ${payment.amount.toStringAsFixed(0)}',
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

  static Map<String, _DueParty> _studentDue(
    StorePaymentLoaded data,
  ) {
    final values = <String, _DueParty>{};

    for (final sale in data.sales) {
      if (sale.outstandingAmount <= 0) continue;

      final existing = values[sale.studentId];

      values[sale.studentId] = _DueParty(
        id: sale.studentId,
        name: sale.studentName,
        admissionNo: sale.admissionNo,
        amount:
            (existing?.amount ?? 0) +
            sale.outstandingAmount,
      );
    }

    return values;
  }

  static Map<String, _DueParty> _supplierDue(
    StorePaymentLoaded data,
  ) {
    final values = <String, _DueParty>{};

    for (final purchase in data.purchases) {
      if (purchase.outstandingAmount <= 0) continue;

      final existing = values[purchase.supplierId];

      values[purchase.supplierId] = _DueParty(
        id: purchase.supplierId,
        name: purchase.supplierName,
        amount:
            (existing?.amount ?? 0) +
            purchase.outstandingAmount,
      );
    }

    return values;
  }

  static Future<void> _receiveStudent(
    BuildContext context,
    Map<String, _DueParty> values,
  ) async {
    var selected = values.values.first;
    final amountController = TextEditingController();
    final receiptController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Receive Student Payment'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_DueParty>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                  ),
                  items: values.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${value.name} - Due Rs. ${value.amount.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selected = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Received',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: receiptController,
                  decoration: const InputDecoration(
                    labelText: 'Receipt Number',
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
              child: const Text('Receive'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePaymentBloc>().add(
            ReceiveStudentPaymentRequested(
              StoreStudentPaymentEntity(
                id: 'student_payment_${now.microsecondsSinceEpoch}',
                studentId: selected.id,
                studentName: selected.name,
                admissionNo: selected.admissionNo,
                amount:
                    double.tryParse(amountController.text) ?? 0,
                paymentDate: now,
                createdAt: now,
                receiptNumber:
                    receiptController.text.trim(),
              ),
            ),
          );
    }

    amountController.dispose();
    receiptController.dispose();
  }

  static Future<void> _paySupplier(
    BuildContext context,
    Map<String, _DueParty> values,
  ) async {
    var selected = values.values.first;
    final amountController = TextEditingController();
    final referenceController = TextEditingController();

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pay Supplier'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_DueParty>(
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Supplier',
                  ),
                  items: values.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            '${value.name} - Due Rs. ${value.amount.toStringAsFixed(0)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selected = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount Paid',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number',
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
              child: const Text('Pay'),
            ),
          ],
        ),
      ),
    );

    if (save == true && context.mounted) {
      final now = DateTime.now();

      context.read<StorePaymentBloc>().add(
            PaySupplierRequested(
              StoreSupplierPaymentEntity(
                id: 'supplier_payment_${now.microsecondsSinceEpoch}',
                supplierId: selected.id,
                supplierName: selected.name,
                amount:
                    double.tryParse(amountController.text) ?? 0,
                paymentDate: now,
                createdAt: now,
                referenceNumber:
                    referenceController.text.trim(),
              ),
            ),
          );
    }

    amountController.dispose();
    referenceController.dispose();
  }
}

class _DueParty {
  const _DueParty({
    required this.id,
    required this.name,
    required this.amount,
    this.admissionNo = '',
  });

  final String id;
  final String name;
  final String admissionNo;
  final double amount;
}
'@

$pathsFile = 'lib/core/constants/firestore_paths.dart'
$pathsText = ReadUtf8 $pathsFile

if (-not $pathsText.Contains(
  'static const String storeStudentPayments'
)) {
  $anchor = "  static const String storePayments = 'store_payments';"

  if (-not $pathsText.Contains($anchor)) {
    throw 'FIRESTORE PATH ANCHOR ERROR.'
  }

  $replacement = @"
$anchor
  static const String storeStudentPayments =
      'store_student_payments';
  static const String storeSupplierPayments =
      'store_supplier_payments';
"@

  BackupFile $pathsFile
  WriteUtf8 $pathsFile (
    $pathsText.Replace($anchor,$replacement)
  )
}

$slFile = 'lib/core/di/service_locator.dart'
$slText = ReadUtf8 $slFile

$imports = @"
import '../../features/school_store/data/datasources/store_payment_remote_datasource.dart';
import '../../features/school_store/data/repositories/store_payment_repository_impl.dart';
import '../../features/school_store/domain/repositories/store_payment_repository.dart';
import '../../features/school_store/domain/usecases/manage_store_payments.dart';
import '../../features/school_store/presentation/bloc/store_payment_bloc.dart';
"@

if (-not $slText.Contains(
  'store_payment_remote_datasource.dart'
)) {
  InsertBefore `
    $slFile `
    "import '../../features/school_store/data/datasources/store_sale_remote_datasource.dart';" `
    $imports
}

$registrations = @"
  sl.registerLazySingleton<StorePaymentRemoteDataSource>(
    () => StorePaymentRemoteDataSourceImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
  sl.registerLazySingleton<StorePaymentRepository>(
    () => StorePaymentRepositoryImpl(
      sl<StorePaymentRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton<GetStorePaymentData>(
    () => GetStorePaymentData(
      sl<StorePaymentRepository>(),
    ),
  );
  sl.registerLazySingleton<ReceiveStoreStudentPayment>(
    () => ReceiveStoreStudentPayment(
      sl<StorePaymentRepository>(),
    ),
  );
  sl.registerLazySingleton<PayStoreSupplier>(
    () => PayStoreSupplier(
      sl<StorePaymentRepository>(),
    ),
  );
  sl.registerFactory<StorePaymentBloc>(
    () => StorePaymentBloc(
      getData: sl<GetStorePaymentData>(),
      receiveStudentPayment:
          sl<ReceiveStoreStudentPayment>(),
      paySupplier: sl<PayStoreSupplier>(),
    ),
  );

"@

if (-not $slText.Contains(
  'sl.registerLazySingleton<StorePaymentRepository>'
)) {
  InsertBefore `
    $slFile `
    '  sl.registerLazySingleton<StoreSaleRemoteDataSource>(' `
    $registrations
}

$dashboardFile = 'lib/features/school_store/presentation/pages/school_store_dashboard_page.dart'
$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  "import 'store_payments_page.dart';"
)) {
  $anchor = "import 'store_sales_page.dart';"

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD IMPORT ANCHOR ERROR.'
  }

  BackupFile $dashboardFile
  WriteUtf8 $dashboardFile (
    $dashboardText.Replace(
      $anchor,
      "$anchor`nimport 'store_payments_page.dart';"
    )
  )
}

$dashboardText = ReadUtf8 $dashboardFile

if (-not $dashboardText.Contains(
  'const StorePaymentsPage()'
)) {
  $anchor = @"
            const SizedBox(height: 18),
            ...d.items.map(
"@

  if (-not $dashboardText.Contains($anchor)) {
    throw 'DASHBOARD PAYMENT BUTTON ANCHOR ERROR.'
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
                          const StorePaymentsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.payments_outlined),
                label: const Text(
                  'Payments & Outstanding',
                ),
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
  lib/core/constants/firestore_paths.dart `
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
Write-Host 'School Store Phase 4 Payments and Outstanding installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backup" -ForegroundColor Cyan
