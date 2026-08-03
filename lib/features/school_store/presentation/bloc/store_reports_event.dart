import 'package:equatable/equatable.dart';

sealed class StoreReportsEvent extends Equatable {
  const StoreReportsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadStoreReports extends StoreReportsEvent {
  const LoadStoreReports();
}
