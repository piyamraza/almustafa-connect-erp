import 'package:equatable/equatable.dart';

sealed class TeacherResultsEvent extends Equatable {
  const TeacherResultsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadTeacherResults extends TeacherResultsEvent {
  const LoadTeacherResults();
}

class RefreshTeacherResults extends TeacherResultsEvent {
  const RefreshTeacherResults();
}

class SelectTeacherForResults extends TeacherResultsEvent {
  const SelectTeacherForResults(this.teacherId);

  final String? teacherId;

  @override
  List<Object?> get props => [teacherId];
}

class FilterTeacherResultsBySession extends TeacherResultsEvent {
  const FilterTeacherResultsBySession(this.academicSession);

  final String? academicSession;

  @override
  List<Object?> get props => [academicSession];
}

class FilterTeacherResultsByExam extends TeacherResultsEvent {
  const FilterTeacherResultsByExam(this.examId);

  final String? examId;

  @override
  List<Object?> get props => [examId];
}
