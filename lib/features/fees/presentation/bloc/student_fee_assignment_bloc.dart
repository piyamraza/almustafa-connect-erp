import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/student_fee_assignment_entity.dart';
import '../../domain/repositories/student_fee_assignment_repository.dart';

sealed class StudentFeeAssignmentEvent {
  const StudentFeeAssignmentEvent();
}

class LoadStudentFeeAssignments extends StudentFeeAssignmentEvent {
  const LoadStudentFeeAssignments({required this.academicSession});

  final String academicSession;
}

class SaveStudentFeeAssignment extends StudentFeeAssignmentEvent {
  const SaveStudentFeeAssignment(this.assignment);

  final StudentFeeAssignmentEntity assignment;
}

class DeleteStudentFeeAssignment extends StudentFeeAssignmentEvent {
  const DeleteStudentFeeAssignment(this.id);

  final String id;
}

sealed class StudentFeeAssignmentState {
  const StudentFeeAssignmentState();
}

class StudentFeeAssignmentInitial extends StudentFeeAssignmentState {
  const StudentFeeAssignmentInitial();
}

class StudentFeeAssignmentLoading extends StudentFeeAssignmentState {
  const StudentFeeAssignmentLoading();
}

class StudentFeeAssignmentLoaded extends StudentFeeAssignmentState {
  const StudentFeeAssignmentLoaded(this.assignments, {this.message});

  final List<StudentFeeAssignmentEntity> assignments;
  final String? message;
}

class StudentFeeAssignmentError extends StudentFeeAssignmentState {
  const StudentFeeAssignmentError(this.message);

  final String message;
}

class StudentFeeAssignmentBloc
    extends Bloc<StudentFeeAssignmentEvent, StudentFeeAssignmentState> {
  StudentFeeAssignmentBloc(this._repository)
    : super(const StudentFeeAssignmentInitial()) {
    on<LoadStudentFeeAssignments>(_load);
    on<SaveStudentFeeAssignment>(_save);
    on<DeleteStudentFeeAssignment>(_delete);
  }

  final StudentFeeAssignmentRepository _repository;
  String _session = '2026-2027';

  Future<void> _load(
    LoadStudentFeeAssignments event,
    Emitter<StudentFeeAssignmentState> emit,
  ) async {
    _session = event.academicSession;
    await _reload(emit);
  }

  Future<void> _save(
    SaveStudentFeeAssignment event,
    Emitter<StudentFeeAssignmentState> emit,
  ) async {
    emit(const StudentFeeAssignmentLoading());
    try {
      await _repository.saveAssignment(event.assignment);
      await _reload(emit, message: 'Student fee assignment saved.');
    } catch (error) {
      emit(StudentFeeAssignmentError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteStudentFeeAssignment event,
    Emitter<StudentFeeAssignmentState> emit,
  ) async {
    emit(const StudentFeeAssignmentLoading());
    try {
      await _repository.deleteAssignment(event.id);
      await _reload(emit, message: 'Student fee assignment removed.');
    } catch (error) {
      emit(StudentFeeAssignmentError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<StudentFeeAssignmentState> emit, {
    String? message,
  }) async {
    emit(const StudentFeeAssignmentLoading());
    try {
      final values = await _repository.getAssignments(
        academicSession: _session,
      );
      emit(StudentFeeAssignmentLoaded(values, message: message));
    } catch (error) {
      emit(StudentFeeAssignmentError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
