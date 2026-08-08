import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc
    extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceBloc(this._repository)
      : super(const AttendanceInitial()) {
    on<LoadAttendanceEvent>(_loadAttendance);
    on<RefreshAttendanceEvent>(_loadAttendance);
    on<AddAttendanceEvent>(_addAttendance);
    on<UpdateAttendanceEvent>(_updateAttendance);
    on<SaveAttendanceBatchEvent>(_saveAttendanceBatch);
    on<DeleteAttendanceEvent>(_deleteAttendance);
    on<LoadAttendanceByDateEvent>(
      _loadAttendanceByDate,
    );
    on<LoadAttendanceByStudentEvent>(
      _loadAttendanceByStudent,
    );
  }

  Future<void> _saveAttendanceBatch(
    SaveAttendanceBatchEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      for (final attendance in event.additions) {
        await _repository.addAttendance(attendance);
      }
      for (final attendance in event.updates) {
        await _repository.updateAttendance(attendance);
      }

      final attendance = await _repository.getAttendance();
      emit(AttendanceBatchSaved(event.additions.length + event.updates.length));
      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _loadAttendance(
    AttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      final attendance =
          await _repository.getAttendance();

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _addAttendance(
    AddAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      await _repository.addAttendance(
        event.attendance,
      );

      final attendance =
          await _repository.getAttendance();

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _updateAttendance(
    UpdateAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      await _repository.updateAttendance(
        event.attendance,
      );

      emit(AttendanceUpdated(event.attendance));

      final attendance =
          await _repository.getAttendance();

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _deleteAttendance(
    DeleteAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      await _repository.deleteAttendance(
        event.attendanceId,
      );

      final attendance =
          await _repository.getAttendance();

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _loadAttendanceByDate(
    LoadAttendanceByDateEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      final attendance =
          await _repository.getAttendanceByDate(
        event.date,
      );

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _loadAttendanceByStudent(
    LoadAttendanceByStudentEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      final attendance =
          await _repository.getAttendanceByStudent(
        event.studentId,
      );

      emit(AttendanceLoaded(attendance));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }
}
