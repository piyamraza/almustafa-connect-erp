import 'package:equatable/equatable.dart';

sealed class CashbookEvent extends Equatable {
  const CashbookEvent();

  @override
  List<Object?> get props => const [];
}

class LoadCashbook extends CashbookEvent {
  const LoadCashbook();
}

class SyncCashbookRequested extends CashbookEvent {
  const SyncCashbookRequested({required this.actorId});

  final String actorId;

  @override
  List<Object?> get props => [actorId];
}
