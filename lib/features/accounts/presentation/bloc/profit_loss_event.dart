import 'package:equatable/equatable.dart';

sealed class ProfitLossEvent extends Equatable {
  const ProfitLossEvent();

  @override
  List<Object?> get props => const [];
}

class LoadProfitLoss extends ProfitLossEvent {
  const LoadProfitLoss();
}

class GenerateProfitLossRequested extends ProfitLossEvent {
  const GenerateProfitLossRequested({
    required this.month,
    required this.actorId,
  });

  final DateTime month;
  final String actorId;

  @override
  List<Object?> get props => [month, actorId];
}
