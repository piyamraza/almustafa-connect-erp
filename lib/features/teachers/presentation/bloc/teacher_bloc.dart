import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/teacher_repository.dart';
import 'teacher_event.dart';
import 'teacher_state.dart';

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  TeacherBloc(this._repository) : super(const TeacherInitial()) { on<LoadTeachersEvent>(_load); on<SaveTeacherEvent>(_save); on<DeleteTeacherEvent>(_delete); }
  final TeacherRepository _repository;
  Future<void> _load(TeacherEvent event, Emitter<TeacherState> emit) async { emit(const TeacherLoading()); try { emit(TeacherLoaded(await _repository.getTeachers())); } catch (error) { emit(TeacherError(error.toString())); } }
  Future<void> _save(SaveTeacherEvent event, Emitter<TeacherState> emit) async { emit(const TeacherLoading()); try { await _repository.saveTeacher(event.teacher); emit(TeacherLoaded(await _repository.getTeachers())); } catch (error) { emit(TeacherError(error.toString())); } }
  Future<void> _delete(DeleteTeacherEvent event, Emitter<TeacherState> emit) async { emit(const TeacherLoading()); try { await _repository.deleteTeacher(event.id); emit(TeacherLoaded(await _repository.getTeachers())); } catch (error) { emit(TeacherError(error.toString())); } }
}
