import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/fee_payment_entity.dart';

class FeePaymentModel extends FeePaymentEntity {
  FeePaymentModel({
    required super.id,
    required super.receiptNumber,
    required super.studentId,
    required super.studentName,
    required super.admissionNo,
    required super.academicSession,
    required super.paymentDate,
    required super.method,
    required super.referenceNumber,
    required super.totalPaid,
    required super.advanceAmount,
    required super.allocations,
    required super.status,
    required super.notes,
    required super.createdAt,
    required super.updatedAt,
    super.cancelledAt,
    super.cancellationReason,
  });

  factory FeePaymentModel.fromEntity(FeePaymentEntity entity) {
    return FeePaymentModel(
      id: entity.id,
      receiptNumber: entity.receiptNumber,
      studentId: entity.studentId,
      studentName: entity.studentName,
      admissionNo: entity.admissionNo,
      academicSession: entity.academicSession,
      paymentDate: entity.paymentDate,
      method: entity.method,
      referenceNumber: entity.referenceNumber,
      totalPaid: entity.totalPaid,
      advanceAmount: entity.advanceAmount,
      allocations: entity.allocations,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      cancelledAt: entity.cancelledAt,
      cancellationReason: entity.cancellationReason,
    );
  }

  factory FeePaymentModel.fromMap(Map<String, dynamic> map) {
    final rawAllocations =
        map['allocations'] as List<dynamic>? ?? const <dynamic>[];

    return FeePaymentModel(
      id: map['id'] as String? ?? '',
      receiptNumber: map['receiptNumber'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNo: map['admissionNo'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      paymentDate: _date(map['paymentDate']),
      method: FeePaymentMethod.values.firstWhere(
        (item) => item.name == map['method'],
        orElse: () => FeePaymentMethod.cash,
      ),
      referenceNumber: map['referenceNumber'] as String? ?? '',
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0,
      advanceAmount: (map['advanceAmount'] as num?)?.toDouble() ?? 0,
      allocations: rawAllocations
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => FeePaymentAllocationEntity(
              dueId: item['dueId'] as String? ?? '',
              month: (item['month'] as num?)?.toInt() ?? 1,
              year: (item['year'] as num?)?.toInt() ?? DateTime.now().year,
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
              dueType:
                  FeeDueType.values
                      .where((value) => value.name == item['dueType'])
                      .firstOrNull ??
                  FeeDueType.monthly,
            ),
          )
          .toList(growable: false),
      status: FeePaymentStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => FeePaymentStatus.completed,
      ),
      notes: map['notes'] as String? ?? '',
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      cancelledAt: _nullableDate(map['cancelledAt']),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'receiptNumber': receiptNumber,
    'studentId': studentId,
    'studentName': studentName,
    'admissionNo': admissionNo,
    'academicSession': academicSession,
    'paymentDate': Timestamp.fromDate(paymentDate),
    'method': method.name,
    'referenceNumber': referenceNumber,
    'totalPaid': totalPaid,
    'advanceAmount': advanceAmount,
    'allocations': allocations
        .map(
          (item) => {
            'dueId': item.dueId,
            'month': item.month,
            'year': item.year,
            'amount': item.amount,
            'dueType': item.dueType.name,
          },
        )
        .toList(growable: false),
    'status': status.name,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
    'cancelledAt': cancelledAt == null
        ? null
        : Timestamp.fromDate(cancelledAt!),
    'cancellationReason': cancellationReason,
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) =>
      value == null ? null : _date(value);
}
