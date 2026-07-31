import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_teacher_timetable.dart';
import 'teacher_timetable_event.dart';
import 'teacher_timetable_state.dart';

class TeacherTimetableBloc
    extends Bloc<TeacherTimetableEvent, TeacherTimetableState> {
  TeacherTimetableBloc(this._getTeacherTimetable)
    : super(const TeacherTimetableInitial()) {
    on<LoadTeacherTimetableEvent>(_onLoad);
  }

  final GetTeacherTimetable _getTeacherTimetable;

  Future<void> _onLoad(
    LoadTeacherTimetableEvent event,
    Emitter<TeacherTimetableState> emit,
  ) async {
    emit(const TeacherTimetableLoading());

    try {
      final entries = await _getTeacherTimetable(
        branchId: event.branchId,
        academicSession: event.academicSession,
        teacherId: event.teacherId,
      );
      emit(TeacherTimetableLoaded(entries));
    } catch (error) {
      emit(TeacherTimetableError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
