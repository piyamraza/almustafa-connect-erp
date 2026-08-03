import 'package:equatable/equatable.dart';

import '../../domain/entities/store_report_entity.dart';

sealed class StoreReportsState extends Equatable {
  const StoreReportsState();

  @override
  List<Object?> get props => const [];
}

class StoreReportsInitial extends StoreReportsState {
  const StoreReportsInitial();
}

class StoreReportsLoading extends StoreReportsState {
  const StoreReportsLoading();
}

class StoreReportsLoaded extends StoreReportsState {
  const StoreReportsLoaded(this.report);

  final StoreReportEntity report;

  @override
  List<Object?> get props => [report];
}

class StoreReportsFailure extends StoreReportsState {
  const StoreReportsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
