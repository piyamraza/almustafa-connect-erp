import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_backup_restore.dart';
import 'backup_event.dart';
import 'backup_state.dart';

class BackupBloc extends Bloc<BackupEvent, BackupState> {
  BackupBloc({
    required this._getData,
    required RequestBackup requestBackup,
    required this._requestRestore,
  }) : _requestBackup = requestBackup,
       super(const BackupInitial()) {
    on<LoadBackupData>(_load);
    on<CreateBackupRequested>(_backup);
    on<CreateRestoreRequestRequested>(_restore);
  }

  final GetBackupRestoreData _getData;
  final RequestBackup _requestBackup;
  final RequestRestore _requestRestore;

  Future<void> _load(LoadBackupData event, Emitter<BackupState> emit) async {
    emit(const BackupLoading());
    await _reload(emit);
  }

  Future<void> _backup(
    CreateBackupRequested event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _requestBackup(event.requestedBy, event.notes);
      await _reload(emit, message: 'Backup request submitted.');
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }

  Future<void> _restore(
    CreateRestoreRequestRequested event,
    Emitter<BackupState> emit,
  ) async {
    try {
      await _requestRestore(event.request);
      await _reload(emit, message: 'Restore request submitted.');
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }

  Future<void> _reload(Emitter<BackupState> emit, {String? message}) async {
    try {
      final data = await _getData();
      emit(
        BackupLoaded(
          backups: data.backups,
          restoreRequests: data.restoreRequests,
          message: message,
        ),
      );
    } catch (error) {
      emit(BackupFailure('$error'));
    }
  }
}
