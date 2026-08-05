import '../../../../core/audit/domain/entities/audit_log_entity.dart';
import '../../../../core/audit/domain/services/audit_service.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../models/fee_payment_model.dart';
import '../models/monthly_fee_due_model.dart';
import '../models/student_additional_charge_due_model.dart';

class FeePaymentRepositoryImpl implements FeePaymentRepository {
  FeePaymentRepositoryImpl({
    required this._firestoreService,
    required AuditService auditService,
  }) : _auditService = auditService;

  final FirebaseFirestoreService _firestoreService;
  final AuditService _auditService;

  @override
  Future<List<FeePaymentEntity>> getPayments({
    String? academicSession,
    String? studentId,
  }) async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.feePayments)
        .get();

    final values =
        snapshot.docs
            .map(
              (document) => FeePaymentModel.fromMap({
                ...document.data(),
                'id': document.id,
              }),
            )
            .where(
              (item) =>
                  (academicSession == null ||
                      item.academicSession == academicSession) &&
                  (studentId == null || item.studentId == studentId),
            )
            .toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return List<FeePaymentEntity>.unmodifiable(values);
  }

  @override
  Future<FeePaymentEntity> collectPayment({
    required String academicSession,
    required String studentId,
    required String studentName,
    required String admissionNo,
    required DateTime paymentDate,
    required FeePaymentMethod method,
    required String referenceNumber,
    required double amount,
    required List<String> dueIds,
    List<String> additionalChargeDueIds = const [],
    required String notes,
  }) async {
    if (amount <= 0) {
      throw StateError('Payment amount must be greater than zero.');
    }
    if (method != FeePaymentMethod.cash && referenceNumber.trim().isEmpty) {
      throw StateError(
        'Transaction/reference number is required for non-cash payment.',
      );
    }

    final dueCollection = _firestoreService.collection(
      FirestorePaths.monthlyFeeDues,
    );
    final paymentCollection = _firestoreService.collection(
      FirestorePaths.feePayments,
    );
    final additionalDueCollection = _firestoreService.collection(
      FirestorePaths.studentAdditionalChargeDues,
    );

    final dues = <MonthlyFeeDueEntity>[];
    final additionalDues = <StudentAdditionalChargeDueEntity>[];

    for (final dueId in dueIds) {
      final document = await dueCollection.doc(dueId).get();
      if (!document.exists || document.data() == null) {
        throw StateError('A selected monthly due was not found.');
      }

      final due = MonthlyFeeDueModel.fromMap({
        ...document.data()!,
        'id': document.id,
      });

      if (due.studentId != studentId) {
        throw StateError('Selected dues belong to different students.');
      }
      if (due.status == MonthlyFeeDueStatus.cancelled ||
          due.status == MonthlyFeeDueStatus.paid) {
        continue;
      }

      dues.add(due);
    }

    for (final dueId in additionalChargeDueIds) {
      final document = await additionalDueCollection.doc(dueId).get();
      if (!document.exists || document.data() == null) {
        throw StateError('A selected additional charge due was not found.');
      }
      final due = StudentAdditionalChargeDueModel.fromMap({
        ...document.data()!,
        'id': document.id,
      });
      if (due.studentId != studentId) {
        throw StateError('Selected dues belong to different students.');
      }
      if (due.status == StudentAdditionalChargeDueStatus.cancelled ||
          due.status == StudentAdditionalChargeDueStatus.waived ||
          due.status == StudentAdditionalChargeDueStatus.paid) {
        continue;
      }
      additionalDues.add(due);
    }

    dues.sort((a, b) {
      final year = a.year.compareTo(b.year);
      if (year != 0) return year;
      return a.month.compareTo(b.month);
    });

    var remaining = amount;
    final allocations = <FeePaymentAllocationEntity>[];
    final updatedDues = <MonthlyFeeDueEntity>[];
    final updatedAdditionalDues = <StudentAdditionalChargeDueEntity>[];
    final now = DateTime.now();

    for (final due in dues) {
      if (remaining <= 0) break;

      final allocation = remaining < due.outstandingAmount
          ? remaining
          : due.outstandingAmount;

      if (allocation <= 0) continue;

      final newPaidAmount = due.paidAmount + allocation;
      final newStatus = newPaidAmount >= due.netPayable
          ? MonthlyFeeDueStatus.paid
          : MonthlyFeeDueStatus.partiallyPaid;

      allocations.add(
        FeePaymentAllocationEntity(
          dueId: due.id,
          month: due.month,
          year: due.year,
          amount: allocation,
        ),
      );

      updatedDues.add(
        MonthlyFeeDueEntity(
          id: due.id,
          studentId: due.studentId,
          studentName: due.studentName,
          admissionNo: due.admissionNo,
          classId: due.classId,
          sectionId: due.sectionId,
          academicSession: due.academicSession,
          feeAssignmentId: due.feeAssignmentId,
          month: due.month,
          year: due.year,
          dueDate: due.dueDate,
          tuitionFee: due.tuitionFee,
          transportFee: due.transportFee,
          otherMonthlyCharges: due.otherMonthlyCharges,
          discountAmount: due.discountAmount,
          scholarshipAmount: due.scholarshipAmount,
          siblingDiscountAmount: due.siblingDiscountAmount,
          previousArrears: due.previousArrears,
          advanceAdjustment: due.advanceAdjustment,
          netPayable: due.netPayable,
          paidAmount: newPaidAmount,
          status: newStatus,
          createdAt: due.createdAt,
          updatedAt: now,
        ),
      );

      remaining -= allocation;
    }

    additionalDues.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    for (final due in additionalDues) {
      if (remaining <= 0) break;
      final allocation = remaining < due.outstandingAmount
          ? remaining
          : due.outstandingAmount;
      if (allocation <= 0) continue;
      final newPaid = due.paidAmount + allocation;
      allocations.add(
        FeePaymentAllocationEntity(
          dueId: due.id,
          month: due.dueDate.month,
          year: due.dueDate.year,
          amount: allocation,
          dueType: FeeDueType.additionalCharge,
        ),
      );
      updatedAdditionalDues.add(
        StudentAdditionalChargeDueEntity(
          id: due.id,
          chargeId: due.chargeId,
          chargeTitle: due.chargeTitle,
          chargeCategory: due.chargeCategory,
          studentId: due.studentId,
          studentName: due.studentName,
          admissionNo: due.admissionNo,
          classId: due.classId,
          sectionId: due.sectionId,
          academicSession: due.academicSession,
          amount: due.amount,
          discountAmount: due.discountAmount,
          waivedAmount: due.waivedAmount,
          netPayable: due.netPayable,
          paidAmount: newPaid,
          dueDate: due.dueDate,
          status: newPaid >= due.netPayable
              ? StudentAdditionalChargeDueStatus.paid
              : StudentAdditionalChargeDueStatus.partiallyPaid,
          notes: due.notes,
          generatedAt: due.generatedAt,
          updatedAt: now,
        ),
      );
      remaining -= allocation;
    }

    final id = generateId();
    final receiptNumber =
        'RCPT-${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${id.substring(0, 6).toUpperCase()}';

    final payment = FeePaymentEntity(
      id: id,
      receiptNumber: receiptNumber,
      studentId: studentId,
      studentName: studentName,
      admissionNo: admissionNo,
      academicSession: academicSession,
      paymentDate: paymentDate,
      method: method,
      referenceNumber: referenceNumber.trim(),
      totalPaid: amount,
      advanceAmount: remaining < 0 ? 0 : remaining,
      allocations: allocations,
      status: FeePaymentStatus.completed,
      notes: notes.trim(),
      createdAt: now,
      updatedAt: now,
    );

    final batch = _firestoreService.instance.batch();

    for (final due in updatedDues) {
      batch.set(
        dueCollection.doc(due.id),
        MonthlyFeeDueModel.fromEntity(due).toMap(),
      );
    }
    for (final due in updatedAdditionalDues) {
      batch.set(
        additionalDueCollection.doc(due.id),
        StudentAdditionalChargeDueModel.fromEntity(due).toMap(),
      );
    }

    batch.set(
      paymentCollection.doc(payment.id),
      FeePaymentModel.fromEntity(payment).toMap(),
    );

    await batch.commit();

    await _auditService.log(
      module: 'Fees',
      action: AuditAction.collectPayment,
      recordId: payment.id,
      description:
          'Fee payment collected: ${payment.receiptNumber} for $studentName',
      newValues: {
        'receiptNumber': payment.receiptNumber,
        'studentId': payment.studentId,
        'studentName': payment.studentName,
        'admissionNo': payment.admissionNo,
        'academicSession': payment.academicSession,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'referenceNumber': payment.referenceNumber,
        'totalPaid': payment.totalPaid,
        'advanceAmount': payment.advanceAmount,
        'monthlyDueIds': dueIds,
        'additionalChargeDueIds': additionalChargeDueIds,
        'notes': payment.notes,
      },
    );

    return payment;
  }

  @override
  Future<void> cancelPayment({
    required String paymentId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('Cancellation reason is required.');
    }

    final paymentCollection = _firestoreService.collection(
      FirestorePaths.feePayments,
    );
    final dueCollection = _firestoreService.collection(
      FirestorePaths.monthlyFeeDues,
    );
    final additionalDueCollection = _firestoreService.collection(
      FirestorePaths.studentAdditionalChargeDues,
    );

    final paymentDocument = await paymentCollection.doc(paymentId).get();

    if (!paymentDocument.exists || paymentDocument.data() == null) {
      throw StateError('Payment record was not found.');
    }

    final payment = FeePaymentModel.fromMap({
      ...paymentDocument.data()!,
      'id': paymentDocument.id,
    });

    if (payment.status == FeePaymentStatus.cancelled) {
      throw StateError('Payment is already cancelled.');
    }

    final batch = _firestoreService.instance.batch();
    final now = DateTime.now();

    for (final allocation in payment.allocations) {
      if (allocation.dueType == FeeDueType.additionalCharge) {
        final document = await additionalDueCollection
            .doc(allocation.dueId)
            .get();
        if (!document.exists || document.data() == null) continue;
        final due = StudentAdditionalChargeDueModel.fromMap({
          ...document.data()!,
          'id': document.id,
        });
        final paid = (due.paidAmount - allocation.amount).clamp(
          0,
          double.infinity,
        );
        final status = paid <= 0
            ? StudentAdditionalChargeDueStatus.unpaid
            : paid >= due.netPayable
            ? StudentAdditionalChargeDueStatus.paid
            : StudentAdditionalChargeDueStatus.partiallyPaid;
        batch.update(additionalDueCollection.doc(due.id), {
          'paidAmount': paid,
          'status': status.name,
          'updatedAt': now,
        });
        continue;
      }
      final dueDocument = await dueCollection.doc(allocation.dueId).get();

      if (!dueDocument.exists || dueDocument.data() == null) {
        continue;
      }

      final due = MonthlyFeeDueModel.fromMap({
        ...dueDocument.data()!,
        'id': dueDocument.id,
      });

      final newPaid = due.paidAmount - allocation.amount;
      final correctedPaid = newPaid < 0 ? 0.0 : newPaid;
      final newStatus = correctedPaid <= 0
          ? MonthlyFeeDueStatus.unpaid
          : correctedPaid >= due.netPayable
          ? MonthlyFeeDueStatus.paid
          : MonthlyFeeDueStatus.partiallyPaid;

      batch.update(dueCollection.doc(due.id), {
        'paidAmount': correctedPaid,
        'status': newStatus.name,
        'updatedAt': now,
      });
    }

    batch.update(paymentCollection.doc(payment.id), {
      'status': FeePaymentStatus.cancelled.name,
      'cancelledAt': now,
      'cancellationReason': reason.trim(),
      'updatedAt': now,
    });

    await batch.commit();

    await _auditService.log(
      module: 'Fees',
      action: AuditAction.delete,
      recordId: payment.id,
      description:
          'Fee payment cancelled: ${payment.receiptNumber}. Reason: ${reason.trim()}',
      oldValues: {
        'receiptNumber': payment.receiptNumber,
        'studentId': payment.studentId,
        'studentName': payment.studentName,
        'admissionNo': payment.admissionNo,
        'paymentDate': payment.paymentDate.toIso8601String(),
        'method': payment.method.name,
        'referenceNumber': payment.referenceNumber,
        'totalPaid': payment.totalPaid,
        'advanceAmount': payment.advanceAmount,
        'status': payment.status.name,
      },
      newValues: {
        'status': FeePaymentStatus.cancelled.name,
        'cancellationReason': reason.trim(),
        'cancelledAt': now.toIso8601String(),
      },
    );
  }

  @override
  String generateId() {
    return _firestoreService.collection(FirestorePaths.feePayments).doc().id;
  }
}
