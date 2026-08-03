import 'package:equatable/equatable.dart';

import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';

sealed class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => const [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

class BackupLoading extends BackupState {
  const BackupLoading();
}

class BackupLoaded extends BackupState {
  const BackupLoaded({
    required this.backups,
    required this.restoreRequests,
    this.processing = false,
    this.message,
  });

  final List<BackupRecordEntity> backups;
  final List<RestoreRequestEntity> restoreRequests;
  final bool processing;
  final String? message;

  @override
  List<Object?> get props => [backups, restoreRequests, processing, message];
}

class BackupFailure extends BackupState {
  const BackupFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
