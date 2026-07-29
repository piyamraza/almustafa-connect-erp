import '../../domain/entities/student_entity.dart';

import 'package:equatable/equatable.dart';

abstract class StudentEvent extends Equatable {
  const StudentEvent();

  @override
  List<Object?> get props => [];
}

class LoadStudentsEvent extends StudentEvent {
  const LoadStudentsEvent();
}

class RefreshStudentsEvent extends StudentEvent {
  const RefreshStudentsEvent();
}

class AddStudentEvent extends StudentEvent {
  const AddStudentEvent(this.student);

  final StudentEntity student;

  @override
  List<Object?> get props => [student];
}
class DeleteStudentEvent extends StudentEvent {
  const DeleteStudentEvent(this.studentId);

  final String studentId;

  @override
  List<Object?> get props => [studentId];
}
class UpdateStudentEvent extends StudentEvent {
  const UpdateStudentEvent(this.student);

  final StudentEntity student;

  @override
  List<Object?> get props => [student];
}