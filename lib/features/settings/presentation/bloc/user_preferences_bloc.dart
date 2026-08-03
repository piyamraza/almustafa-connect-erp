import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/manage_user_preferences.dart';
import 'user_preferences_event.dart';
import 'user_preferences_state.dart';

class UserPreferencesBloc
    extends Bloc<UserPreferencesEvent, UserPreferencesState> {
  UserPreferencesBloc({
    required this._getPreferences,
    required this._savePreferences,
  }) : super(const UserPreferencesInitial()) {
    on<LoadUserPreferences>(_load);
    on<SaveUserPreferencesRequested>(_save);
  }

  final GetUserPreferences _getPreferences;
  final SaveUserPreferences _savePreferences;

  Future<void> _load(
    LoadUserPreferences event,
    Emitter<UserPreferencesState> emit,
  ) async {
    emit(const UserPreferencesLoading());

    try {
      emit(
        UserPreferencesLoaded(preferences: await _getPreferences(event.userId)),
      );
    } catch (error) {
      emit(UserPreferencesFailure(_message(error)));
    }
  }

  Future<void> _save(
    SaveUserPreferencesRequested event,
    Emitter<UserPreferencesState> emit,
  ) async {
    emit(UserPreferencesLoaded(preferences: event.preferences, isSaving: true));

    try {
      await _savePreferences(event.preferences);

      emit(
        UserPreferencesLoaded(
          preferences: event.preferences,
          message: 'Preferences saved successfully.',
        ),
      );
    } catch (error) {
      emit(UserPreferencesFailure(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
