import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/usecases/get_students_by_class_and_section.dart';
import '../../domain/entities/exam_mark_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/usecases/delete_exam_mark.dart';
import '../../domain/usecases/get_exam_marks.dart';
import '../../domain/usecases/get_exam_subject_setups_for_exam.dart';
import '../../domain/usecases/get_exams.dart';
import '../../domain/usecases/save_exam_marks.dart';
import 'exam_marks_event.dart';
import 'exam_marks_state.dart';

class ExamMarksBloc extends Bloc<ExamMarksEvent, ExamMarksState> {
  ExamMarksBloc({
    required GetExams getExams,
    required GetExamSubjectSetupsForExam getSubjectSetupsForExam,
    required GetStudentsByClassAndSection getStudentsByClassAndSection,
    required GetExamMarks getExamMarks,
    required SaveExamMarks saveExamMarks,
    required DeleteExamMark deleteExamMark,
  })  : _getExams = getExams,
        _getSubjectSetupsForExam = getSubjectSetupsForExam,
        _getStudentsByClassAndSection = getStudentsByClassAndSection,
        _getExamMarks = getExamMarks,
        _saveExamMarks = saveExamMarks,
        _deleteExamMark = deleteExamMark,
        super(const ExamMarksInitial()) {
    on<LoadMarksEntry>(_onLoad);
    on<RefreshMarksEntry>(_onRefresh);
    on<SelectMarksExam>(_onSelectExam);
    on<SelectMarksClass>(_onSelectClass);
    on<SelectMarksSection>(_onSelectSection);
    on<SelectMarksSubject>(_onSelectSubject);
    on<SearchMarksStudents>(_onSearch);
    on<SaveMarksEntry>(_onSave);
    on<DeleteExamMarkEntry>(_onDelete);
  }

  final GetExams _getExams;
  final GetExamSubjectSetupsForExam _getSubjectSetupsForExam;
  final GetStudentsByClassAndSection _getStudentsByClassAndSection;
  final GetExamMarks _getExamMarks;
  final SaveExamMarks _saveExamMarks;
  final DeleteExamMark _deleteExamMark;

