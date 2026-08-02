import 'package:equatable/equatable.dart';

import '../../domain/entities/cashbook_entry_entity.dart';

sealed class CashbookState extends Equatable {
  const CashbookState();

  @override
  List<Object?> get props => const [];
}

class CashbookInitial extends CashbookState {
  const CashbookInitial();
}

class CashbookLoading extends CashbookState {
  const CashbookLoading();
}

class CashbookLoaded extends CashbookState {
  const CashbookLoaded({
    required this.entries,
    this.isProcessing = false,
    this.message,
    this.error,
  });

  final List<CashbookEntryEntity> entries;
  final bool isProcessing;
  final String? message;
  final String? error;

  int get totalIncome => entries
      .where((entry) => entry.entryType == CashbookEntryType.income)
      .fold<int>(0, (sum, entry) => sum + entry.amount);

  int get totalExpense => entries
      .where((entry) => entry.entryType == CashbookEntryType.expense)
      .fold<int>(0, (sum, entry) => sum + entry.amount);

  int get closingBalance => totalIncome - totalExpense;

  CashbookLoaded copyWith({
    List<CashbookEntryEntity>? entries,
    bool? isProcessing,
    String? message,
    String? error,
    bool clearMessages = false,
  }) {
    return CashbookLoaded(
      entries: entries ?? this.entries,
      isProcessing: isProcessing ?? this.isProcessing,
      message: clearMessages ? null : message ?? this.message,
      error: clearMessages ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [entries, isProcessing, message, error];
}

class CashbookFailure extends CashbookState {
  const CashbookFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
