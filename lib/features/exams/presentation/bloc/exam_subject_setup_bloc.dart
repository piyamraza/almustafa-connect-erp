import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../academic_structure/domain/entities/academic_class_entity.dart';
import '../../../academic_structure/domain/entities/academic_subject_entity.dart';
import '../../../academic_structure/domain/entities/section_entity.dart';
import '../../../academic_structure/domain/repositories/academic_structure_repository.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../../domain/repositories/exam_mark_repository.dart';
import '../../domain/repositories/exam_subject_setup_repository.dart';
import '../../domain/usecases/create_exam_subject_setups.dart'
    as create_usecase;
import '../../domain/usecases/delete_exam_subject_setup.dart' as delete_usecase;
import '../../domain/usecases/get_exam_subject_setups.dart' as get_usecase;
import '../../domain/usecases/update_exam_subject_setup.dart' as update_usecase;
import 'exam_subject_setup_event.dart';
import 'exam_subject_setup_state.dart';

class ExamSubjectSetupBloc
    extends Bloc<ExamSubjectSetupEvent, ExamSubjectSetupState> {
  ExamSubjectSetupBloc({
    required this._getSetups,
    required this._createSetups,
    required this._updateSetup,
    required this._deleteSetup,
    required this._examRepository,
    required this._academicStructureRepository,
    required this._subjectSetupRepository,
    required this._markRepository,
  }) : super(const ExamSubjectSetupInitial()) {
    on<LoadExamSubjectSetups>(_load);
    on<RefreshExamSubjectSetups>(_refresh);
    on<CreateExamSubjectSetups>(_create);
    on<UpdateExamSubjectSetupEvent>(_update);
    on<DeleteExamSubjectSetupEvent>(_delete);
    on<FilterExamSubjectSetups>(_filter);
    on<LoadExamConfiguration>(_loadConfiguration);
    on<SaveExamConfiguration>(_saveConfiguration);
  }

  final get_usecase.GetExamSubjectSetups _getSetups;
  final create_usecase.CreateExamSubjectSetups _createSetups;
  final update_usecase.UpdateExamSubjectSetup _updateSetup;
  final delete_usecase.DeleteExamSubjectSetup _deleteSetup;
  final ExamRepository _examRepository;
  final AcademicStructureRepository _academicStructureRepository;
  final ExamSubjectSetupRepository _subjectSetupRepository;
  final ExamMarkRepository _markRepository;

  Future<void> _loadConfiguration(
    LoadExamConfiguration event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    emit(const ExamConfigurationLoading());
    try {
      final examId = event.exam?.id;
      final responses = await Future.wait<Object>([
        _academicStructureRepository.getClasses(),
        _academicStructureRepository.getSections(),
        _academicStructureRepository.getSubjects(),
        if (examId != null)
          _subjectSetupRepository.getSetupsForExam(examId)
        else
          Future<List<ExamSubjectSetupEntity>>.value(const []),
        if (examId != null)
          _markRepository.getMarksForExam(examId)
        else
          Future.value(const []),
      ]);
      final setups = responses[3] as List<ExamSubjectSetupEntity>;
      final marks = responses[4] as List<dynamic>;
      final protected = <String>{};
      for (final setup in setups) {
        if (marks.any(
          (mark) =>
              mark.classId == setup.classId &&
              mark.sectionId == setup.sectionId &&
              mark.subjectId == setup.subjectId,
        )) {
          protected.add(setup.uniqueKey);
        }
      }
      emit(
        ExamConfigurationLoaded(
          classes: (responses[0] as List<AcademicClassEntity>)
              .where((item) => item.isActive)
              .toList(growable: false),
          sections: (responses[1] as List<SectionEntity>)
              .where((item) => item.isActive)
              .toList(growable: false),
          subjects: (responses[2] as List<AcademicSubjectEntity>)
              .where((item) => item.isActive)
              .toList(growable: false),
          existingSetups: setups,
          protectedSetupKeys: protected,
        ),
      );
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  Future<void> _saveConfiguration(
    SaveExamConfiguration event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    if (event.setups.isEmpty) {
      emit(const ExamSubjectSetupError('Select at least one subject.'));
      return;
    }
    emit(const ExamConfigurationLoading());
    try {
      final existing = await _subjectSetupRepository.getSetupsForExam(
        event.exam.id,
      );
      final selectedKeys = event.setups.map((item) => item.uniqueKey).toSet();
      final removed = existing
          .where(
            (item) => item.isActive && !selectedKeys.contains(item.uniqueKey),
          )
          .toList(growable: false);
      if (removed.isNotEmpty) {
        final marks = await _markRepository.getMarksForExam(event.exam.id);
        final blocked =
            removed
                .where(
                  (setup) => marks.any(
                    (mark) =>
                        mark.classId == setup.classId &&
                        mark.sectionId == setup.sectionId &&
                        mark.subjectId == setup.subjectId,
                  ),
                )
                .map((item) => item.subjectName)
                .toSet()
                .toList()
              ..sort();
        if (blocked.isNotEmpty) {
          throw StateError(
            'Cannot deselect ${blocked.join(', ')} because marks already exist. Remove those marks explicitly first.',
          );
        }
      }
      if (event.isEditing) {
        await _examRepository.updateExam(event.exam);
      } else {
        await _examRepository.createExam(event.exam);
      }
      await _subjectSetupRepository.synchronizeExamSetups(
        examId: event.exam.id,
        selectedSetups: event.setups,
      );
      emit(const ExamConfigurationSaved());
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  Future<void> _load(
    LoadExamSubjectSetups event,
    Emitter<ExamSubjectSetupState> emit,
  ) {
    return _loadData(emit);
  }

  Future<void> _refresh(
    RefreshExamSubjectSetups event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    final previous = state;
    await _loadData(
      emit,
      query: previous is ExamSubjectSetupLoaded ? previous.query : '',
      examId: previous is ExamSubjectSetupLoaded ? previous.examId : null,
      classId: previous is ExamSubjectSetupLoaded ? previous.classId : null,
      sectionId: previous is ExamSubjectSetupLoaded ? previous.sectionId : null,
    );
  }

  Future<void> _create(
    CreateExamSubjectSetups event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    final previous = state;
    emit(const ExamSubjectSetupLoading());
    try {
      await _createSetups(event.setups);
      await _reload(emit, previous, 'Subject setup saved successfully.');
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  Future<void> _update(
    UpdateExamSubjectSetupEvent event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    final previous = state;
    emit(const ExamSubjectSetupLoading());
    try {
      await _updateSetup(event.setup);
      await _reload(emit, previous, 'Subject setup updated successfully.');
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteExamSubjectSetupEvent event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    final previous = state;
    emit(const ExamSubjectSetupLoading());
    try {
      await _deleteSetup(event.id);
      await _reload(emit, previous, 'Subject setup deleted successfully.');
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  Future<void> _filter(
    FilterExamSubjectSetups event,
    Emitter<ExamSubjectSetupState> emit,
  ) async {
    final current = state;
    if (current is! ExamSubjectSetupLoaded) {
      await _loadData(
        emit,
        query: event.query,
        examId: event.examId,
        classId: event.classId,
        sectionId: event.sectionId,
      );
      return;
    }
    emit(
      _loadedFrom(
        current.allSetups,
        current.exams,
        current.classes,
        current.sectionsByClass,
        current.subjectsByClassSection,
        query: event.query,
        examId: event.examId,
        classId: event.classId,
        sectionId: event.sectionId,
      ),
    );
  }

  Future<void> _reload(
    Emitter<ExamSubjectSetupState> emit,
    ExamSubjectSetupState previous,
    String message,
  ) {
    return _loadData(
      emit,
      query: previous is ExamSubjectSetupLoaded ? previous.query : '',
      examId: previous is ExamSubjectSetupLoaded ? previous.examId : null,
      classId: previous is ExamSubjectSetupLoaded ? previous.classId : null,
      sectionId: previous is ExamSubjectSetupLoaded ? previous.sectionId : null,
      showLoading: false,
      successMessage: message,
    );
  }

  Future<void> _loadData(
    Emitter<ExamSubjectSetupState> emit, {
    String query = '',
    String? examId,
    String? classId,
    String? sectionId,
    bool showLoading = true,
    String? successMessage,
  }) async {
    if (showLoading) emit(const ExamSubjectSetupLoading());
    try {
      final response = await Future.wait<Object>([
        _getSetups(),
        _examRepository.getExams(),
        _academicStructureRepository.getClasses(),
        _academicStructureRepository.getSections(),
        _academicStructureRepository.getSubjects(),
      ]);
      final setups = response[0] as List<ExamSubjectSetupEntity>;
      final exams = response[1] as List<ExamEntity>;
      final classes = response[2] as List<AcademicClassEntity>;
      final sections = response[3] as List<SectionEntity>;
      final subjects = response[4] as List<AcademicSubjectEntity>;
      final classNames = classes
          .where((value) => value.isActive)
          .map((value) => value.name)
          .toList(growable: false);
      classNames.sort();
      final sectionsByClass = _sectionsByClass(classes, sections);
      final subjectsByClassSection = _subjectsByClassSection(
        classes,
        sections,
        subjects,
      );
      emit(
        _loadedFrom(
          setups,
          exams,
          classNames,
          sectionsByClass,
          subjectsByClassSection,
          query: query,
          examId: examId,
          classId: classId,
          sectionId: sectionId,
          successMessage: successMessage,
        ),
      );
    } catch (error) {
      emit(ExamSubjectSetupError(_message(error)));
    }
  }

  ExamSubjectSetupLoaded _loadedFrom(
    List<ExamSubjectSetupEntity> all,
    List<ExamEntity> exams,
    List<String> classes,
    Map<String, List<String>> sectionsByClass,
    Map<String, List<String>> subjectsByClassSection, {
    required String query,
    String? examId,
    String? classId,
    String? sectionId,
    String? successMessage,
  }) {
    final needle = query.trim().toLowerCase();
    final visible = all
        .where(
          (setup) =>
              (examId == null || setup.examId == examId) &&
              (classId == null || setup.classId == classId) &&
              (sectionId == null || setup.sectionId == sectionId) &&
              (needle.isEmpty ||
                  [
                    setup.examName,
                    setup.academicSession,
                    setup.className,
                    setup.sectionName,
                    setup.subjectName,
                    setup.isActive ? 'active' : 'inactive',
                  ].join(' ').toLowerCase().contains(needle)),
        )
        .toList(growable: false);
    return ExamSubjectSetupLoaded(
      setups: visible,
      allSetups: all,
      exams: exams,
      classes: classes,
      sectionsByClass: sectionsByClass,
      subjectsByClassSection: subjectsByClassSection,
      query: query,
      examId: examId,
      classId: classId,
      sectionId: sectionId,
      successMessage: successMessage,
    );
  }

  Map<String, List<String>> _sectionsByClass(
    List<AcademicClassEntity> classes,
    List<SectionEntity> sections,
  ) {
    final classNames = {for (final value in classes) value.id: value.name};
    final result = <String, List<String>>{};
    for (final section in sections.where((value) => value.isActive)) {
      final className = classNames[section.classId];
      if (className == null) continue;
      result.putIfAbsent(className, () => []).add(section.name);
    }
    for (final values in result.values) {
      values.sort();
    }
    return result;
  }

  Map<String, List<String>> _subjectsByClassSection(
    List<AcademicClassEntity> classes,
    List<SectionEntity> sections,
    List<AcademicSubjectEntity> subjects,
  ) {
    final classNames = {for (final value in classes) value.id: value.name};
    final defaultSubjectsByClass = <String, List<String>>{};
    final subjectsBySection = <String, List<String>>{};
    for (final subject in subjects.where((value) => value.isActive)) {
      if (subject.sectionId == null) {
        defaultSubjectsByClass
            .putIfAbsent(subject.classId, () => [])
            .add(subject.name);
      } else {
        subjectsBySection
            .putIfAbsent(subject.sectionId!, () => [])
            .add(subject.name);
      }
    }
    for (final values in defaultSubjectsByClass.values) {
      values.sort();
    }
    for (final values in subjectsBySection.values) {
      values.sort();
    }

    final result = <String, List<String>>{};
    for (final section in sections.where((value) => value.isActive)) {
      final className = classNames[section.classId];
      final sectionSubjects = subjectsBySection[section.id];
      final defaultSubjects = defaultSubjectsByClass[section.classId];
      final effectiveSubjects = sectionSubjects?.isNotEmpty == true
          ? sectionSubjects
          : defaultSubjects;
      if (className == null || effectiveSubjects == null) continue;
      result['$className|${section.name}'] = effectiveSubjects;
    }
    return result;
  }

  String _message(Object error) {
    return error.toString().replaceFirst('StateError: ', '');
  }
}
