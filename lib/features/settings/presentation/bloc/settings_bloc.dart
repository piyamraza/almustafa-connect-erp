import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_settings.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required this._getSettings,
    required SaveSchoolSettings saveSettings,
  }) : _saveSettings = saveSettings,
       super(const SettingsInitial()) {
    on<LoadSettings>(_load);
    on<SaveSettingsRequested>(_save);
  }

  final GetSchoolSettings _getSettings;
  final SaveSchoolSettings _saveSettings;

  Future<void> _load(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(const SettingsLoading());

    try {
      emit(SettingsLoaded(settings: await _getSettings()));
    } catch (error) {
      emit(SettingsFailure(_message(error)));
    }
  }

  Future<void> _save(
    SaveSettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoaded(settings: event.settings, isSaving: true));

    try {
      await _saveSettings(event.settings);

      emit(
        SettingsLoaded(
          settings: event.settings,
          message: 'Settings saved successfully.',
        ),
      );
    } catch (error) {
      emit(SettingsFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
