import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_day_timetable.dart';
import 'day_timetable_event.dart';
import 'day_timetable_state.dart';

class DayTimetableBloc extends Bloc<DayTimetableEvent, DayTimetableState> {
  DayTimetableBloc(this._getDayTimetable) : super(const DayTimetableInitial()) {
    on<LoadDayTimetableEvent>(_onLoad);
  }

  final GetDayTimetable _getDayTimetable;

  Future<void> _onLoad(
    LoadDayTimetableEvent event,
    Emitter<DayTimetableState> emit,
  ) async {
    emit(const DayTimetableLoading());

    try {
      final entries = await _getDayTimetable(
        branchId: event.branchId,
        academicSession: event.academicSession,
        weekday: event.weekday,
      );
      emit(DayTimetableLoaded(entries));
    } catch (error) {
      emit(DayTimetableError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
