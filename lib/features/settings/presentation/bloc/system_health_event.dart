import 'package:equatable/equatable.dart';

sealed class SystemHealthEvent extends Equatable {
  const SystemHealthEvent();

  @override
  List<Object?> get props => const [];
}

class LoadSystemHealth extends SystemHealthEvent {
  const LoadSystemHealth();
}

class RefreshSystemHealth extends SystemHealthEvent {
  const RefreshSystemHealth();
}
