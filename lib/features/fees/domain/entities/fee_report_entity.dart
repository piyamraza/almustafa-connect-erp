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
}

class FeeReportData extends Equatable {
  FeeReportData({
    required this.type,
    required List<MonthlyFeeDueEntity> dues,
    required List<FeePaymentEntity> payments,
    required this.startDate,
    required this.endDate,
  }) : dues = List<MonthlyFeeDueEntity>.unmodifiable(dues),
       payments = List<FeePaymentEntity>.unmodifiable(payments);

  final FeeReportType type;
  final List<MonthlyFeeDueEntity> dues;
  final List<FeePaymentEntity> payments;
  final DateTime startDate;
  final DateTime endDate;

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
  List<Object> get props => [type, dues, payments, startDate, endDate];
}
