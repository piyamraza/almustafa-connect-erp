import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_teacher_workloads.dart';
import 'teacher_workload_event.dart';
import 'teacher_workload_state.dart';

class TeacherWorkloadBloc
    extends Bloc<TeacherWorkloadEvent, TeacherWorkloadState> {
  TeacherWorkloadBloc(this._getTeacherWorkloads)
    : super(const TeacherWorkloadInitial()) {
    on<LoadTeacherWorkloadEvent>(_onLoad);
  }

  final GetTeacherWorkloads _getTeacherWorkloads;

  Future<void> _onLoad(
    LoadTeacherWorkloadEvent event,
    Emitter<TeacherWorkloadState> emit,
  ) async {
    emit(const TeacherWorkloadLoading());

    try {
      final report = await _getTeacherWorkloads(
        branchId: event.branchId,
        academicSession: event.academicSession,
      );
      emit(TeacherWorkloadLoaded(report));
    } catch (error) {
      emit(TeacherWorkloadError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Invalid argument: ', '');
}
