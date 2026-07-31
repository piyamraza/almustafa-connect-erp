import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_mark_entity.dart';

sealed class ExamMarksEvent extends Equatable {
  const ExamMarksEvent();

  @override
  List<Object?> get props => const [];
}

class LoadMarksEntry extends ExamMarksEvent {
  const LoadMarksEntry();
}

class RefreshMarksEntry extends ExamMarksEvent {
  const RefreshMarksEntry();
}

class SelectMarksExam extends ExamMarksEvent {
  const SelectMarksExam(this.examId);

  final String examId;

  @override
  List<Object?> get props => [examId];
}

class SelectMarksClass extends ExamMarksEvent {
  const SelectMarksClass(this.classId);

  final String classId;

  @override
  List<Object?> get props => [classId];
}

class SelectMarksSection extends ExamMarksEvent {
  const SelectMarksSection(this.sectionId);

  final String sectionId;

  @override
  List<Object?> get props => [sectionId];
}

class SelectMarksSubject extends ExamMarksEvent {
  const SelectMarksSubject(this.subjectSetupId);

  final String subjectSetupId;

  @override
  List<Object?> get props => [subjectSetupId];
}

class SearchMarksStudents extends ExamMarksEvent {
  const SearchMarksStudents(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SaveMarksEntry extends ExamMarksEvent {
  const SaveMarksEntry(this.marks);

  final List<ExamMarkEntity> marks;

  @override
  List<Object?> get props => [marks];
}

class DeleteExamMarkEntry extends ExamMarksEvent {
  const DeleteExamMarkEntry(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
