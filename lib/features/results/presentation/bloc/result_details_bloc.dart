import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/usecases/get_student_by_id.dart';
import 'result_details_event.dart';
import 'result_details_state.dart';

class ResultDetailsBloc extends Bloc<ResultDetailsEvent, ResultDetailsState> {
  ResultDetailsBloc({required GetStudentById getStudentById})
      : _getStudentById = getStudentById,
        super(const ResultDetailsInitial()) {
    on<LoadResultDetails>(_onLoad);
  }

  final GetStudentById _getStudentById;

  Future<void> _onLoad(
    LoadResultDetails event,
    Emitter<ResultDetailsState> emit,
  ) async {
    emit(ResultDetailsLoading(event.result));
    try {
      final student = await _getStudentById(event.result.studentId);
      emit(ResultDetailsLoaded(result: event.result, student: student));
    } catch (error) {
      emit(ResultDetailsFailure(
        result: event.result,
        message: error
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('StateError: ', ''),
      ));
    }
  }
}
