import 'package:equatable/equatable.dart';

import '../../domain/entities/payroll_profile_entity.dart';
import '../../domain/entities/payroll_record_entity.dart';

sealed class PayrollState extends Equatable {
  const PayrollState();

  @override
  List<Object?> get props => const [];
}

class PayrollInitial extends PayrollState {
  const PayrollInitial();
}

class PayrollLoading extends PayrollState {
  const PayrollLoading();
}

class PayrollLoaded extends PayrollState {
  const PayrollLoaded({
    required this.profiles,
    required this.records,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<PayrollProfileEntity> profiles;
  final List<PayrollRecordEntity> records;
  final bool isProcessing;
  final String? message;
  final String? error;

  PayrollLoaded copyWith({
    List<PayrollProfileEntity>? profiles,
    List<PayrollRecordEntity>? records,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) => PayrollLoaded(
    profiles: profiles ?? this.profiles,
    records: records ?? this.records,
    isProcessing: isProcessing ?? this.isProcessing,
    message: clearMessages ? null : message ?? this.message,
    error: clearMessages ? null : error ?? this.error,
  );

  @override
  List<Object?> get props => [profiles, records, isProcessing, message, error];
}

class PayrollFailure extends PayrollState {
  const PayrollFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
