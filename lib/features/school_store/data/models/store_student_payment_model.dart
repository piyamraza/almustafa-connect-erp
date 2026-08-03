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

  factory StoreStudentPaymentModel.fromMap(Map<String, dynamic> map) {
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
