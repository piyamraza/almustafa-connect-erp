import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_timetable_configuration.dart';
import '../../domain/usecases/save_timetable_configuration.dart';
import 'timetable_configuration_event.dart';
import 'timetable_configuration_state.dart';

class TimetableConfigurationBloc
    extends Bloc<TimetableConfigurationEvent, TimetableConfigurationState> {
  TimetableConfigurationBloc(
    this._getTimetableConfiguration,
    this._saveTimetableConfiguration,
  ) : super(const TimetableConfigurationInitial()) {
    on<LoadTimetableConfigurationEvent>(_onLoad);
    on<SaveTimetableConfigurationEvent>(_onSave);
  }

  final GetTimetableConfiguration _getTimetableConfiguration;
  final SaveTimetableConfiguration _saveTimetableConfiguration;

  Future<void> _onLoad(
    LoadTimetableConfigurationEvent event,
    Emitter<TimetableConfigurationState> emit,
  ) async {
    emit(const TimetableConfigurationLoading());

    try {
      final configuration = await _getTimetableConfiguration(
        branchId: event.branchId,
        academicSession: event.academicSession,
      );

      if (configuration == null) {
        emit(
          TimetableConfigurationEmpty(
            branchId: event.branchId,
            academicSession: event.academicSession,
          ),
        );
        return;
      }

      emit(TimetableConfigurationLoaded(configuration: configuration));
    } catch (error) {
      emit(TimetableConfigurationError(_message(error)));
    }
  }

  Future<void> _onSave(
    SaveTimetableConfigurationEvent event,
    Emitter<TimetableConfigurationState> emit,
  ) async {
    emit(const TimetableConfigurationLoading());

    try {
      await _saveTimetableConfiguration(event.configuration);

      final savedConfiguration = await _getTimetableConfiguration(
        branchId: event.configuration.branchId,
        academicSession: event.configuration.academicSession,
      );

      emit(
        TimetableConfigurationLoaded(
          configuration: savedConfiguration ?? event.configuration,
          successMessage: 'Timetable configuration saved successfully.',
        ),
      );
    } catch (error) {
      emit(TimetableConfigurationError(_message(error)));
    }
  }

  String _message(Object error) {
    return error
        .toString()
        .replaceFirst('StateError: ', '')
        .replaceFirst('Invalid argument(s): ', '');
  }
}
