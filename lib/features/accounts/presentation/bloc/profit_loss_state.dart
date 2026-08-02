import 'package:equatable/equatable.dart';

import '../../domain/entities/monthly_profit_loss_entity.dart';

sealed class ProfitLossState extends Equatable {
  const ProfitLossState();

  @override
  List<Object?> get props => const [];
}

class ProfitLossInitial extends ProfitLossState {
  const ProfitLossInitial();
}

class ProfitLossLoading extends ProfitLossState {
  const ProfitLossLoading();
}

class ProfitLossLoaded extends ProfitLossState {
  const ProfitLossLoaded({
    required this.snapshots,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<MonthlyProfitLossEntity> snapshots;
  final bool isProcessing;
  final String? message;
  final String? error;

  ProfitLossLoaded copyWith({
    List<MonthlyProfitLossEntity>? snapshots,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return ProfitLossLoaded(
      snapshots: snapshots ?? this.snapshots,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [snapshots, isProcessing, message, error];
}

class ProfitLossFailure extends ProfitLossState {
  const ProfitLossFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
