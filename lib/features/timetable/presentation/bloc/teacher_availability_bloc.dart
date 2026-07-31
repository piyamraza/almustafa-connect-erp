import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/teacher_availability_entity.dart';
import '../../domain/repositories/teacher_availability_repository.dart';

sealed class TeacherAvailabilityEvent {
  const TeacherAvailabilityEvent();
}

class LoadTeacherAvailabilities extends TeacherAvailabilityEvent {
  const LoadTeacherAvailabilities({
    required this.branchId,
    required this.academicSession,
  });

  final String branchId;
  final String academicSession;
}

class SaveTeacherAvailability extends TeacherAvailabilityEvent {
  const SaveTeacherAvailability(this.availability);
  final TeacherAvailabilityEntity availability;
}

class DeleteTeacherAvailability extends TeacherAvailabilityEvent {
  const DeleteTeacherAvailability({
    required this.id,
    required this.branchId,
    required this.academicSession,
  });

  final String id;
  final String branchId;
  final String academicSession;
}

sealed class TeacherAvailabilityState {
  const TeacherAvailabilityState();
}

class TeacherAvailabilityInitial extends TeacherAvailabilityState {
  const TeacherAvailabilityInitial();
}

class TeacherAvailabilityLoading extends TeacherAvailabilityState {
  const TeacherAvailabilityLoading();
}

class TeacherAvailabilityLoaded extends TeacherAvailabilityState {
  const TeacherAvailabilityLoaded(this.values, {this.message});

  final List<TeacherAvailabilityEntity> values;
  final String? message;
}

class TeacherAvailabilityError extends TeacherAvailabilityState {
  const TeacherAvailabilityError(this.message);
  final String message;
}

class TeacherAvailabilityBloc
    extends Bloc<TeacherAvailabilityEvent, TeacherAvailabilityState> {
  TeacherAvailabilityBloc(this._repository)
    : super(const TeacherAvailabilityInitial()) {
    on<LoadTeacherAvailabilities>(_load);
    on<SaveTeacherAvailability>(_save);
    on<DeleteTeacherAvailability>(_delete);
  }

  final TeacherAvailabilityRepository _repository;

  Future<void> _load(
    LoadTeacherAvailabilities event,
    Emitter<TeacherAvailabilityState> emit,
  ) async {
    await _reload(event.branchId, event.academicSession, emit);
  }

  Future<void> _save(
    SaveTeacherAvailability event,
    Emitter<TeacherAvailabilityState> emit,
  ) async {
    emit(const TeacherAvailabilityLoading());
    try {
      await _repository.saveAvailability(event.availability);
      await _reload(
        event.availability.branchId,
        event.availability.academicSession,
        emit,
        message: 'Teacher availability saved.',
      );
    } catch (error) {
      emit(TeacherAvailabilityError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteTeacherAvailability event,
    Emitter<TeacherAvailabilityState> emit,
  ) async {
    emit(const TeacherAvailabilityLoading());
    try {
      await _repository.deleteAvailability(event.id);
      await _reload(
        event.branchId,
        event.academicSession,
        emit,
        message: 'Teacher availability removed.',
      );
    } catch (error) {
      emit(TeacherAvailabilityError(_message(error)));
    }
  }

  Future<void> _reload(
    String branchId,
    String session,
    Emitter<TeacherAvailabilityState> emit, {
    String? message,
  }) async {
    emit(const TeacherAvailabilityLoading());
    try {
      final values = await _repository.getAvailabilities(
        branchId: branchId,
        academicSession: session,
      );
      emit(TeacherAvailabilityLoaded(values, message: message));
    } catch (error) {
      emit(TeacherAvailabilityError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
