import 'package:equatable/equatable.dart';

import '../../domain/entities/system_health_entity.dart';

sealed class SystemHealthState extends Equatable {
  const SystemHealthState();

  @override
  List<Object?> get props => const [];
}

class SystemHealthInitial extends SystemHealthState {
  const SystemHealthInitial();
}

class SystemHealthLoading extends SystemHealthState {
  const SystemHealthLoading();
}

class SystemHealthLoaded extends SystemHealthState {
  const SystemHealthLoaded(this.health);

  final SystemHealthEntity health;

  @override
  List<Object?> get props => [health];
}

class SystemHealthFailure extends SystemHealthState {
  const SystemHealthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
