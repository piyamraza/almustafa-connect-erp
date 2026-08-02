import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/income_entry_entity.dart';

class IncomeEntryModel extends IncomeEntryEntity {
  const IncomeEntryModel({
    required super.id,
    required super.incomeType,
    required super.amount,
    required super.incomeDate,
    required super.description,
    required super.paymentMethod,
    required super.referenceNumber,
    required super.studentId,
    required super.studentName,
    required super.feePaymentId,
    required super.enteredBy,
    required super.createdAt,
    required super.updatedAt,
    required super.sourceType,
    required super.sourceId,
    required super.status,
    super.reversedAt,
    super.reversalReason,
  });

  factory IncomeEntryModel.fromEntity(IncomeEntryEntity entity) {
    return IncomeEntryModel(
      id: entity.id,
      incomeType: entity.incomeType,
      amount: entity.amount,
      incomeDate: entity.incomeDate,
      description: entity.description,
      paymentMethod: entity.paymentMethod,
      referenceNumber: entity.referenceNumber,
      studentId: entity.studentId,
      studentName: entity.studentName,
      feePaymentId: entity.feePaymentId,
      enteredBy: entity.enteredBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      status: entity.status,
      reversedAt: entity.reversedAt,
      reversalReason: entity.reversalReason,
    );
  }

  factory IncomeEntryModel.fromMap(Map<String, dynamic> map) {
    return IncomeEntryModel(
      id: map['id'] as String? ?? '',
      incomeType: _enumValue(
        IncomeType.values,
        map['incomeType'],
        IncomeType.other,
      ),
      amount: _intValue(map['amount']),
      incomeDate: _dateValue(map['incomeDate']),
      description: map['description'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      referenceNumber: map['referenceNumber'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      feePaymentId: map['feePaymentId'] as String? ?? '',
      enteredBy: map['enteredBy'] as String? ?? '',
      createdAt: _dateValue(map['createdAt']),
      updatedAt: _dateValue(map['updatedAt']),
      sourceType: _enumValue(
        IncomeSourceType.values,
        map['sourceType'],
        IncomeSourceType.manual,
      ),
      sourceId: map['sourceId'] as String? ?? '',
      status: _enumValue(
        IncomeEntryStatus.values,
        map['status'],
        IncomeEntryStatus.active,
      ),
      reversedAt: map['reversedAt'] == null
          ? null
          : _dateValue(map['reversedAt']),
      reversalReason: map['reversalReason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'incomeType': incomeType.name,
      'amount': amount,
      'incomeDate': incomeDate.toIso8601String(),
      'description': description,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'studentId': studentId,
      'studentName': studentName,
      'feePaymentId': feePaymentId,
      'enteredBy': enteredBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'status': status.name,
      'reversedAt': reversedAt?.toIso8601String(),
      'reversalReason': reversalReason,
      'schemaVersion': 2,
    };
  }

  static DateTime _dateValue(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static T _enumValue<T extends Enum>(
    List<T> values,
    dynamic value,
    T fallback,
  ) {
    final raw = value?.toString();
    for (final item in values) {
      if (item.name == raw) return item;
    }
    return fallback;
  }
}
