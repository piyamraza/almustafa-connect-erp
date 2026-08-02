import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/expense_category_entity.dart';
import '../../domain/entities/expense_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

int _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

T _enum<T extends Enum>(List<T> values, dynamic value, T fallback) {
  final name = value?.toString();
  return values.firstWhere((item) => item.name == name, orElse: () => fallback);
}

class ExpenseCategoryModel extends ExpenseCategoryEntity {
  const ExpenseCategoryModel({
    required super.id,
    required super.name,
    required super.description,
    required super.isActive,
    required super.displayOrder,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseCategoryModel.fromMap(Map<String, dynamic> map) =>
      ExpenseCategoryModel(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        isActive: map['isActive'] as bool? ?? true,
        displayOrder: _int(map['displayOrder']),
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'isActive': isActive,
    'displayOrder': displayOrder,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.categoryId,
    required super.categoryName,
    required super.amount,
    required super.expenseDate,
    required super.description,
    required super.payeeName,
    required super.paymentMethod,
    required super.referenceNumber,
    required super.receiptUrl,
    required super.status,
    required super.enteredBy,
    required super.approvedBy,
    required super.createdAt,
    required super.updatedAt,
    required super.sourceType,
    required super.sourceId,
    super.approvedAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] as String? ?? '',
    categoryId: map['categoryId'] as String? ?? '',
    categoryName: map['categoryName'] as String? ?? '',
    amount: _int(map['amount']),
    expenseDate: _date(map['expenseDate']),
    description: map['description'] as String? ?? '',
    payeeName: map['payeeName'] as String? ?? '',
    paymentMethod: map['paymentMethod'] as String? ?? '',
    referenceNumber: map['referenceNumber'] as String? ?? '',
    receiptUrl: map['receiptUrl'] as String? ?? '',
    status: _enum(ExpenseStatus.values, map['status'], ExpenseStatus.draft),
    enteredBy: map['enteredBy'] as String? ?? '',
    approvedBy: map['approvedBy'] as String? ?? '',
    approvedAt: map['approvedAt'] == null ? null : _date(map['approvedAt']),
    createdAt: _date(map['createdAt']),
    updatedAt: _date(map['updatedAt']),
    sourceType: _enum(
      ExpenseSourceType.values,
      map['sourceType'],
      ExpenseSourceType.manual,
    ),
    sourceId: map['sourceId'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'amount': amount,
    'expenseDate': expenseDate.toIso8601String(),
    'description': description,
    'payeeName': payeeName,
    'paymentMethod': paymentMethod,
    'referenceNumber': referenceNumber,
    'receiptUrl': receiptUrl,
    'status': status.name,
    'enteredBy': enteredBy,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sourceType': sourceType.name,
    'sourceId': sourceId,
  };
}
