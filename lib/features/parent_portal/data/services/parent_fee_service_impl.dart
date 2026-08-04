import '../../../fees/domain/entities/monthly_fee_due_entity.dart';
import '../../../fees/domain/repositories/monthly_fee_due_repository.dart';
import '../../domain/entities/parent_fee_summary.dart';
import '../../domain/services/parent_fee_service.dart';

class ParentFeeServiceImpl implements ParentFeeService {
  const ParentFeeServiceImpl(this._repository);

  final MonthlyFeeDueRepository _repository;

  @override
  Future<ParentFeeSummary> loadStudentFeeSummary({
    required String studentId,
    String? academicSession,
  }) async {
    final dues = await _repository.getMonthlyDues(
      studentId: studentId.trim(),
      academicSession: academicSession,
    );

    final sorted = dues.toList()
      ..sort((a, b) {
        final yearCompare = b.year.compareTo(a.year);
        if (yearCompare != 0) return yearCompare;
        return b.month.compareTo(a.month);
      });

    var totalPayable = 0.0;
    var totalPaid = 0.0;
    var totalOutstanding = 0.0;
    var totalAdvanceAdjusted = 0.0;
    var paidMonths = 0;
    var partiallyPaidMonths = 0;
    var unpaidMonths = 0;
    var overdueMonths = 0;

    final now = DateTime.now();

    for (final due in sorted) {
      totalPayable += due.netPayable;
      totalPaid += due.paidAmount;
      totalOutstanding += due.outstandingAmount;
      totalAdvanceAdjusted += due.advanceAdjustment;

      switch (due.status) {
        case MonthlyFeeDueStatus.paid:
          paidMonths++;
          break;
        case MonthlyFeeDueStatus.partiallyPaid:
          partiallyPaidMonths++;
          break;
        case MonthlyFeeDueStatus.unpaid:
          unpaidMonths++;
          break;
        case MonthlyFeeDueStatus.cancelled:
          break;
      }

      if (due.status != MonthlyFeeDueStatus.paid &&
          due.status != MonthlyFeeDueStatus.cancelled &&
          due.dueDate.isBefore(now)) {
        overdueMonths++;
      }
    }

    return ParentFeeSummary(
      dues: List<MonthlyFeeDueEntity>.unmodifiable(sorted),
      totalPayable: totalPayable,
      totalPaid: totalPaid,
      totalOutstanding: totalOutstanding,
      totalAdvanceAdjusted: totalAdvanceAdjusted,
      paidMonths: paidMonths,
      partiallyPaidMonths: partiallyPaidMonths,
      unpaidMonths: unpaidMonths,
      overdueMonths: overdueMonths,
    );
  }
}
