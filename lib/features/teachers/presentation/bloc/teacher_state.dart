import 'package:equatable/equatable.dart';
import '../../domain/entities/teacher_entity.dart';

sealed class TeacherState extends Equatable { const TeacherState(); @override List<Object?> get props => []; }
class TeacherInitial extends TeacherState { const TeacherInitial(); }
class TeacherLoading extends TeacherState { const TeacherLoading(); }
class TeacherLoaded extends TeacherState { const TeacherLoaded(this.teachers); final List<TeacherEntity> teachers; @override List<Object> get props => [teachers]; }
class TeacherError extends TeacherState { const TeacherError(this.message); final String message; @override List<Object> get props => [message]; }
