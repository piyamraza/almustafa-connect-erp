import 'package:equatable/equatable.dart';

import 'results_export_event.dart';

sealed class ResultsExportState extends Equatable {
  const ResultsExportState();

  @override
  List<Object?> get props => const [];
}

class ResultsExportInitial extends ResultsExportState {
  const ResultsExportInitial();
}

class ResultsExportInProgress extends ResultsExportState {
  const ResultsExportInProgress(this.action);

  final ResultExportAction action;

  @override
  List<Object?> get props => [action];
}

class ResultsExportSuccess extends ResultsExportState {
  const ResultsExportSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ResultsExportFailure extends ResultsExportState {
  const ResultsExportFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
