import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/academic_calendar_conflict_entity.dart';
import '../../domain/usecases/validate_academic_calendar.dart';

sealed class AcademicCalendarValidationEvent {
  const AcademicCalendarValidationEvent();
}

class RunAcademicCalendarValidation extends AcademicCalendarValidationEvent {
  const RunAcademicCalendarValidation(this.academicSession);

  final String academicSession;
}

sealed class AcademicCalendarValidationState {
  const AcademicCalendarValidationState();
}

class AcademicCalendarValidationInitial
    extends AcademicCalendarValidationState {
  const AcademicCalendarValidationInitial();
}

class AcademicCalendarValidationLoading
    extends AcademicCalendarValidationState {
  const AcademicCalendarValidationLoading();
}

class AcademicCalendarValidationLoaded extends AcademicCalendarValidationState {
  const AcademicCalendarValidationLoaded(this.result);

  final AcademicCalendarValidationResult result;
}

class AcademicCalendarValidationError extends AcademicCalendarValidationState {
  const AcademicCalendarValidationError(this.message);

  final String message;
}

class AcademicCalendarValidationBloc
    extends
        Bloc<AcademicCalendarValidationEvent, AcademicCalendarValidationState> {
  AcademicCalendarValidationBloc(this._validate)
    : super(const AcademicCalendarValidationInitial()) {
    on<RunAcademicCalendarValidation>(_run);
  }

  final ValidateAcademicCalendar _validate;

  Future<void> _run(
    RunAcademicCalendarValidation event,
    Emitter<AcademicCalendarValidationState> emit,
  ) async {
    emit(const AcademicCalendarValidationLoading());
    try {
      final result = await _validate(event.academicSession);
      emit(AcademicCalendarValidationLoaded(result));
    } catch (error) {
      emit(
        AcademicCalendarValidationError(
          error.toString().replaceFirst('StateError: ', ''),
        ),
      );
    }
  }
}
