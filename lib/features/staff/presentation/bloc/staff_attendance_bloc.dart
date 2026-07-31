import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_staff_attendance_by_date.dart';
import '../../domain/usecases/get_staff_attendance_by_date_range.dart';
import '../../domain/usecases/get_staff_attendance_by_staff.dart';
import '../../domain/usecases/save_staff_attendance.dart';
import 'staff_attendance_event.dart';
import 'staff_attendance_state.dart';

class StaffAttendanceBloc
    extends Bloc<StaffAttendanceEvent, StaffAttendanceState> {
  StaffAttendanceBloc({
    required this._getStaffAttendanceByDate,
    required this._getStaffAttendanceByStaff,
    required this._getStaffAttendanceByDateRange,
    required this._saveStaffAttendance,
  })  : super(const StaffAttendanceInitial()) {
    on<LoadStaffAttendanceByDateEvent>(
      _onLoadStaffAttendanceByDate,
    );
    on<LoadStaffAttendanceByStaffEvent>(
      _onLoadStaffAttendanceByStaff,
    );
    on<LoadStaffAttendanceByDateRangeEvent>(
      _onLoadStaffAttendanceByDateRange,
    );
    on<SaveStaffAttendanceEvent>(
      _onSaveStaffAttendance,
    );
  }

  final GetStaffAttendanceByDate _getStaffAttendanceByDate;
  final GetStaffAttendanceByStaff _getStaffAttendanceByStaff;
  final GetStaffAttendanceByDateRange _getStaffAttendanceByDateRange;
  final SaveStaffAttendance _saveStaffAttendance;

  Future<void> _onLoadStaffAttendanceByDate(
    LoadStaffAttendanceByDateEvent event,
    Emitter<StaffAttendanceState> emit,
  ) async {
    emit(const StaffAttendanceLoading());

    try {
      final records = await _getStaffAttendanceByDate(
        event.date,
      );

      emit(
        StaffAttendanceLoaded(
          records: records,
          selectedDate: event.date,
        ),
      );
    } catch (error) {
      emit(
        StaffAttendanceError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadStaffAttendanceByStaff(
    LoadStaffAttendanceByStaffEvent event,
    Emitter<StaffAttendanceState> emit,
  ) async {
    emit(const StaffAttendanceLoading());

    try {
      final records = await _getStaffAttendanceByStaff(
        staffId: event.staffId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        StaffAttendanceLoaded(
          records: records,
          staffId: event.staffId,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    } catch (error) {
      emit(
        StaffAttendanceError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadStaffAttendanceByDateRange(
    LoadStaffAttendanceByDateRangeEvent event,
    Emitter<StaffAttendanceState> emit,
  ) async {
    emit(const StaffAttendanceLoading());

    try {
      final records = await _getStaffAttendanceByDateRange(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(
        StaffAttendanceLoaded(
          records: records,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      );
    } catch (error) {
      emit(
        StaffAttendanceError(
          error.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveStaffAttendance(
    SaveStaffAttendanceEvent event,
    Emitter<StaffAttendanceState> emit,
  ) async {
    emit(const StaffAttendanceLoading());

    try {
      for (final record in event.records) {
        await _saveStaffAttendance(record);
      }

      final records = await _getStaffAttendanceByDate(
        event.date,
      );

      emit(
        StaffAttendanceLoaded(
          records: records,
          selectedDate: event.date,
          successMessage: 'Staff attendance saved successfully.',
        ),
      );
    } catch (error) {
      emit(
        StaffAttendanceError(
          error.toString(),
        ),
      );
    }
  }
}