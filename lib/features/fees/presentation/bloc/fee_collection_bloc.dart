import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fee_payment_entity.dart';
import '../../domain/entities/monthly_fee_due_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/student_additional_charge_due_repository.dart';

sealed class FeeCollectionEvent {
  const FeeCollectionEvent();
}

class LoadFeeCollectionData extends FeeCollectionEvent {
  const LoadFeeCollectionData({required this.academicSession, this.studentId});

  final String academicSession;
  final String? studentId;
}

class CollectStudentFeePayment extends FeeCollectionEvent {
  const CollectStudentFeePayment({
    required this.academicSession,
    required this.studentId,
    required this.studentName,
    required this.admissionNo,
    required this.paymentDate,
    required this.method,
    required this.referenceNumber,
    required this.amount,
    required this.dueIds,
    this.additionalChargeDueIds = const [],
    required this.notes,
  });

  final String academicSession;
  final String studentId;
  final String studentName;
  final String admissionNo;
  final DateTime paymentDate;
  final FeePaymentMethod method;
  final String referenceNumber;
  final double amount;
  final List<String> dueIds;
  final List<String> additionalChargeDueIds;
  final String notes;
}

class CancelStudentFeePayment extends FeeCollectionEvent {
  const CancelStudentFeePayment({
    required this.paymentId,
    required this.reason,
    required this.academicSession,
    required this.studentId,
  });

  final String paymentId;
  final String reason;
  final String academicSession;
  final String studentId;
}

sealed class FeeCollectionState {
  const FeeCollectionState();
}

class FeeCollectionInitial extends FeeCollectionState {
  const FeeCollectionInitial();
}

class FeeCollectionLoading extends FeeCollectionState {
  const FeeCollectionLoading();
}

class FeeCollectionLoaded extends FeeCollectionState {
  const FeeCollectionLoaded({
    required this.dues,
    required this.payments,
    required this.additionalChargeDues,
    this.latestPayment,
    this.message,
  });

  final List<MonthlyFeeDueEntity> dues;
  final List<FeePaymentEntity> payments;
  final List<StudentAdditionalChargeDueEntity> additionalChargeDues;
  final FeePaymentEntity? latestPayment;
  final String? message;
}

class FeeCollectionError extends FeeCollectionState {
  const FeeCollectionError(this.message);

  final String message;
}

class FeeCollectionBloc extends Bloc<FeeCollectionEvent, FeeCollectionState> {
  FeeCollectionBloc(
    this._dueRepository,
    this._additionalDueRepository,
    this._paymentRepository,
  ) : super(const FeeCollectionInitial()) {
    on<LoadFeeCollectionData>(_load);
    on<CollectStudentFeePayment>(_collect);
    on<CancelStudentFeePayment>(_cancel);
  }

  final MonthlyFeeDueRepository _dueRepository;
  final StudentAdditionalChargeDueRepository _additionalDueRepository;
  final FeePaymentRepository _paymentRepository;

  Future<void> _load(
    LoadFeeCollectionData event,
    Emitter<FeeCollectionState> emit,
  ) async {
    emit(const FeeCollectionLoading());
    try {
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final payments = await _paymentRepository.getPayments(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final additional = event.studentId == null
          ? <StudentAdditionalChargeDueEntity>[]
          : await _additionalDueRepository.getStudentDues(
              event.studentId!,
              academicSession: event.academicSession,
            );
      emit(
        FeeCollectionLoaded(
          dues: dues,
          payments: payments,
          additionalChargeDues: additional,
        ),
      );
    } catch (error) {
      emit(FeeCollectionError(_message(error)));
    }
  }

  Future<void> _collect(
    CollectStudentFeePayment event,
    Emitter<FeeCollectionState> emit,
  ) async {
    emit(const FeeCollectionLoading());
    try {
      final payment = await _paymentRepository.collectPayment(
        academicSession: event.academicSession,
        studentId: event.studentId,
        studentName: event.studentName,
        admissionNo: event.admissionNo,
        paymentDate: event.paymentDate,
        method: event.method,
        referenceNumber: event.referenceNumber,
        amount: event.amount,
        dueIds: event.dueIds,
        additionalChargeDueIds: event.additionalChargeDueIds,
        notes: event.notes,
      );

      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final payments = await _paymentRepository.getPayments(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final additional = await _additionalDueRepository.getStudentDues(
        event.studentId,
        academicSession: event.academicSession,
      );

      emit(
        FeeCollectionLoaded(
          dues: dues,
          payments: payments,
          additionalChargeDues: additional,
          latestPayment: payment,
          message: 'Payment collected. Receipt: ${payment.receiptNumber}',
        ),
      );
    } catch (error) {
      emit(FeeCollectionError(_message(error)));
    }
  }

  Future<void> _cancel(
    CancelStudentFeePayment event,
    Emitter<FeeCollectionState> emit,
  ) async {
    emit(const FeeCollectionLoading());
    try {
      await _paymentRepository.cancelPayment(
        paymentId: event.paymentId,
        reason: event.reason,
      );

      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final payments = await _paymentRepository.getPayments(
        academicSession: event.academicSession,
        studentId: event.studentId,
      );
      final additional = await _additionalDueRepository.getStudentDues(
        event.studentId,
        academicSession: event.academicSession,
      );

      emit(
        FeeCollectionLoaded(
          dues: dues,
          payments: payments,
          additionalChargeDues: additional,
          message: 'Payment cancelled successfully.',
        ),
      );
    } catch (error) {
      emit(FeeCollectionError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
