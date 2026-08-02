import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_class_timetable_entry.dart';
import '../../domain/usecases/get_class_timetable.dart';
import '../../domain/usecases/save_class_timetable_entry.dart';
import 'class_timetable_event.dart';
import 'class_timetable_state.dart';

class ClassTimetableBloc
    extends Bloc<ClassTimetableEvent, ClassTimetableState> {
  ClassTimetableBloc(
    this._getClassTimetable,
    this._saveClassTimetableEntry,
    this._deleteClassTimetableEntry,
  ) : super(const ClassTimetableInitial()) {
    on<LoadClassTimetableEvent>(_onLoad);
    on<SaveClassTimetableEntryEvent>(_onSave);
    on<SaveClassTimetableEntriesEvent>(_onSaveMany);
    on<DeleteClassTimetableEntryEvent>(_onDelete);
  }

  final GetClassTimetable _getClassTimetable;
  final SaveClassTimetableEntry _saveClassTimetableEntry;
  final DeleteClassTimetableEntry _deleteClassTimetableEntry;

  Future<void> _onLoad(
    LoadClassTimetableEvent event,
    Emitter<ClassTimetableState> emit,
  ) async {
    emit(const ClassTimetableLoading());
    await _load(
      branchId: event.branchId,
      academicSession: event.academicSession,
      classId: event.classId,
      sectionId: event.sectionId,
      emit: emit,
    );
  }

  Future<void> _onSave(
    SaveClassTimetableEntryEvent event,
    Emitter<ClassTimetableState> emit,
  ) async {
    emit(const ClassTimetableLoading());

    try {
      await _saveClassTimetableEntry(event.entry);
      await _load(
        branchId: event.entry.branchId,
        academicSession: event.entry.academicSession,
        classId: event.entry.classId,
        sectionId: event.entry.sectionId,
        emit: emit,
        successMessage: 'Timetable period saved successfully.',
      );
    } catch (error) {
      emit(ClassTimetableError(_message(error)));
    }
  }

  Future<void> _onSaveMany(
    SaveClassTimetableEntriesEvent event,
    Emitter<ClassTimetableState> emit,
  ) async {
    if (event.entries.isEmpty) return;
    emit(const ClassTimetableLoading());

    try {
      for (final entry in event.entries) {
        await _saveClassTimetableEntry(entry);
      }
      final first = event.entries.first;
      await _load(
        branchId: first.branchId,
        academicSession: first.academicSession,
        classId: first.classId,
        sectionId: first.sectionId,
        emit: emit,
        successMessage:
            '${event.entries.length} Monday period(s) copied successfully.',
      );
    } catch (error) {
      emit(ClassTimetableError(_message(error)));
    }
  }

  Future<void> _onDelete(
    DeleteClassTimetableEntryEvent event,
    Emitter<ClassTimetableState> emit,
  ) async {
    emit(const ClassTimetableLoading());

    try {
      await _deleteClassTimetableEntry(event.entryId);
      await _load(
        branchId: event.branchId,
        academicSession: event.academicSession,
        classId: event.classId,
        sectionId: event.sectionId,
        emit: emit,
        successMessage: 'Timetable period removed successfully.',
      );
    } catch (error) {
      emit(ClassTimetableError(_message(error)));
    }
  }

  Future<void> _load({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
    required Emitter<ClassTimetableState> emit,
    String? successMessage,
  }) async {
    try {
      final entries = await _getClassTimetable(
        branchId: branchId,
        academicSession: academicSession,
        classId: classId,
        sectionId: sectionId,
      );

      emit(
        ClassTimetableLoaded(
          entries: entries,
          branchId: branchId,
          academicSession: academicSession,
          classId: classId,
          sectionId: sectionId,
          successMessage: successMessage,
        ),
      );
    } catch (error) {
      emit(ClassTimetableError(_message(error)));
    }
  }

  String _message(Object error) {
    return error
        .toString()
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
