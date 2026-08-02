import 'package:equatable/equatable.dart';

import '../../domain/entities/income_entry_entity.dart';

sealed class IncomeState extends Equatable {
  const IncomeState();

  @override
  List<Object?> get props => const [];
}

class IncomeInitial extends IncomeState {
  const IncomeInitial();
}

class IncomeLoading extends IncomeState {
  const IncomeLoading();
}

class IncomeLoaded extends IncomeState {
  const IncomeLoaded({
    required this.entries,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<IncomeEntryEntity> entries;
  final bool isProcessing;
  final String? message;
  final String? error;

  int get activeTotal => entries
      .where((entry) => entry.isActive)
      .fold<int>(0, (sum, entry) => sum + entry.amount);

  IncomeLoaded copyWith({
    List<IncomeEntryEntity>? entries,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return IncomeLoaded(
      entries: entries ?? this.entries,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [entries, isProcessing, message, error];
}

class IncomeFailure extends IncomeState {
  const IncomeFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
