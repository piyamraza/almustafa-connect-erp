import '../entities/monthly_fee_due_entity.dart';
import '../entities/monthly_fee_generation_entity.dart';
import '../entities/student_fee_assignment_entity.dart';
import '../repositories/monthly_fee_due_repository.dart';
import '../repositories/student_fee_assignment_repository.dart';

class GenerateMonthlyFees {
  const GenerateMonthlyFees(this._assignmentRepository, this._dueRepository);

  final StudentFeeAssignmentRepository _assignmentRepository;
  final MonthlyFeeDueRepository _dueRepository;

  Future<MonthlyFeeGenerationResult> call(
    MonthlyFeeGenerationRequest request,
  ) async {
    final assignments = await _assignmentRepository.getAssignments(
      academicSession: request.academicSession,
      isActive: true,
    );
    final existingForMonth = await _dueRepository.getMonthlyDues(
      academicSession: request.academicSession,
      month: request.month,
      year: request.year,
    );
    final allDues = await _dueRepository.getMonthlyDues(
      academicSession: request.academicSession,
    );

    final existingKeys = existingForMonth.map((item) => item.monthKey).toSet();

    final selected = assignments.where(
      (assignment) => _matchesScope(assignment, request),
    );

    final generated = <MonthlyFeeDueEntity>[];
    final skipped = <String>[];
    var gross = 0.0;
    var discounts = 0.0;
    var arrears = 0.0;
    var advance = 0.0;
    var net = 0.0;
    final now = DateTime.now();

    for (final assignment in selected) {
      final key =
          '${assignment.studentId}|${request.year}|'
          '${request.month.toString().padLeft(2, '0')}';

      if (existingKeys.contains(key)) {
        skipped.add('${assignment.studentName} (${assignment.admissionNo})');
        continue;
      }

      if (assignment.effectiveFrom.isAfter(
        DateTime(request.year, request.month + 1, 0),
      )) {
        skipped.add('${assignment.studentName} — assignment not effective yet');
        continue;
      }

      final studentPreviousDues = allDues
          .where(
            (due) =>
                due.studentId == assignment.studentId &&
                _isBeforeTarget(
                  due.year,
                  due.month,
                  request.year,
                  request.month,
                ) &&
                due.status != MonthlyFeeDueStatus.cancelled,
          )
          .toList();

      final previousArrears = studentPreviousDues.fold<double>(
        0,
        (sum, due) => sum + due.outstandingAmount,
      );

      final tuition = assignment.tuitionFee;
      final double transport = assignment.transportEnabled
          ? assignment.baseTransportFee
          : 0.0;
      final other = assignment.baseOtherMonthlyCharges;
      final discount = assignment.discountAmount;
      final scholarship = assignment.scholarshipAmount;
      final sibling = assignment.siblingDiscountAmount;
      const advanceAdjustment = 0.0;

      final monthlyNet = assignment.monthlyPayable;
      final netPayable = monthlyNet + previousArrears - advanceAdjustment;

      final dueDay = request.dueDay.clamp(1, 28).toInt();
      final due = MonthlyFeeDueEntity(
        id: _dueRepository.generateId(),
        studentId: assignment.studentId,
        studentName: assignment.studentName,
        admissionNo: assignment.admissionNo,
        classId: assignment.classId,
        sectionId: assignment.sectionId,
        academicSession: assignment.academicSession,
        feeAssignmentId: assignment.id,
        month: request.month,
        year: request.year,
        dueDate: DateTime(request.year, request.month, dueDay),
        tuitionFee: tuition,
        transportFee: transport,
        otherMonthlyCharges: other,
        discountAmount: discount,
        scholarshipAmount: scholarship,
        siblingDiscountAmount: sibling,
        previousArrears: previousArrears,
        advanceAdjustment: advanceAdjustment,
        netPayable: netPayable < 0 ? 0 : netPayable,
        paidAmount: 0,
        status: MonthlyFeeDueStatus.unpaid,
        createdAt: now,
        updatedAt: now,
      );

      generated.add(due);
      gross += tuition + transport + other;
      discounts += discount + scholarship + sibling;
      arrears += previousArrears;
      advance += advanceAdjustment;
      net += due.netPayable;
    }

    await _dueRepository.saveMonthlyDues(generated);

    return MonthlyFeeGenerationResult(
      generatedDues: generated,
      skippedStudents: skipped,
      totalGross: gross,
      totalDiscounts: discounts,
      totalArrears: arrears,
      totalAdvanceAdjustment: advance,
      netReceivable: net,
    );
  }

  bool _matchesScope(
    StudentFeeAssignmentEntity assignment,
    MonthlyFeeGenerationRequest request,
  ) {
    return switch (request.scope) {
      FeeGenerationScope.entireSchool => true,
      FeeGenerationScope.classWise => assignment.classId == request.classId,
      FeeGenerationScope.sectionWise =>
        assignment.classId == request.classId &&
            assignment.sectionId == request.sectionId,
      FeeGenerationScope.selectedStudents =>
        request.selectedAssignmentIds.contains(assignment.id),
    };
  }

  bool _isBeforeTarget(int year, int month, int targetYear, int targetMonth) {
    if (year < targetYear) return true;
    if (year > targetYear) return false;
    return month < targetMonth;
  }
}
