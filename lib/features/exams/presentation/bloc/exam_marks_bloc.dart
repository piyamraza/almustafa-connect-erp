import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../students/domain/usecases/get_students_by_class_and_section.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/services/subject_component_exam_service.dart';
import '../../domain/entities/exam_mark_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/usecases/delete_exam_mark.dart';
import '../../domain/usecases/get_exam_marks.dart';
import '../../domain/usecases/get_exam_results.dart';
import '../../domain/usecases/get_exam_subject_setups_for_exam.dart';
import '../../domain/usecases/get_exams.dart';
import '../../domain/usecases/save_exam_marks.dart';
import 'exam_marks_event.dart';
import 'exam_marks_state.dart';

class ExamMarksBloc extends Bloc<ExamMarksEvent, ExamMarksState> {
  ExamMarksBloc({
    required this._getExams,
    required this._getSubjectSetupsForExam,
    required this._getStudentsByClassAndSection,
    required this._getExamMarks,
    required this._getExamResults,
    required this._saveExamMarks,
    required this._deleteExamMark,
    required this.componentService,
    required this.studentRepository,
    required this.academicStructureRepository,
  }) : super(const ExamMarksInitial()) {
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
  final GetExamResults _getExamResults;
  final SaveExamMarks _saveExamMarks;
  final DeleteExamMark _deleteExamMark;
  final SubjectComponentExamService componentService;
  final StudentRepository studentRepository;
  final AcademicStructureRepository academicStructureRepository;

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
      final setups = await componentService.expandSetups(
        await _getSubjectSetupsForExam(current.selectedExamId!),
      );
      final classId =
          setups.any((setup) => setup.classId == current.selectedClassId)
          ? current.selectedClassId
          : null;
      final sectionId =
          classId != null &&
              setups.any(
                (setup) =>
                    setup.classId == classId &&
                    setup.sectionId == current.selectedSectionId,
              )
          ? current.selectedSectionId
          : null;
      final subjectSetupId =
          sectionId != null &&
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
      emit(
        current.copyWith(
          isLoading: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _onSelectExam(
    SelectMarksExam event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;

    emit(
      current.copyWith(
        selectedExamId: event.examId,
        subjectSetups: const [],
        students: const [],
        marks: const [],
        clearClass: true,
        clearSection: true,
        clearSubject: true,
        isLoading: true,
        clearMessages: true,
      ),
    );
    try {
      final setups = await componentService.expandSetups(
        await _getSubjectSetupsForExam(event.examId),
      );
      emit(
        current.copyWith(
          selectedExamId: event.examId,
          subjectSetups: setups,
          students: const [],
          marks: const [],
          clearClass: true,
          clearSection: true,
          clearSubject: true,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isLoading: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  void _onSelectClass(SelectMarksClass event, Emitter<ExamMarksState> emit) {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(
      current.copyWith(
        selectedClassId: event.classId,
        students: const [],
        marks: const [],
        clearSection: true,
        clearSubject: true,
        clearMessages: true,
      ),
    );
  }

  void _onSelectSection(
    SelectMarksSection event,
    Emitter<ExamMarksState> emit,
  ) {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    emit(
      current.copyWith(
        selectedSectionId: event.sectionId,
        students: const [],
        marks: const [],
        clearSubject: true,
        clearMessages: true,
      ),
    );
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
      emit(
        current.copyWith(
          errorMessage: 'Select a configured subject first.',
          clearMessages: true,
        ),
      );
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
      emit(
        current.copyWith(errorMessage: _message(error), clearMessages: true),
      );
    }
  }

  void _onSearch(SearchMarksStudents event, Emitter<ExamMarksState> emit) {
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
      emit(
        current.copyWith(errorMessage: validationMessage, clearMessages: true),
      );
      return;
    }
    final lockedMessage = await _lockedResultsMessage(current);
    if (lockedMessage != null) {
      emit(current.copyWith(errorMessage: lockedMessage, clearMessages: true));
      return;
    }

    emit(current.copyWith(isSaving: true, clearMessages: true));
    try {
      await _saveExamMarks(event.marks);
      emit(
        await _loadRows(
          current.copyWith(isSaving: true, clearMessages: true),
          successMessage: 'Marks saved successfully.',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isSaving: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _onDelete(
    DeleteExamMarkEntry event,
    Emitter<ExamMarksState> emit,
  ) async {
    final current = state;
    if (current is! ExamMarksLoaded) return;
    final lockedMessage = await _lockedResultsMessage(current);
    if (lockedMessage != null) {
      emit(current.copyWith(errorMessage: lockedMessage, clearMessages: true));
      return;
    }
    emit(current.copyWith(isSaving: true, clearMessages: true));
    try {
      await _deleteExamMark(event.id);
      emit(
        await _loadRows(
          current.copyWith(isSaving: true, clearMessages: true),
          successMessage: 'Marks record deleted.',
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isSaving: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<ExamMarksLoaded> _loadRows(
    ExamMarksLoaded state, {
    String? successMessage,
  }) async {
    final setup = state.selectedSubjectSetup;
    final exam = state.selectedExam;
    if (setup == null || exam == null) {
      throw StateError(
        'Complete the exam, class, section and subject selection.',
      );
    }
    final entryKey = ExamMarkEntity.entryKeyFor(
      examId: exam.id,
      classId: setup.classId,
      sectionId: setup.sectionId,
      subjectId: setup.subjectId,
    );
    final locations = _studentLocations(state, setup);
    final response = await Future.wait<Object>([
      Future.wait(
        locations.map(
          (location) => _getStudentsByClassAndSection(
            classId: location.classId,
            sectionId: location.sectionId,
          ),
        ),
      ),
      _getExamMarks(entryKey),
    ]);
    final studentLists = response[0] as List<List<StudentEntity>>;
    final studentsById = <String, StudentEntity>{};
    for (final students in studentLists) {
      for (final student in students.where((student) => student.isActive)) {
        studentsById[student.id] = student;
      }
    }
    if (studentsById.isEmpty) {
      final fallbackStudents = await _loadStudentsByAcademicReferences(
        setup,
        locations,
      );
      for (final student in fallbackStudents) {
        studentsById[student.id] = student;
      }
    }
    final activeStudents = studentsById.values.toList(growable: false);
    activeStudents.sort(_compareStudents);
    final marks = response[1] as List<ExamMarkEntity>;
    return state.copyWith(
      students: activeStudents,
      marks: marks,
      isLoading: false,
      isSaving: false,
      successMessage: successMessage,
      clearMessages: successMessage == null,
    );
  }

  Future<List<StudentEntity>> _loadStudentsByAcademicReferences(
    ExamSubjectSetupEntity selectedSetup,
    List<({String classId, String sectionId})> locations,
  ) async {
    final response = await Future.wait<Object>([
      studentRepository.getStudents(),
      academicStructureRepository.getClasses(),
      academicStructureRepository.getSections(),
    ]);
    final students = response[0] as List<StudentEntity>;
    final classes = response[1] as List<AcademicClassEntity>;
    final sections = response[2] as List<SectionEntity>;

    final classReferences = <String>{
      _normalise(selectedSetup.className),
      for (final location in locations) _normalise(location.classId),
    };
    for (final academicClass in classes) {
      final id = _normalise(academicClass.id);
      final name = _normalise(academicClass.name);
      if (classReferences.contains(id) || classReferences.contains(name)) {
        classReferences.addAll([id, name]);
      }
    }

    final sectionReferences = <String>{
      _normalise(selectedSetup.sectionName),
      for (final location in locations) _normalise(location.sectionId),
    };
    for (final section in sections) {
      final classId = _normalise(section.classId);
      final id = _normalise(section.id);
      final name = _normalise(section.name);
      if (classReferences.contains(classId) &&
          (sectionReferences.contains(id) ||
              sectionReferences.contains(name))) {
        sectionReferences.addAll([id, name]);
      }
    }

    return students
        .where(
          (student) =>
              student.isActive &&
              classReferences.contains(_normalise(student.classId)) &&
              sectionReferences.contains(_normalise(student.sectionId)),
        )
        .toList(growable: false);
  }

  List<({String classId, String sectionId})> _studentLocations(
    ExamMarksLoaded state,
    ExamSubjectSetupEntity selectedSetup,
  ) {
    final locations = <String, ({String classId, String sectionId})>{};

    void add(String? classId, String? sectionId) {
      if (classId == null || sectionId == null) return;
      final cleanClassId = classId.trim();
      final cleanSectionId = sectionId.trim();
      if (cleanClassId.isEmpty || cleanSectionId.isEmpty) return;
      locations['$cleanClassId|$cleanSectionId'] = (
        classId: cleanClassId,
        sectionId: cleanSectionId,
      );
    }

    add(selectedSetup.classId, selectedSetup.sectionId);
    add(state.selectedClassId, state.selectedSectionId);

    final className = _normalise(selectedSetup.className);
    final sectionName = _normalise(selectedSetup.sectionName);
    for (final setup in state.subjectSetups) {
      if (setup.isActive &&
          _normalise(setup.className) == className &&
          _normalise(setup.sectionName) == sectionName) {
        add(setup.classId, setup.sectionId);
      }
    }

    return locations.values.toList(growable: false);
  }

  String _normalise(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  String? _validateMarks(ExamMarksLoaded state, List<ExamMarkEntity> marks) {
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

  Future<String?> _lockedResultsMessage(ExamMarksLoaded state) async {
    final exam = state.selectedExam;
    final setup = state.selectedSubjectSetup;
    if (exam == null || setup == null) return null;
    try {
      final results = await _getExamResults(exam.id);
      final hasLockedResult = results.any(
        (result) =>
            result.classId == setup.classId &&
            result.sectionId == setup.sectionId &&
            result.isLocked,
      );
      return hasLockedResult
          ? 'Marks are read-only because results for this class and section are locked.'
          : null;
    } catch (error) {
      return 'Marks could not be changed because the result lock status could not be verified: ${_message(error)}';
    }
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
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '');
  }
}
