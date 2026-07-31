import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/timetable_version_entity.dart';
import '../../domain/usecases/manage_timetable_versions.dart';

sealed class TimetableVersionEvent {
  const TimetableVersionEvent();
}

class LoadTimetableVersions extends TimetableVersionEvent {
  const LoadTimetableVersions({
    required this.branchId,
    required this.academicSession,
  });

  final String branchId;
  final String academicSession;
}

class CreateTimetableDraft extends TimetableVersionEvent {
  const CreateTimetableDraft({
    required this.branchId,
    required this.academicSession,
    required this.name,
  });

  final String branchId;
  final String academicSession;
  final String name;
}

class PublishTimetableVersion extends TimetableVersionEvent {
  const PublishTimetableVersion(this.version);
  final TimetableVersionEntity version;
}

class ArchiveTimetableVersion extends TimetableVersionEvent {
  const ArchiveTimetableVersion(this.version);
  final TimetableVersionEntity version;
}

class RollbackTimetableVersion extends TimetableVersionEvent {
  const RollbackTimetableVersion(this.version);
  final TimetableVersionEntity version;
}

sealed class TimetableVersionState {
  const TimetableVersionState();
}

class TimetableVersionInitial extends TimetableVersionState {
  const TimetableVersionInitial();
}

class TimetableVersionLoading extends TimetableVersionState {
  const TimetableVersionLoading();
}

class TimetableVersionLoaded extends TimetableVersionState {
  const TimetableVersionLoaded(this.versions, {this.message});

  final List<TimetableVersionEntity> versions;
  final String? message;
}

class TimetableVersionError extends TimetableVersionState {
  const TimetableVersionError(this.message);
  final String message;
}

class TimetableVersionBloc
    extends Bloc<TimetableVersionEvent, TimetableVersionState> {
  TimetableVersionBloc(this._manager) : super(const TimetableVersionInitial()) {
    on<LoadTimetableVersions>(_load);
    on<CreateTimetableDraft>(_create);
    on<PublishTimetableVersion>(_publish);
    on<ArchiveTimetableVersion>(_archive);
    on<RollbackTimetableVersion>(_rollback);
  }

  final ManageTimetableVersions _manager;
  String? _branchId;
  String? _academicSession;

  Future<void> _load(
    LoadTimetableVersions event,
    Emitter<TimetableVersionState> emit,
  ) async {
    _branchId = event.branchId;
    _academicSession = event.academicSession;
    await _reload(emit);
  }

  Future<void> _create(
    CreateTimetableDraft event,
    Emitter<TimetableVersionState> emit,
  ) async {
    _branchId = event.branchId;
    _academicSession = event.academicSession;
    emit(const TimetableVersionLoading());
    try {
      await _manager.createDraft(
        branchId: event.branchId,
        academicSession: event.academicSession,
        name: event.name,
      );
      await _reload(emit, message: 'Draft version created.');
    } catch (error) {
      emit(TimetableVersionError(_message(error)));
    }
  }

  Future<void> _publish(
    PublishTimetableVersion event,
    Emitter<TimetableVersionState> emit,
  ) async {
    emit(const TimetableVersionLoading());
    try {
      await _manager.publish(event.version);
      await _reload(emit, message: 'Version published successfully.');
    } catch (error) {
      emit(TimetableVersionError(_message(error)));
    }
  }

  Future<void> _archive(
    ArchiveTimetableVersion event,
    Emitter<TimetableVersionState> emit,
  ) async {
    emit(const TimetableVersionLoading());
    try {
      await _manager.archive(event.version);
      await _reload(emit, message: 'Version archived.');
    } catch (error) {
      emit(TimetableVersionError(_message(error)));
    }
  }

  Future<void> _rollback(
    RollbackTimetableVersion event,
    Emitter<TimetableVersionState> emit,
  ) async {
    emit(const TimetableVersionLoading());
    try {
      await _manager.rollback(event.version);
      await _reload(
        emit,
        message: 'Selected version restored to the live timetable.',
      );
    } catch (error) {
      emit(TimetableVersionError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<TimetableVersionState> emit, {
    String? message,
  }) async {
    final branchId = _branchId;
    final session = _academicSession;
    if (branchId == null || session == null) return;

    emit(const TimetableVersionLoading());
    try {
      final versions = await _manager.getVersions(
        branchId: branchId,
        academicSession: session,
      );
      emit(TimetableVersionLoaded(versions, message: message));
    } catch (error) {
      emit(TimetableVersionError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
