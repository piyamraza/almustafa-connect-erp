import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/audit_configuration_repository.dart';
import 'audit_configuration_event.dart';
import 'audit_configuration_state.dart';

class AuditConfigurationBloc
    extends Bloc<AuditConfigurationEvent, AuditConfigurationState> {
  AuditConfigurationBloc(this._repository)
    : super(const AuditConfigurationInitial()) {
    on<LoadAuditConfiguration>(_onLoad);
    on<ChangeAuditLogLevel>(_onChangeLevel);
  }

  final AuditConfigurationRepository _repository;

  Future<void> _onLoad(
    LoadAuditConfiguration event,
    Emitter<AuditConfigurationState> emit,
  ) async {
    emit(const AuditConfigurationLoading());

    try {
      final configuration = await _repository.getConfiguration();

      emit(AuditConfigurationLoaded(configuration: configuration));
    } catch (error) {
      emit(
        AuditConfigurationFailure(
          'Unable to load audit logging settings: $error',
        ),
      );
    }
  }

  Future<void> _onChangeLevel(
    ChangeAuditLogLevel event,
    Emitter<AuditConfigurationState> emit,
  ) async {
    final currentState = state;

    if (currentState is! AuditConfigurationLoaded ||
        currentState.isSaving ||
        currentState.configuration.level == event.level) {
      return;
    }

    final updatedConfiguration = currentState.configuration.copyWith(
      level: event.level,
      updatedAt: DateTime.now(),
    );

    emit(
      currentState.copyWith(
        configuration: updatedConfiguration,
        isSaving: true,
        clearMessage: true,
      ),
    );

    try {
      await _repository.saveConfiguration(updatedConfiguration);

      emit(
        AuditConfigurationLoaded(
          configuration: updatedConfiguration,
          message: 'Audit logging level updated successfully.',
        ),
      );
    } catch (error) {
      emit(
        currentState.copyWith(
          isSaving: false,
          message: 'Unable to update audit logging level: $error',
        ),
      );
    }
  }
}
