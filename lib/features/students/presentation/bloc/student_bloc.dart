import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/student_repository.dart';
import 'student_event.dart';
import 'student_state.dart';

class StudentBloc extends Bloc<StudentEvent, StudentState> {
  final StudentRepository _repository;

  StudentBloc(this._repository) : super(const StudentInitial()) {
    on<LoadStudentsEvent>(_loadStudents);
    on<RefreshStudentsEvent>(_loadStudents);
    on<AddStudentEvent>(_addStudent);
on<UpdateStudentEvent>(_updateStudent);
    on<DeleteStudentEvent>(_deleteStudent);
  }

  Future<void> _loadStudents(
    StudentEvent event,
    Emitter<StudentState> emit,
  ) async {
    emit(const StudentLoading());

    try {
      final students = await _repository.getStudents();
      emit(StudentLoaded(students));
    } catch (e) {
      emit(StudentError(e.toString()));
    }
  }

  Future<void> _addStudent(
  AddStudentEvent event,
  Emitter<StudentState> emit,
) async {
  emit(const StudentLoading());

  try {
    await _repository.addStudent(event.student);

    final students = await _repository.getStudents();

    emit(StudentLoaded(students));
  } catch (e) {
    emit(StudentError(e.toString()));
  }
}
Future<void> _updateStudent(
  UpdateStudentEvent event,
  Emitter<StudentState> emit,
) async {
  emit(const StudentLoading());

  try {
    await _repository.updateStudent(event.student);

    final students = await _repository.getStudents();

    emit(StudentLoaded(students));
  } catch (e) {
    emit(StudentError(e.toString()));
  }
}
  Future<void> _deleteStudent(
  DeleteStudentEvent event,
  Emitter<StudentState> emit,
) async {
  emit(const StudentLoading());

  try {
    await _repository.deleteStudent(event.studentId);

    final students = await _repository.getStudents();

    emit(StudentLoaded(students));
  } catch (e) {
    emit(StudentError(e.toString()));
  }
}
}
