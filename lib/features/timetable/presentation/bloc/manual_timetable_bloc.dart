import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/class_timetable_entry_entity.dart';
import '../../domain/entities/manual_timetable_change_entity.dart';
import '../../domain/usecases/apply_manual_timetable_changes.dart';
import '../../domain/usecases/get_class_timetable.dart';

sealed class ManualTimetableEvent {
  const ManualTimetableEvent();
}

class LoadManualTimetable extends ManualTimetableEvent {
  const LoadManualTimetable({
    required this.branchId,
    required this.academicSession,
    required this.classId,
    required this.sectionId,
  });

  final String branchId;
  final String academicSession;
  final String classId;
  final String sectionId;
}

class SaveManualTimetable extends ManualTimetableEvent {
  const SaveManualTimetable(this.changes);

  final ManualTimetableChangeSet changes;
}

sealed class ManualTimetableState {
  const ManualTimetableState();
}

class ManualTimetableInitial extends ManualTimetableState {
  const ManualTimetableInitial();
}

class ManualTimetableLoading extends ManualTimetableState {
  const ManualTimetableLoading();
}

class ManualTimetableLoaded extends ManualTimetableState {
  const ManualTimetableLoaded(this.entries, {this.successMessage});

  final List<ClassTimetableEntryEntity> entries;
  final String? successMessage;
}

class ManualTimetableError extends ManualTimetableState {
  const ManualTimetableError(this.message);

  final String message;
}

class ManualTimetableBloc
    extends Bloc<ManualTimetableEvent, ManualTimetableState> {
  ManualTimetableBloc(this._getClassTimetable, this._applyChanges)
    : super(const ManualTimetableInitial()) {
    on<LoadManualTimetable>(_load);
    on<SaveManualTimetable>(_save);
  }

  final GetClassTimetable _getClassTimetable;
  final ApplyManualTimetableChanges _applyChanges;

  Future<void> _load(
    LoadManualTimetable event,
    Emitter<ManualTimetableState> emit,
  ) async {
    emit(const ManualTimetableLoading());
    try {
      final entries = await _getClassTimetable(
        branchId: event.branchId,
        academicSession: event.academicSession,
        classId: event.classId,
        sectionId: event.sectionId,
      );
      emit(ManualTimetableLoaded(entries));
    } catch (error) {
      emit(ManualTimetableError(_message(error)));
    }
  }

  Future<void> _save(
    SaveManualTimetable event,
    Emitter<ManualTimetableState> emit,
  ) async {
    emit(const ManualTimetableLoading());
    try {
      await _applyChanges(event.changes);
      final entries = await _getClassTimetable(
        branchId: event.changes.branchId,
        academicSession: event.changes.academicSession,
        classId: event.changes.classId,
        sectionId: event.changes.sectionId,
      );
      emit(
        ManualTimetableLoaded(
          entries,
          successMessage: 'Manual timetable changes saved successfully.',
        ),
      );
    } catch (error) {
      emit(ManualTimetableError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Invalid argument: ', '');
}
