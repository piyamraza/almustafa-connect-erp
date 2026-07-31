import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auto_timetable_generation_entity.dart';
import '../../domain/usecases/generate_auto_timetable.dart';

sealed class AutoTimetableEvent {
  const AutoTimetableEvent();
}

class PreviewAutoTimetable extends AutoTimetableEvent {
  const PreviewAutoTimetable(this.request);
  final AutoTimetableGenerationRequest request;
}

class SaveAutoTimetable extends AutoTimetableEvent {
  const SaveAutoTimetable();
}

sealed class AutoTimetableState {
  const AutoTimetableState();
}

class AutoTimetableInitial extends AutoTimetableState {
  const AutoTimetableInitial();
}

class AutoTimetableLoading extends AutoTimetableState {
  const AutoTimetableLoading();
}

class AutoTimetablePreviewReady extends AutoTimetableState {
  const AutoTimetablePreviewReady(this.request, this.result);
  final AutoTimetableGenerationRequest request;
  final AutoTimetableGenerationResult result;
}

class AutoTimetableSaved extends AutoTimetableState {
  const AutoTimetableSaved(this.result);
  final AutoTimetableGenerationResult result;
}

class AutoTimetableError extends AutoTimetableState {
  const AutoTimetableError(this.message);
  final String message;
}

class AutoTimetableBloc extends Bloc<AutoTimetableEvent, AutoTimetableState> {
  AutoTimetableBloc(this._generator) : super(const AutoTimetableInitial()) {
    on<PreviewAutoTimetable>(_preview);
    on<SaveAutoTimetable>(_save);
  }

  final GenerateAutoTimetable _generator;
  AutoTimetableGenerationRequest? _request;
  AutoTimetableGenerationResult? _result;

  Future<void> _preview(
    PreviewAutoTimetable event,
    Emitter<AutoTimetableState> emit,
  ) async {
    emit(const AutoTimetableLoading());
    try {
      final result = await _generator.preview(event.request);
      _request = event.request;
      _result = result;
      emit(AutoTimetablePreviewReady(event.request, result));
    } catch (error) {
      emit(AutoTimetableError(_message(error)));
    }
  }

  Future<void> _save(
    SaveAutoTimetable event,
    Emitter<AutoTimetableState> emit,
  ) async {
    final request = _request;
    final result = _result;
    if (request == null || result == null) {
      emit(const AutoTimetableError('Generate a preview first.'));
      return;
    }

    emit(const AutoTimetableLoading());
    try {
      await _generator.save(request, result);
      emit(AutoTimetableSaved(result));
    } catch (error) {
      emit(AutoTimetableError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Invalid argument: ', '');
}
