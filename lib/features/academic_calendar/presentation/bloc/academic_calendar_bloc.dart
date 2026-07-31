import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/academic_calendar_event_entity.dart';
import '../../domain/repositories/academic_calendar_repository.dart';

sealed class AcademicCalendarEvent {
  const AcademicCalendarEvent();
}

class LoadAcademicCalendar extends AcademicCalendarEvent {
  const LoadAcademicCalendar({
    required this.academicSession,
    required this.month,
  });

  final String academicSession;
  final DateTime month;
}

class SaveAcademicCalendarEvent extends AcademicCalendarEvent {
  const SaveAcademicCalendarEvent(this.event);

  final AcademicCalendarEventEntity event;
}

class DeleteAcademicCalendarEvent extends AcademicCalendarEvent {
  const DeleteAcademicCalendarEvent(this.id);

  final String id;
}

sealed class AcademicCalendarState {
  const AcademicCalendarState();
}

class AcademicCalendarInitial extends AcademicCalendarState {
  const AcademicCalendarInitial();
}

class AcademicCalendarLoading extends AcademicCalendarState {
  const AcademicCalendarLoading();
}

class AcademicCalendarLoaded extends AcademicCalendarState {
  const AcademicCalendarLoaded({
    required this.events,
    required this.month,
    this.message,
  });

  final List<AcademicCalendarEventEntity> events;
  final DateTime month;
  final String? message;
}

class AcademicCalendarError extends AcademicCalendarState {
  const AcademicCalendarError(this.message);

  final String message;
}

class AcademicCalendarBloc
    extends Bloc<AcademicCalendarEvent, AcademicCalendarState> {
  AcademicCalendarBloc(this._repository)
    : super(const AcademicCalendarInitial()) {
    on<LoadAcademicCalendar>(_load);
    on<SaveAcademicCalendarEvent>(_save);
    on<DeleteAcademicCalendarEvent>(_delete);
  }

  final AcademicCalendarRepository _repository;
  String _session = '2026-2027';
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> _load(
    LoadAcademicCalendar event,
    Emitter<AcademicCalendarState> emit,
  ) async {
    _session = event.academicSession;
    _month = DateTime(event.month.year, event.month.month);
    await _reload(emit);
  }

  Future<void> _save(
    SaveAcademicCalendarEvent event,
    Emitter<AcademicCalendarState> emit,
  ) async {
    emit(const AcademicCalendarLoading());
    try {
      await _repository.saveEvent(event.event);
      await _reload(emit, message: 'Calendar event saved.');
    } catch (error) {
      emit(AcademicCalendarError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteAcademicCalendarEvent event,
    Emitter<AcademicCalendarState> emit,
  ) async {
    emit(const AcademicCalendarLoading());
    try {
      await _repository.deleteEvent(event.id);
      await _reload(emit, message: 'Calendar event deleted.');
    } catch (error) {
      emit(AcademicCalendarError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<AcademicCalendarState> emit, {
    String? message,
  }) async {
    emit(const AcademicCalendarLoading());
    try {
      final start = DateTime(_month.year, _month.month, 1);
      final end = DateTime(_month.year, _month.month + 1, 0);
      final events = await _repository.getEvents(
        academicSession: _session,
        startDate: start,
        endDate: end,
      );
      emit(
        AcademicCalendarLoaded(events: events, month: _month, message: message),
      );
    } catch (error) {
      emit(AcademicCalendarError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
