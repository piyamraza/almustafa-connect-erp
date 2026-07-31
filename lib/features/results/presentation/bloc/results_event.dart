import 'package:equatable/equatable.dart';

sealed class ResultsEvent extends Equatable {
  const ResultsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadPublishedResults extends ResultsEvent {
  const LoadPublishedResults();
}

class RefreshPublishedResults extends ResultsEvent {
  const RefreshPublishedResults();
}

class FilterResultsBySession extends ResultsEvent {
  const FilterResultsBySession(this.academicSession);

  final String? academicSession;

  @override
  List<Object?> get props => [academicSession];
}

class FilterResultsByExam extends ResultsEvent {
  const FilterResultsByExam(this.examId);

  final String? examId;

  @override
  List<Object?> get props => [examId];
}

class FilterResultsByClass extends ResultsEvent {
  const FilterResultsByClass(this.classId);

  final String? classId;

  @override
  List<Object?> get props => [classId];
}

class FilterResultsBySection extends ResultsEvent {
  const FilterResultsBySection(this.sectionId);

  final String? sectionId;

  @override
  List<Object?> get props => [sectionId];
}

class FilterResultsByStudent extends ResultsEvent {
  const FilterResultsByStudent(this.studentId);

  final String? studentId;

  @override
  List<Object?> get props => [studentId];
}

class SearchPublishedResults extends ResultsEvent {
  const SearchPublishedResults(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
