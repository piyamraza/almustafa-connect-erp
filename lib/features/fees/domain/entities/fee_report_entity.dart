import 'package:equatable/equatable.dart';

import 'fee_payment_entity.dart';
import 'monthly_fee_due_entity.dart';

enum FeeReportType {
  collectionSummary,
  outstanding,
  defaulters,
  discounts,
  paymentMethods,
  demandVsCollection,
  classWiseOutstanding,
  classWiseOutstandingWithoutAmount,
}

class OutstandingFeeStudent extends Equatable {
  const OutstandingFeeStudent({
    required this.studentId,
    required this.classId,
    required this.className,
    required this.studentName,
    required this.fatherName,
    required this.rollNumber,
    required this.outstandingAmount,
  });

  final String studentId;
  final String classId;
  final String className;
  final String studentName;
  final String fatherName;
  final String rollNumber;
  final double outstandingAmount;

  @override
  List<Object> get props => [
    studentId,
    classId,
    className,
    studentName,
    fatherName,
    rollNumber,
    outstandingAmount,
  ];
}

class ClassOutstandingFeeGroup extends Equatable {
  ClassOutstandingFeeGroup({
    required this.classId,
    required this.className,
    required List<OutstandingFeeStudent> students,
  }) : students = List.unmodifiable(students);

  final String classId;
  final String className;
  final List<OutstandingFeeStudent> students;

  double get totalOutstanding =>
      students.fold(0, (total, student) => total + student.outstandingAmount);

  @override
  List<Object> get props => [classId, className, students];
}

class FeeReportData extends Equatable {
  FeeReportData({
    required this.type,
    required List<MonthlyFeeDueEntity> dues,
    required List<FeePaymentEntity> payments,
    required this.startDate,
    required this.endDate,
    this.outstandingGroups = const [],
  }) : dues = List<MonthlyFeeDueEntity>.unmodifiable(dues),
       payments = List<FeePaymentEntity>.unmodifiable(payments);

  final FeeReportType type;
  final List<MonthlyFeeDueEntity> dues;
  final List<FeePaymentEntity> payments;
  final DateTime startDate;
  final DateTime endDate;
  final List<ClassOutstandingFeeGroup> outstandingGroups;

  double get totalDemand =>
      dues.fold<double>(0, (sum, item) => sum + item.netPayable);

  double get totalCollected => payments
      .where((item) => item.status == FeePaymentStatus.completed)
      .fold<double>(0, (sum, item) => sum + item.totalPaid);

  double get totalOutstanding =>
      dues.fold<double>(0, (sum, item) => sum + item.outstandingAmount);

  double get totalDiscounts =>
      dues.fold<double>(0, (sum, item) => sum + item.totalDeductions);

  double get totalArrears =>
      dues.fold<double>(0, (sum, item) => sum + item.previousArrears);

  double get totalAdvance => payments
      .where((item) => item.status == FeePaymentStatus.completed)
      .fold<double>(0, (sum, item) => sum + item.advanceAmount);

  int get paidCount =>
      dues.where((item) => item.status == MonthlyFeeDueStatus.paid).length;

  int get partialCount => dues
      .where((item) => item.status == MonthlyFeeDueStatus.partiallyPaid)
      .length;

  int get unpaidCount =>
      dues.where((item) => item.status == MonthlyFeeDueStatus.unpaid).length;

  Map<FeePaymentMethod, double> get collectionByMethod {
    final values = {for (final method in FeePaymentMethod.values) method: 0.0};

    for (final payment in payments) {
      if (payment.status == FeePaymentStatus.completed) {
        values[payment.method] =
            (values[payment.method] ?? 0) + payment.totalPaid;
      }
    }

    return values;
  }

  @override
  List<Object> get props => [
    type,
    dues,
    payments,
    startDate,
    endDate,
    outstandingGroups,
  ];
}
