import '../../../fees/domain/entities/monthly_fee_due_entity.dart';

class ParentFeeSummary {
  const ParentFeeSummary({
    required this.dues,
    required this.totalPayable,
    required this.totalPaid,
    required this.totalOutstanding,
    required this.totalAdvanceAdjusted,
    required this.paidMonths,
    required this.partiallyPaidMonths,
    required this.unpaidMonths,
    required this.overdueMonths,
  });

  final List<MonthlyFeeDueEntity> dues;
  final double totalPayable;
  final double totalPaid;
  final double totalOutstanding;
  final double totalAdvanceAdjusted;
  final int paidMonths;
  final int partiallyPaidMonths;
  final int unpaidMonths;
  final int overdueMonths;
}
