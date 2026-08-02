[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$projectRoot = (Get-Location).Path
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
if (-not (Test-Path -LiteralPath $pubspecPath -PathType Leaf)) {
    throw 'Run this installer from the Almustafa Connect ERP project root (pubspec.yaml was not found).'
}

$pathsRelative = 'lib/core/constants/firestore_paths.dart'
$locatorRelative = 'lib/core/di/service_locator.dart'
$pathsPath = Join-Path $projectRoot $pathsRelative
$locatorPath = Join-Path $projectRoot $locatorRelative
foreach ($requiredPath in @($pathsPath, $locatorPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required integration file is missing: $requiredPath"
    }
}

$generatedFiles = [ordered]@{
'lib/features/fees/domain/entities/additional_charge_entity.dart' = @'
import 'package:equatable/equatable.dart';

enum AdditionalChargeCategory {
  paperMoney,
  trip,
  exam,
  annualFunction,
  sportsDay,
  diary,
  idCard,
  uniform,
  penalty,
  other,
}

enum AdditionalChargeScope {
  entireSchool,
  classWise,
  sectionWise,
  selectedStudents,
}

enum AdditionalChargeFrequency { oneTime, monthly, quarterly, annual, custom }

enum AdditionalChargeStatus { pending, generated, inactive }

class AdditionalChargeEntity extends Equatable {
  const AdditionalChargeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.customCategoryName,
    required this.academicSession,
    required this.amount,
    required this.scope,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.selectedStudentIds,
    required this.excludedStudentIds,
    required this.dueDate,
    required this.frequency,
    required this.mandatory,
    required this.refundable,
    required this.isActive,
    required this.generated,
    required this.generatedStudentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final AdditionalChargeCategory category;
  final String customCategoryName;
  final String academicSession;
  final double amount;
  final AdditionalChargeScope scope;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final List<String> selectedStudentIds;
  final List<String> excludedStudentIds;
  final DateTime dueDate;
  final AdditionalChargeFrequency frequency;
  final bool mandatory;
  final bool refundable;
  final bool isActive;
  final bool generated;
  final int generatedStudentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object> get props => [
    id,
    title,
    description,
    category,
    customCategoryName,
    academicSession,
    amount,
    scope,
    classId,
    className,
    sectionId,
    sectionName,
    selectedStudentIds,
    excludedStudentIds,
    dueDate,
    frequency,
    mandatory,
    refundable,
    isActive,
    generated,
    generatedStudentCount,
    createdAt,
    updatedAt,
  ];
}
'@
'lib/features/fees/domain/entities/student_additional_charge_due_entity.dart' = @'
import 'package:equatable/equatable.dart';

import 'additional_charge_entity.dart';

enum StudentAdditionalChargeStatus {
  unpaid,
  partiallyPaid,
  paid,
  waived,
  cancelled,
}

class StudentAdditionalChargeDueEntity extends Equatable {
  const StudentAdditionalChargeDueEntity({
    required this.id,
    required this.chargeId,
    required this.chargeTitle,
    required this.chargeCategory,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.academicSession,
    required this.amount,
    required this.discountAmount,
    required this.waivedAmount,
    required this.netPayable,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    required this.dueDate,
    required this.generatedAt,
    required this.updatedAt,
    required this.notes,
  });

  final String id;
  final String chargeId;
  final String chargeTitle;
  final AdditionalChargeCategory chargeCategory;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final String classId;
  final String className;
  final String sectionId;
  final String sectionName;
  final String academicSession;
  final double amount;
  final double discountAmount;
  final double waivedAmount;
  final double netPayable;
  final double paidAmount;
  final double outstandingAmount;
  final StudentAdditionalChargeStatus status;
  final DateTime dueDate;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final String notes;

  @override
  List<Object> get props => [
    id,
    chargeId,
    chargeTitle,
    chargeCategory,
    studentId,
    studentName,
    admissionNo,
    classId,
    className,
    sectionId,
    sectionName,
    academicSession,
    amount,
    discountAmount,
    waivedAmount,
    netPayable,
    paidAmount,
    outstandingAmount,
    status,
    dueDate,
    generatedAt,
    updatedAt,
    notes,
  ];
}
'@
'lib/features/fees/domain/repositories/additional_charge_repository.dart' = @'
import '../entities/additional_charge_entity.dart';

abstract class AdditionalChargeRepository {
  Future<List<AdditionalChargeEntity>> getCharges();

  Future<AdditionalChargeEntity?> getCharge(String id);

  Future<void> saveCharge(AdditionalChargeEntity charge);

  Future<void> updateCharge(AdditionalChargeEntity charge);

  Future<void> deleteCharge(String id);

  Future<String> generateId();
}
'@
'lib/features/fees/domain/repositories/student_additional_charge_due_repository.dart' = @'
import '../entities/student_additional_charge_due_entity.dart';

abstract class StudentAdditionalChargeDueRepository {
  Future<List<StudentAdditionalChargeDueEntity>> getStudentDues();

  Future<void> saveDue(StudentAdditionalChargeDueEntity due);

  Future<void> saveBatch(List<StudentAdditionalChargeDueEntity> dues);

  Future<void> updateDue(StudentAdditionalChargeDueEntity due);

  Future<void> deleteDue(String id);

  Future<String> generateId();
}
'@
'lib/features/fees/data/models/additional_charge_model.dart' = @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/additional_charge_entity.dart';

class AdditionalChargeModel extends AdditionalChargeEntity {
  const AdditionalChargeModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.customCategoryName,
    required super.academicSession,
    required super.amount,
    required super.scope,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.selectedStudentIds,
    required super.excludedStudentIds,
    required super.dueDate,
    required super.frequency,
    required super.mandatory,
    required super.refundable,
    required super.isActive,
    required super.generated,
    required super.generatedStudentCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdditionalChargeModel.fromEntity(AdditionalChargeEntity entity) {
    return AdditionalChargeModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      customCategoryName: entity.customCategoryName,
      academicSession: entity.academicSession,
      amount: entity.amount,
      scope: entity.scope,
      classId: entity.classId,
      className: entity.className,
      sectionId: entity.sectionId,
      sectionName: entity.sectionName,
      selectedStudentIds: List<String>.unmodifiable(entity.selectedStudentIds),
      excludedStudentIds: List<String>.unmodifiable(entity.excludedStudentIds),
      dueDate: entity.dueDate,
      frequency: entity.frequency,
      mandatory: entity.mandatory,
      refundable: entity.refundable,
      isActive: entity.isActive,
      generated: entity.generated,
      generatedStudentCount: entity.generatedStudentCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AdditionalChargeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return AdditionalChargeModel(
      id: document.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: _enumValue(
        AdditionalChargeCategory.values,
        data['category'],
        AdditionalChargeCategory.other,
      ),
      customCategoryName: data['customCategoryName'] as String? ?? '',
      academicSession: data['academicSession'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      scope: _enumValue(
        AdditionalChargeScope.values,
        data['scope'],
        AdditionalChargeScope.entireSchool,
      ),
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      sectionId: data['sectionId'] as String? ?? '',
      sectionName: data['sectionName'] as String? ?? '',
      selectedStudentIds: List<String>.unmodifiable(
        (data['selectedStudentIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      ),
      excludedStudentIds: List<String>.unmodifiable(
        (data['excludedStudentIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      ),
      dueDate: _date(data['dueDate']),
      frequency: _enumValue(
        AdditionalChargeFrequency.values,
        data['frequency'],
        AdditionalChargeFrequency.oneTime,
      ),
      mandatory: data['mandatory'] as bool? ?? false,
      refundable: data['refundable'] as bool? ?? false,
      isActive: data['isActive'] as bool? ?? true,
      generated: data['generated'] as bool? ?? false,
      generatedStudentCount:
          (data['generatedStudentCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'description': description,
    'category': category.name,
    'customCategoryName': customCategoryName,
    'academicSession': academicSession,
    'amount': amount,
    'scope': scope.name,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'selectedStudentIds': selectedStudentIds,
    'excludedStudentIds': excludedStudentIds,
    'dueDate': Timestamp.fromDate(dueDate),
    'frequency': frequency.name,
    'mandatory': mandatory,
    'refundable': refundable,
    'isActive': isActive,
    'generated': generated,
    'generatedStudentCount': generatedStudentCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  AdditionalChargeModel copyWith({
    String? id,
    String? title,
    String? description,
    AdditionalChargeCategory? category,
    String? customCategoryName,
    String? academicSession,
    double? amount,
    AdditionalChargeScope? scope,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    List<String>? selectedStudentIds,
    List<String>? excludedStudentIds,
    DateTime? dueDate,
    AdditionalChargeFrequency? frequency,
    bool? mandatory,
    bool? refundable,
    bool? isActive,
    bool? generated,
    int? generatedStudentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdditionalChargeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      academicSession: academicSession ?? this.academicSession,
      amount: amount ?? this.amount,
      scope: scope ?? this.scope,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      selectedStudentIds: List<String>.unmodifiable(
        selectedStudentIds ?? this.selectedStudentIds,
      ),
      excludedStudentIds: List<String>.unmodifiable(
        excludedStudentIds ?? this.excludedStudentIds,
      ),
      dueDate: dueDate ?? this.dueDate,
      frequency: frequency ?? this.frequency,
      mandatory: mandatory ?? this.mandatory,
      refundable: refundable ?? this.refundable,
      isActive: isActive ?? this.isActive,
      generated: generated ?? this.generated,
      generatedStudentCount:
          generatedStudentCount ?? this.generatedStudentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    dynamic value,
    T fallback,
  ) {
    final name = value as String?;
    for (final item in values) {
      if (item.name == name) return item;
    }
    return fallback;
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
'@
'lib/features/fees/data/models/student_additional_charge_due_model.dart' = @'
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';

class StudentAdditionalChargeDueModel
    extends StudentAdditionalChargeDueEntity {
  const StudentAdditionalChargeDueModel({
    required super.id,
    required super.chargeId,
    required super.chargeTitle,
    required super.chargeCategory,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.academicSession,
    required super.amount,
    required super.discountAmount,
    required super.waivedAmount,
    required super.netPayable,
    required super.paidAmount,
    required super.outstandingAmount,
    required super.status,
    required super.dueDate,
    required super.generatedAt,
    required super.updatedAt,
    required super.notes,
  });

  factory StudentAdditionalChargeDueModel.fromEntity(
    StudentAdditionalChargeDueEntity entity,
  ) {
    return StudentAdditionalChargeDueModel(
      id: entity.id,
      chargeId: entity.chargeId,
      chargeTitle: entity.chargeTitle,
      chargeCategory: entity.chargeCategory,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      classId: entity.classId,
      className: entity.className,
      sectionId: entity.sectionId,
      sectionName: entity.sectionName,
      academicSession: entity.academicSession,
      amount: entity.amount,
      discountAmount: entity.discountAmount,
      waivedAmount: entity.waivedAmount,
      netPayable: entity.netPayable,
      paidAmount: entity.paidAmount,
      outstandingAmount: entity.outstandingAmount,
      status: entity.status,
      dueDate: entity.dueDate,
      generatedAt: entity.generatedAt,
      updatedAt: entity.updatedAt,
      notes: entity.notes,
    );
  }

  factory StudentAdditionalChargeDueModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return StudentAdditionalChargeDueModel(
      id: document.id,
      chargeId: data['chargeId'] as String? ?? '',
      chargeTitle: data['chargeTitle'] as String? ?? '',
      chargeCategory: _enumValue(
        AdditionalChargeCategory.values,
        data['chargeCategory'],
        AdditionalChargeCategory.other,
      ),
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      admissionNo: data['admissionNo'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      sectionId: data['sectionId'] as String? ?? '',
      sectionName: data['sectionName'] as String? ?? '',
      academicSession: data['academicSession'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      waivedAmount: (data['waivedAmount'] as num?)?.toDouble() ?? 0,
      netPayable: (data['netPayable'] as num?)?.toDouble() ?? 0,
      paidAmount: (data['paidAmount'] as num?)?.toDouble() ?? 0,
      outstandingAmount:
          (data['outstandingAmount'] as num?)?.toDouble() ?? 0,
      status: _enumValue(
        StudentAdditionalChargeStatus.values,
        data['status'],
        StudentAdditionalChargeStatus.unpaid,
      ),
      dueDate: _date(data['dueDate']),
      generatedAt: _date(data['generatedAt']),
      updatedAt: _date(data['updatedAt']),
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'chargeId': chargeId,
    'chargeTitle': chargeTitle,
    'chargeCategory': chargeCategory.name,
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'academicSession': academicSession,
    'amount': amount,
    'discountAmount': discountAmount,
    'waivedAmount': waivedAmount,
    'netPayable': netPayable,
    'paidAmount': paidAmount,
    'outstandingAmount': outstandingAmount,
    'status': status.name,
    'dueDate': Timestamp.fromDate(dueDate),
    'generatedAt': Timestamp.fromDate(generatedAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'notes': notes,
  };

  StudentAdditionalChargeDueModel copyWith({
    String? id,
    String? chargeId,
    String? chargeTitle,
    AdditionalChargeCategory? chargeCategory,
    String? studentId,
    String? studentName,
    String? admissionNo,
    String? classId,
    String? className,
    String? sectionId,
    String? sectionName,
    String? academicSession,
    double? amount,
    double? discountAmount,
    double? waivedAmount,
    double? netPayable,
    double? paidAmount,
    double? outstandingAmount,
    StudentAdditionalChargeStatus? status,
    DateTime? dueDate,
    DateTime? generatedAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return StudentAdditionalChargeDueModel(
      id: id ?? this.id,
      chargeId: chargeId ?? this.chargeId,
      chargeTitle: chargeTitle ?? this.chargeTitle,
      chargeCategory: chargeCategory ?? this.chargeCategory,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      admissionNo: admissionNo ?? this.admissionNo,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      academicSession: academicSession ?? this.academicSession,
      amount: amount ?? this.amount,
      discountAmount: discountAmount ?? this.discountAmount,
      waivedAmount: waivedAmount ?? this.waivedAmount,
      netPayable: netPayable ?? this.netPayable,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      generatedAt: generatedAt ?? this.generatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
    );
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    dynamic value,
    T fallback,
  ) {
    final name = value as String?;
    for (final item in values) {
      if (item.name == name) return item;
    }
    return fallback;
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
'@
'lib/features/fees/data/repositories/additional_charge_repository_impl.dart' = @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/repositories/additional_charge_repository.dart';
import '../models/additional_charge_model.dart';

class AdditionalChargeRepositoryImpl implements AdditionalChargeRepository {
  const AdditionalChargeRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<AdditionalChargeEntity>> getCharges() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .get();
    final charges = snapshot.docs
        .map(AdditionalChargeModel.fromFirestore)
        .toList()
      ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
    return List<AdditionalChargeEntity>.unmodifiable(charges);
  }

  @override
  Future<AdditionalChargeEntity?> getCharge(String id) async {
    final document = await _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .doc(id)
        .get();
    return document.exists
        ? AdditionalChargeModel.fromFirestore(document)
        : null;
  }

  @override
  Future<void> saveCharge(AdditionalChargeEntity charge) {
    return _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .doc(charge.id)
        .set(AdditionalChargeModel.fromEntity(charge).toFirestore());
  }

  @override
  Future<void> updateCharge(AdditionalChargeEntity charge) {
    return _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .doc(charge.id)
        .update(AdditionalChargeModel.fromEntity(charge).toFirestore());
  }

  @override
  Future<void> deleteCharge(String id) {
    return _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .doc(id)
        .delete();
  }

  @override
  Future<String> generateId() async {
    return _firestoreService
        .collection(FirestorePaths.additionalCharges)
        .doc()
        .id;
  }
}
'@
'lib/features/fees/data/repositories/student_additional_charge_due_repository_impl.dart' = @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/student_additional_charge_due_repository.dart';
import '../models/student_additional_charge_due_model.dart';

class StudentAdditionalChargeDueRepositoryImpl
    implements StudentAdditionalChargeDueRepository {
  const StudentAdditionalChargeDueRepositoryImpl(this._firestoreService);

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StudentAdditionalChargeDueEntity>> getStudentDues() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .get();
    final dues = snapshot.docs
        .map(StudentAdditionalChargeDueModel.fromFirestore)
        .toList()
      ..sort((first, second) => second.dueDate.compareTo(first.dueDate));
    return List<StudentAdditionalChargeDueEntity>.unmodifiable(dues);
  }

  @override
  Future<void> saveDue(StudentAdditionalChargeDueEntity due) {
    return _firestoreService
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .doc(due.id)
        .set(StudentAdditionalChargeDueModel.fromEntity(due).toFirestore());
  }

  @override
  Future<void> saveBatch(List<StudentAdditionalChargeDueEntity> dues) async {
    if (dues.isEmpty) return;
    final batch = _firestoreService.instance.batch();
    final collection = _firestoreService.collection(
      FirestorePaths.studentAdditionalChargeDues,
    );
    for (final due in dues) {
      batch.set(
        collection.doc(due.id),
        StudentAdditionalChargeDueModel.fromEntity(due).toFirestore(),
      );
    }
    await batch.commit();
  }

  @override
  Future<void> updateDue(StudentAdditionalChargeDueEntity due) {
    return _firestoreService
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .doc(due.id)
        .update(StudentAdditionalChargeDueModel.fromEntity(due).toFirestore());
  }

  @override
  Future<void> deleteDue(String id) {
    return _firestoreService
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .doc(id)
        .delete();
  }

  @override
  Future<String> generateId() async {
    return _firestoreService
        .collection(FirestorePaths.studentAdditionalChargeDues)
        .doc()
        .id;
  }
}
'@
}

function Add-AfterAnchor {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Anchor,
        [Parameter(Mandatory = $true)][string]$Addition,
        [Parameter(Mandatory = $true)][string]$FileLabel
    )
    $matches = ([regex]::Matches($Content, [regex]::Escape($Anchor))).Count
    if ($matches -ne 1) {
        throw "Expected exactly one integration anchor in ${FileLabel}, found ${matches}: $Anchor"
    }
    return $Content.Replace($Anchor, "$Anchor`r`n$Addition")
}

# Preflight every anchor and prepare all modified content before any write.
$pathsContent = Get-Content -LiteralPath $pathsPath -Raw
if (-not $pathsContent.Contains("static const String additionalCharges = 'additional_charges';")) {
    $pathsContent = Add-AfterAnchor -Content $pathsContent `
        -Anchor "  static const String monthlyFeeDues = 'monthly_fee_dues';" `
        -Addition "  static const String additionalCharges = 'additional_charges';`r`n  static const String studentAdditionalChargeDues =`r`n      'student_additional_charge_dues';" `
        -FileLabel $pathsRelative
} elseif (-not $pathsContent.Contains("studentAdditionalChargeDues")) {
    throw "Partial Additional Charges integration detected in $pathsRelative. No files were changed."
}

$locatorContent = Get-Content -LiteralPath $locatorPath -Raw
$dataImport = "import '../../features/fees/data/repositories/additional_charge_repository_impl.dart';`r`nimport '../../features/fees/data/repositories/student_additional_charge_due_repository_impl.dart';"
if (-not $locatorContent.Contains("data/repositories/additional_charge_repository_impl.dart")) {
    $locatorContent = Add-AfterAnchor -Content $locatorContent `
        -Anchor "import '../../features/fees/data/repositories/monthly_fee_due_repository_impl.dart';" `
        -Addition $dataImport `
        -FileLabel $locatorRelative
}

$domainImport = "import '../../features/fees/domain/repositories/additional_charge_repository.dart';`r`nimport '../../features/fees/domain/repositories/student_additional_charge_due_repository.dart';"
if (-not $locatorContent.Contains("domain/repositories/additional_charge_repository.dart")) {
    $locatorContent = Add-AfterAnchor -Content $locatorContent `
        -Anchor "import '../../features/fees/domain/repositories/monthly_fee_due_repository.dart';" `
        -Addition $domainImport `
        -FileLabel $locatorRelative
}

$registrationAnchor = @'
  sl.registerLazySingleton<MonthlyFeeDueRepository>(
    () => MonthlyFeeDueRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
'@
$registrations = @'
  sl.registerLazySingleton<AdditionalChargeRepository>(
    () => AdditionalChargeRepositoryImpl(sl<FirebaseFirestoreService>()),
  );
  sl.registerLazySingleton<StudentAdditionalChargeDueRepository>(
    () => StudentAdditionalChargeDueRepositoryImpl(
      sl<FirebaseFirestoreService>(),
    ),
  );
'@
if (-not $locatorContent.Contains('registerLazySingleton<AdditionalChargeRepository>')) {
    $normalizedAnchor = $registrationAnchor.TrimEnd("`r", "`n")
    $locatorContent = Add-AfterAnchor -Content $locatorContent `
        -Anchor $normalizedAnchor `
        -Addition $registrations.TrimEnd("`r", "`n") `
        -FileLabel $locatorRelative
} elseif (-not $locatorContent.Contains('registerLazySingleton<StudentAdditionalChargeDueRepository>')) {
    throw "Partial Additional Charges registration detected in $locatorRelative. No files were changed."
}

$dartCommand = Get-Command dart -ErrorAction SilentlyContinue
if ($null -eq $dartCommand) {
    throw 'Dart was not found on PATH. No files were changed.'
}
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($null -eq $flutterCommand) {
    throw 'Flutter was not found on PATH. No files were changed.'
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path $projectRoot ".additional_charges_phase1_backups\$stamp"
$filesToBackup = @($pathsRelative, $locatorRelative) + @($generatedFiles.Keys)
$existingFiles = $filesToBackup | Where-Object {
    Test-Path -LiteralPath (Join-Path $projectRoot $_) -PathType Leaf
}
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
foreach ($relativePath in $existingFiles) {
    $source = Join-Path $projectRoot $relativePath
    $destination = Join-Path $backupRoot $relativePath
    $destinationDirectory = Split-Path -Parent $destination
    New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Force
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($pathsPath, $pathsContent, $utf8NoBom)
[System.IO.File]::WriteAllText($locatorPath, $locatorContent, $utf8NoBom)
foreach ($entry in $generatedFiles.GetEnumerator()) {
    $target = Join-Path $projectRoot $entry.Key
    $targetDirectory = Split-Path -Parent $target
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    [System.IO.File]::WriteAllText(
        $target,
        ($entry.Value.TrimStart("`r", "`n") + "`r`n"),
        $utf8NoBom
    )
}

& $dartCommand.Source format `
    $pathsRelative `
    $locatorRelative `
    @($generatedFiles.Keys)
if ($LASTEXITCODE -ne 0) {
    throw "dart format failed. Backups are available at: $backupRoot"
}

& $flutterCommand.Source analyze
if ($LASTEXITCODE -ne 0) {
    throw "flutter analyze failed. Backups are available at: $backupRoot"
}

Write-Host ''
Write-Host 'Additional Charges Management Phase 1 installed successfully.' -ForegroundColor Green
Write-Host 'Created the domain entities, repositories, data models, and repository implementations.'
Write-Host 'Registered Firestore paths and GetIt dependencies.'
Write-Host "Backup: $backupRoot"
