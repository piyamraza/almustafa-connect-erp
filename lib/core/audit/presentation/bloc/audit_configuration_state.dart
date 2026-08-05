import 'package:equatable/equatable.dart';

import '../../domain/entities/audit_configuration_entity.dart';

sealed class AuditConfigurationState extends Equatable {
  const AuditConfigurationState();

  @override
  List<Object?> get props => [];
}

final class AuditConfigurationInitial extends AuditConfigurationState {
  const AuditConfigurationInitial();
}

final class AuditConfigurationLoading extends AuditConfigurationState {
  const AuditConfigurationLoading();
}

final class AuditConfigurationLoaded extends AuditConfigurationState {
  const AuditConfigurationLoaded({
    required this.configuration,
    this.isSaving = false,
    this.isDeleting = false,
    this.message,
  });

  final AuditConfigurationEntity configuration;
  final bool isSaving;
  final bool isDeleting;
  final String? message;

  AuditConfigurationLoaded copyWith({
    AuditConfigurationEntity? configuration,
    bool? isSaving,
    bool? isDeleting,
    String? message,
    bool clearMessage = false,
  }) {
    return AuditConfigurationLoaded(
      configuration: configuration ?? this.configuration,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    configuration,
    isSaving,
    isDeleting,
    message,
  ];
}

final class AuditConfigurationFailure extends AuditConfigurationState {
  const AuditConfigurationFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
