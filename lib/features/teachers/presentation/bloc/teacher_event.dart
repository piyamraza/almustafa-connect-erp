import 'package:equatable/equatable.dart';
import '../../domain/entities/teacher_entity.dart';

sealed class TeacherEvent extends Equatable { const TeacherEvent(); @override List<Object?> get props => []; }
class LoadTeachersEvent extends TeacherEvent { const LoadTeachersEvent(); }
class SaveTeacherEvent extends TeacherEvent { const SaveTeacherEvent(this.teacher); final TeacherEntity teacher; @override List<Object> get props => [teacher]; }
class DeleteTeacherEvent extends TeacherEvent { const DeleteTeacherEvent(this.id); final String id; @override List<Object> get props => [id]; }
