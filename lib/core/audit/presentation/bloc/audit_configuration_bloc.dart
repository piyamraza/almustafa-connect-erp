import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/audit_configuration_repository.dart';
import '../../domain/repositories/audit_repository.dart';
import 'audit_configuration_event.dart';
import 'audit_configuration_state.dart';

class AuditConfigurationBloc
    extends Bloc<AuditConfigurationEvent, AuditConfigurationState> {
  AuditConfigurationBloc(
    this._configurationRepository,
    this._auditRepository,
  ) : super(const AuditConfigurationInitial()) {
    on<LoadAuditConfiguration>(_onLoad);
    on<ChangeAuditLogLevel>(_onChangeLevel);
    on<DeleteAllAuditLogs>(_onDeleteAllLogs);
  }

  final AuditConfigurationRepository _configurationRepository;
  final AuditRepository _auditRepository;

  Future<void> _onLoad(
    LoadAuditConfiguration event,
    Emitter<AuditConfigurationState> emit,
  ) async {
    emit(const AuditConfigurationLoading());

    try {
      final configuration =
          await _configurationRepository.getConfiguration();

      emit(
        AuditConfigurationLoaded(
          configuration: configuration,
        ),
      );
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
        currentState.isDeleting ||
        currentState.configuration.level == event.level) {
      return;
    }

    final updatedConfiguration =
        currentState.configuration.copyWith(
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
      await _configurationRepository.saveConfiguration(
        updatedConfiguration,
      );

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

  Future<void> _onDeleteAllLogs(
    DeleteAllAuditLogs event,
    Emitter<AuditConfigurationState> emit,
  ) async {
    final currentState = state;

    if (currentState is! AuditConfigurationLoaded ||
        currentState.isDeleting ||
        currentState.isSaving) {
      return;
    }

    emit(
      currentState.copyWith(
        isDeleting: true,
        clearMessage: true,
      ),
    );

    try {
      final deletedCount = await _auditRepository.deleteAllLogs();

      emit(
        currentState.copyWith(
          isDeleting: false,
          message: deletedCount == 0
              ? 'No audit logs were available to delete.'
              : '$deletedCount audit logs deleted successfully.',
        ),
      );
    } catch (error) {
      emit(
        currentState.copyWith(
          isDeleting: false,
          message: 'Unable to delete audit logs: $error',
        ),
      );
    }
  }
}
