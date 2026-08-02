import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/cashbook_entry_entity.dart';

class CashbookEntryModel extends CashbookEntryEntity {
  const CashbookEntryModel({
    required super.id,
    required super.entryDate,
    required super.entryType,
    required super.amount,
    required super.description,
    required super.paymentMethod,
    required super.referenceNumber,
    required super.sourceType,
    required super.sourceId,
    required super.createdAt,
    required super.createdBy,
  });

  factory CashbookEntryModel.fromEntity(CashbookEntryEntity entity) {
    return CashbookEntryModel(
      id: entity.id,
      entryDate: entity.entryDate,
      entryType: entity.entryType,
      amount: entity.amount,
      description: entity.description,
      paymentMethod: entity.paymentMethod,
      referenceNumber: entity.referenceNumber,
      sourceType: entity.sourceType,
      sourceId: entity.sourceId,
      createdAt: entity.createdAt,
      createdBy: entity.createdBy,
    );
  }

  factory CashbookEntryModel.fromMap(Map<String, dynamic> map) {
    return CashbookEntryModel(
      id: map['id'] as String? ?? '',
      entryDate: _date(map['entryDate']),
      entryType: _entryType(map['entryType']),
      amount: _int(map['amount']),
      description: map['description'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? '',
      referenceNumber: map['referenceNumber'] as String? ?? '',
      sourceType: map['sourceType'] as String? ?? '',
      sourceId: map['sourceId'] as String? ?? '',
      createdAt: _date(map['createdAt']),
      createdBy: map['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryDate': entryDate.toIso8601String(),
      'entryType': entryType.name,
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'schemaVersion': 1,
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static CashbookEntryType _entryType(dynamic value) {
    final raw = value?.toString();
    for (final item in CashbookEntryType.values) {
      if (item.name == raw) return item;
    }
    return CashbookEntryType.income;
  }
}
