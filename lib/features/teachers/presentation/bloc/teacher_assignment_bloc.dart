import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/teacher_assignment_entity.dart';
import '../../domain/repositories/teacher_assignment_repository.dart';

sealed class TeacherAssignmentEvent extends Equatable {
  const TeacherAssignmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeacherAssignments extends TeacherAssignmentEvent {
  const LoadTeacherAssignments();
}

class SaveTeacherAssignment extends TeacherAssignmentEvent {
  const SaveTeacherAssignment(this.assignment);

  final TeacherAssignmentEntity assignment;

  @override
  List<Object> get props => [assignment];
}

class DeleteTeacherAssignment extends TeacherAssignmentEvent {
  const DeleteTeacherAssignment(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

sealed class TeacherAssignmentState extends Equatable {
  const TeacherAssignmentState();

  @override
  List<Object?> get props => [];
}

class TeacherAssignmentInitial extends TeacherAssignmentState {
  const TeacherAssignmentInitial();
}

class TeacherAssignmentLoading extends TeacherAssignmentState {
  const TeacherAssignmentLoading();
}

class TeacherAssignmentLoaded extends TeacherAssignmentState {
  const TeacherAssignmentLoaded(this.assignments);

  final List<TeacherAssignmentEntity> assignments;

  @override
  List<Object> get props => [assignments];
}

class TeacherAssignmentError extends TeacherAssignmentState {
  const TeacherAssignmentError(this.message, {this.assignments = const []});

  final String message;
  final List<TeacherAssignmentEntity> assignments;

  @override
  List<Object> get props => [message, assignments];
}

class TeacherAssignmentBloc
    extends Bloc<TeacherAssignmentEvent, TeacherAssignmentState> {
  TeacherAssignmentBloc(this._repository)
    : super(const TeacherAssignmentInitial()) {
    on<LoadTeacherAssignments>(_load);
    on<SaveTeacherAssignment>(_save);
    on<DeleteTeacherAssignment>(_delete);
  }

  final TeacherAssignmentRepository _repository;

  Future<void> _load(
    LoadTeacherAssignments event,
    Emitter<TeacherAssignmentState> emit,
  ) async {
    emit(const TeacherAssignmentLoading());
    try {
      emit(TeacherAssignmentLoaded(await _repository.getAssignments()));
    } catch (error) {
      emit(TeacherAssignmentError(_message(error)));
    }
  }

  Future<void> _save(
    SaveTeacherAssignment event,
    Emitter<TeacherAssignmentState> emit,
  ) async {
    final assignments = _existingAssignments();
    emit(const TeacherAssignmentLoading());
    try {
      await _repository.saveAssignment(event.assignment);
      emit(TeacherAssignmentLoaded(await _repository.getAssignments()));
    } catch (error) {
      emit(TeacherAssignmentError(_message(error), assignments: assignments));
    }
  }

  Future<void> _delete(
    DeleteTeacherAssignment event,
    Emitter<TeacherAssignmentState> emit,
  ) async {
    final assignments = _existingAssignments();
    emit(const TeacherAssignmentLoading());
    try {
      await _repository.deleteAssignment(event.id);
      emit(TeacherAssignmentLoaded(await _repository.getAssignments()));
    } catch (error) {
      emit(TeacherAssignmentError(_message(error), assignments: assignments));
    }
  }

  List<TeacherAssignmentEntity> _existingAssignments() {
    final current = state;
    return switch (current) {
      TeacherAssignmentLoaded(:final assignments) => assignments,
      TeacherAssignmentError(:final assignments) => assignments,
      _ => const <TeacherAssignmentEntity>[],
    };
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
