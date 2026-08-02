import 'package:equatable/equatable.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_mark_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';

sealed class ExamMarksState extends Equatable {
  const ExamMarksState();

  @override
  List<Object?> get props => const [];
}

class ExamMarksInitial extends ExamMarksState {
  const ExamMarksInitial();
}

class ExamMarksLoading extends ExamMarksState {
  const ExamMarksLoading();
}

class ExamMarksFailure extends ExamMarksState {
  const ExamMarksFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ExamMarksLoaded extends ExamMarksState {
  const ExamMarksLoaded({
    required this.exams,
    this.subjectSetups = const [],
    this.students = const [],
    this.marks = const [],
    this.selectedExamId,
    this.selectedClassId,
    this.selectedSectionId,
    this.selectedSubjectSetupId,
    this.searchQuery = '',
    this.isLoading = false,
    this.isSaving = false,
    this.successMessage,
    this.errorMessage,
  });

  final List<ExamEntity> exams;
  final List<ExamSubjectSetupEntity> subjectSetups;
  final List<StudentEntity> students;
  final List<ExamMarkEntity> marks;
  final String? selectedExamId;
  final String? selectedClassId;
  final String? selectedSectionId;
  final String? selectedSubjectSetupId;
  final String searchQuery;
  final bool isLoading;
  final bool isSaving;
  final String? successMessage;
  final String? errorMessage;

  List<ExamEntity> get availableExams {
    final values = exams.where((exam) => exam.isActive).toList(growable: false);
    return values..sort((first, second) => first.name.compareTo(second.name));
  }

  List<ExamSubjectSetupEntity> get availableClasses {
    final byName = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where((value) => value.isActive)) {
      byName.putIfAbsent(_normalise(setup.className), () => setup);
    }
    final values = byName.values.toList(growable: false);
    return values
      ..sort((first, second) => first.className.compareTo(second.className));
  }

  List<ExamSubjectSetupEntity> get availableSections {
    if (selectedClassId == null) return const [];
    final selectedClass = availableClasses
        .where((setup) => setup.classId == selectedClassId)
        .firstOrNull;
    if (selectedClass == null) return const [];
    final byName = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where(
      (value) =>
          value.isActive &&
          (value.classId == selectedClassId ||
              _normalise(value.className) ==
                  _normalise(selectedClass.className)),
    )) {
      byName.putIfAbsent(_normalise(setup.sectionName), () => setup);
    }
    final values = byName.values.toList(growable: false);
    return values..sort(
      (first, second) => first.sectionName.compareTo(second.sectionName),
    );
  }

  List<ExamSubjectSetupEntity> get availableSubjects {
    if (selectedClassId == null || selectedSectionId == null) return const [];
    final selectedClass = availableClasses
        .where((setup) => setup.classId == selectedClassId)
        .firstOrNull;
    final selectedSection = availableSections
        .where((setup) => setup.sectionId == selectedSectionId)
        .firstOrNull;
    if (selectedClass == null || selectedSection == null) return const [];
    final byName = <String, ExamSubjectSetupEntity>{};
    for (final setup in subjectSetups.where(
      (setup) =>
          setup.isActive &&
          (setup.classId == selectedClassId ||
              _normalise(setup.className) ==
                  _normalise(selectedClass.className)) &&
          (setup.sectionId == selectedSectionId ||
              _normalise(setup.sectionName) ==
                  _normalise(selectedSection.sectionName)),
    )) {
      byName.putIfAbsent(_normalise(setup.subjectName), () => setup);
    }
    final values = byName.values.toList(growable: false);
    return values..sort(
      (first, second) => first.subjectName.compareTo(second.subjectName),
    );
  }

  ExamSubjectSetupEntity? get selectedSubjectSetup {
    for (final setup in subjectSetups) {
      if (setup.id == selectedSubjectSetupId) return setup;
    }
    return null;
  }

  ExamEntity? get selectedExam {
    for (final exam in exams) {
      if (exam.id == selectedExamId) return exam;
    }
    return null;
  }

  ExamMarkEntity? markForStudent(String studentId) {
    for (final mark in marks) {
      if (mark.studentId == studentId) return mark;
    }
    return null;
  }

  List<StudentEntity> get visibleStudents {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return students;
    return students
        .where(
          (student) => [
            student.rollNumber,
            student.fullName,
            student.fatherName,
          ].join(' ').toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  static String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  ExamMarksLoaded copyWith({
    List<ExamEntity>? exams,
    List<ExamSubjectSetupEntity>? subjectSetups,
    List<StudentEntity>? students,
    List<ExamMarkEntity>? marks,
    String? selectedExamId,
    String? selectedClassId,
    String? selectedSectionId,
    String? selectedSubjectSetupId,
    String? searchQuery,
    bool? isLoading,
    bool? isSaving,
    bool clearClass = false,
    bool clearSection = false,
    bool clearSubject = false,
    bool clearMessages = false,
    String? successMessage,
    String? errorMessage,
  }) {
    return ExamMarksLoaded(
      exams: exams ?? this.exams,
      subjectSetups: subjectSetups ?? this.subjectSetups,
      students: students ?? this.students,
      marks: marks ?? this.marks,
      selectedExamId: selectedExamId ?? this.selectedExamId,
      selectedClassId: clearClass
          ? null
          : selectedClassId ?? this.selectedClassId,
      selectedSectionId: clearSection
          ? null
          : selectedSectionId ?? this.selectedSectionId,
      selectedSubjectSetupId: clearSubject
          ? null
          : selectedSubjectSetupId ?? this.selectedSubjectSetupId,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      successMessage:
          successMessage ?? (clearMessages ? null : this.successMessage),
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    exams,
    subjectSetups,
    students,
    marks,
    selectedExamId,
    selectedClassId,
    selectedSectionId,
    selectedSubjectSetupId,
    searchQuery,
    isLoading,
    isSaving,
    successMessage,
    errorMessage,
  ];
}
