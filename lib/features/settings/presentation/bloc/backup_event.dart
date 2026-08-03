import 'package:equatable/equatable.dart';

import '../../domain/entities/restore_request_entity.dart';

sealed class BackupEvent extends Equatable {
  const BackupEvent();

  @override
  List<Object?> get props => const [];
}

class LoadBackupData extends BackupEvent {
  const LoadBackupData();
}

class CreateBackupRequested extends BackupEvent {
  const CreateBackupRequested(this.requestedBy, this.notes);

  final String requestedBy;
  final String notes;

  @override
  List<Object?> get props => [requestedBy, notes];
}

class CreateRestoreRequestRequested extends BackupEvent {
  const CreateRestoreRequestRequested(this.request);

  final RestoreRequestEntity request;

  @override
  List<Object?> get props => [request];
}