  Future<void> _onLoad(
    LoadMarksEntry event,
    Emitter<ExamMarksState> emit,
  ) async {
    emit(const ExamMarksLoading());
    try {
      final exams = await _getExams();
      emit(ExamMarksLoaded(exams: exams));
    } catch (error) {
      emit(ExamMarksFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshMarksEntry event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded || current.selectedExamId == null) {
      await _onLoad(const LoadMarksEntry(), emit);
      return;
    }

    emit(current.copyWith(isLoading: true, clearMessages: true));
    try {
      final exams = await _getExams();
      final setups = await _getSubjectSetupsForExam(current.selectedExamId!);
      final classId = setups.any((setup) => setup.classId == current.selectedClassId)
          ? current.selectedClassId
          : null;
      final sectionId = classId != null &&
              setups.any(
                (setup) =>
                    setup.classId == classId &&
                    setup.sectionId == current.selectedSectionId,
              )
          ? current.selectedSectionId
          : null;
      final subjectSetupId = sectionId != null &&
              setups.any((setup) => setup.id == current.selectedSubjectSetupId)
          ? current.selectedSubjectSetupId
          : null;
      var refreshed = ExamMarksLoaded(
        exams: exams,
        subjectSetups: setups,
        selectedExamId: current.selectedExamId,
        selectedClassId: classId,
        selectedSectionId: sectionId,
        selectedSubjectSetupId: subjectSetupId,
        searchQuery: current.searchQuery,
        isLoading: true,
      );
      if (subjectSetupId == null) {
        emit(refreshed.copyWith(isLoading: false));
        return;
      }
      refreshed = await _loadRows(refreshed);
      emit(refreshed);
    } catch (error) {
      emit(current.copyWith(isLoading: false, errorMessage: _message(error), clearMessages: true));
    }
  }

  Future<void> _onSelectExam(
    SelectMarksExam event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;

    emit(current.copyWith(
      selectedExamId: event.examId,
      subjectSetups: const [],
      students: const [],
      marks: const [],
      clearClass: true,
      clearSection: true,
      clearSubject: true,
      isLoading: true,
      clearMessages: true,
    ));
    try {
      final setups = await _getSubjectSetupsForExam(event.examId);
      emit(current.copyWith(
        selectedExamId: event.examId,
        subjectSetups: setups,
        students: const [],
        marks: const [],
        clearClass: true,
        clearSection: true,
        clearSubject: true,
        isLoading: false,
        clearMessages: true,
      ));
    } catch (error) {
      emit(current.copyWith(
        isLoading: false,
        errorMessage: _message(error),
        clearMessages: true,
      ));
    }
  }

  void _onSelectClass(
    SelectMarksClass event,
    Emitter<ExamMarksState> emit,
  ) {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(current.copyWith(
      selectedClassId: event.classId,
      students: const [],
      marks: const [],
      clearSection: true,
      clearSubject: true,
      clearMessages: true,
    ));
  }

  void _onSelectSection(
    SelectMarksSection event,
    Emitter<ExamMarksState> emit,
  ) {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(current.copyWith(
      selectedSectionId: event.sectionId,
      students: const [],
      marks: const [],
      clearSubject: true,
      clearMessages: true,
    ));
  }

  Future<void> _onSelectSubject(
    SelectMarksSubject event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    ExamSubjectSetupEntity? selected;
    for (final setup in current.availableSubjects) {
      if (setup.id == event.subjectSetupId) {
        selected = setup;
        break;
      }
    }
    if (selected == null) {
      emit(current.copyWith(
        errorMessage: 'Select a configured subject first.',
        clearMessages: true,
      ));
      return;
    }

    final loading = current.copyWith(
      selectedSubjectSetupId: selected.id,
      students: const [],
      marks: const [],
      isLoading: true,
      clearMessages: true,
    );
    emit(loading);
    try {
      emit(await _loadRows(loading));
    } catch (error) {
      emit(current.copyWith(
        errorMessage: _message(error),
        clearMessages: true,
      ));
    }
  }

  void _onSearch(
    SearchMarksStudents event,
    Emitter<ExamMarksState> emit,
  ) {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(current.copyWith(searchQuery: event.query, clearMessages: true));
  }

  Future<void> _onSave(
    SaveMarksEntry event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    final validationMessage = _validateMarks(current, event.marks);
    if (validationMessage != null) {
      emit(current.copyWith(
        errorMessage: validationMessage,
        clearMessages: true,
      ));
      return;
    }

    emit(current.copyWith(isSaving: true, clearMessages: true));
    try {
      await _saveExamMarks(event.marks);
      emit(await _loadRows(
        current.copyWith(isSaving: true, clearMessages: true),
        successMessage: 'Marks saved successfully.',
      ));
    } catch (error) {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: _message(error),
        clearMessages: true,
      ));
    }
  }

  Future<void> _onDelete(
    DeleteExamMarkEntry event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(current.copyWith(isSaving: true, clearMessages: true));
    try {
      await _deleteExamMark(event.id);
      emit(await _loadRows(
        current.copyWith(isSaving: true, clearMessages: true),
        successMessage: 'Marks record deleted.',
      ));
    } catch (error) {
      emit(current.copyWith(
        isSaving: false,
        errorMessage: _message(error),
        clearMessages: true,
      ));
    }
  }

  Future<ExamMarksLoaded> _loadRows(
    ExamMarksLoaded state, {
    String? successMessage,
  }) async {
    final setup = state.selectedSubjectSetup;
    final exam = state.selectedExam;
    if (setup == null || exam == null) {
      throw StateError('Complete the exam, class, section and subject selection.');
    }
    final entryKey = ExamMarkEntity.entryKeyFor(
      examId: exam.id,
      classId: setup.classId,
      sectionId: setup.sectionId,
      subjectId: setup.subjectId,
    );
    final response = await Future.wait([
      _getStudentsByClassAndSection(
        classId: setup.classId,
        sectionId: setup.sectionId,
      ),
      _getExamMarks(entryKey),
    ]);
    final students = (response[0] as List<StudentEntity>)
        .where((student) => student.isActive)
        .toList(growable: false);
    students.sort(_compareStudents);
    final marks = response[1] as List<ExamMarkEntity>;
    return state.copyWith(
      students: students,
      marks: marks,
      isLoading: false,
      isSaving: false,
      successMessage: successMessage,
      clearMessages: successMessage == null,
    );
  }

  String? _validateMarks(
    ExamMarksLoaded state,
    List<ExamMarkEntity> marks,
  ) {
    final setup = state.selectedSubjectSetup;
    final exam = state.selectedExam;
    if (setup == null || exam == null) {
      return 'Select exam, class, section and subject before saving.';
    }
    if (marks.length != state.students.length) {
      return 'Enter marks for every student before saving.';
    }
    final studentIds = <String>{};
    final expectedEntryKey = ExamMarkEntity.entryKeyFor(
      examId: exam.id,
      classId: setup.classId,
      sectionId: setup.sectionId,
      subjectId: setup.subjectId,
    );
    for (final mark in marks) {
      if (!studentIds.add(mark.studentId)) {
        return 'Duplicate marks were entered for a student.';
      }
      if (mark.entryKey != expectedEntryKey || mark.examId != exam.id) {
        return 'Marks selection does not match the selected exam subject.';
      }
      if (mark.obtainedMarks < 0 || mark.obtainedMarks > setup.totalMarks) {
        return 'Marks must be between 0 and ${setup.totalMarks}.';
      }
      if (mark.isAbsent && mark.obtainedMarks != 0) {
        return 'Absent students must have zero marks.';
      }
    }
    return null;
  }

  int _compareStudents(StudentEntity first, StudentEntity second) {
    final firstRoll = int.tryParse(first.rollNumber.trim());
    final secondRoll = int.tryParse(second.rollNumber.trim());
    if (firstRoll != null && secondRoll != null) {
      return firstRoll.compareTo(secondRoll);
    }
    if (firstRoll != null) return -1;
    if (secondRoll != null) return 1;
    return first.rollNumber.compareTo(second.rollNumber);
  }

  String _message(Object error) {
    return error.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }
}
