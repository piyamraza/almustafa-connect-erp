import 'package:equatable/equatable.dart';

import '../../domain/entities/income_entry_entity.dart';

sealed class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => const [];
}

class LoadIncomeEntries extends IncomeEvent {
  const LoadIncomeEntries();
}

class SaveIncomeEntryRequested extends IncomeEvent {
  const SaveIncomeEntryRequested(this.entry);

  final IncomeEntryEntity entry;

  @override
  List<Object?> get props => [entry];
}

class ReverseIncomeEntryRequested extends IncomeEvent {
  const ReverseIncomeEntryRequested({
    required this.incomeEntryId,
    required this.reason,
  });

  final String incomeEntryId;
  final String reason;

  @override
  List<Object?> get props => [incomeEntryId, reason];
}

class SyncFeeIncomeRequested extends IncomeEvent {
  const SyncFeeIncomeRequested({required this.actorId, this.academicSession});

  final String actorId;
  final String? academicSession;

  @override
  List<Object?> get props => [actorId, academicSession];
}
