import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../domain/data/default_admission_question_bank.dart';
import '../../domain/entities/admission_test_entities.dart';
import '../../domain/repositories/admission_test_repository.dart';
import '../../domain/services/admission_paper_generator.dart';
import 'admission_test_event.dart';
import 'admission_test_state.dart';

class AdmissionTestBloc extends Bloc<AdmissionTestEvent, AdmissionTestState> {
  AdmissionTestBloc(this._repository, this._generator)
    : super(const AdmissionTestInitial()) {
    on<LoadAdmissionTests>(_load);
    on<SaveAdmissionQuestion>(_saveQuestion);
    on<DeleteAdmissionQuestion>(_deleteQuestion);
    on<SaveAdmissionTemplate>(_saveTemplate);
    on<GenerateAdmissionPaper>(_generate);
    on<SaveCustomAdmissionPaper>(_saveCustomPaper);
    on<SaveAdmissionCandidate>(_saveCandidate);
  }
  final AdmissionTestRepository _repository;
  final AdmissionPaperGenerator _generator;
  Future<void> _load(
    LoadAdmissionTests event,
    Emitter<AdmissionTestState> emit,
  ) async {
    emit(const AdmissionTestLoading());
    try {
      final values = await Future.wait([
        _repository.getQuestions(),
        _repository.getTemplates(),
        _repository.getPapers(),
        _repository.getCandidates(),
      ]);
      final customQuestions = values[0] as List<AdmissionQuestionEntity>;
      final questions = [...defaultAdmissionQuestionBank(), ...customQuestions];
      var templates = values[1] as List<AdmissionPaperTemplateEntity>;
      if (templates.isEmpty) templates = defaultAdmissionTemplates();
      emit(
        AdmissionTestLoaded(
          questions: questions,
          templates: templates,
          papers: values[2] as List<AdmissionPaperEntity>,
          candidates: values[3] as List<AdmissionCandidateEntity>,
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not load admission tests: $e'));
    }
  }

  Future<void> _saveQuestion(
    SaveAdmissionQuestion event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    try {
      await _repository.saveQuestion(event.value);
      emit(
        s.copyWith(
          questions: [
            event.value,
            ...s.questions.where((q) => q.id != event.value.id),
          ],
          message: 'Question saved.',
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not save question: $e'));
    }
  }

  Future<void> _deleteQuestion(
    DeleteAdmissionQuestion event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    final target = s.questions.where((q) => q.id == event.id).firstOrNull;
    if (target?.isDefault == true) {
      emit(s.copyWith(message: 'Default questions are read-only.'));
      return;
    }
    try {
      await _repository.deleteQuestion(event.id);
      emit(
        s.copyWith(
          questions: s.questions.where((q) => q.id != event.id).toList(),
          message: 'Question deleted.',
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not delete question: $e'));
    }
  }

  Future<void> _saveTemplate(
    SaveAdmissionTemplate event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    try {
      await _repository.saveTemplate(event.value);
      emit(
        s.copyWith(
          templates: [
            event.value,
            ...s.templates.where((t) => t.id != event.value.id),
          ],
          message: 'Template saved.',
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not save template: $e'));
    }
  }

  Future<void> _generate(
    GenerateAdmissionPaper event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    try {
      final paper = _generator.generate(
        id: _repository.newId(FirestorePaths.admissionTestPapers),
        template: event.template,
        bank: s.questions,
        title: event.title,
        variant: event.variant,
      );
      await _repository.savePaper(paper);
      emit(
        s.copyWith(
          papers: [paper, ...s.papers],
          preview: paper,
          message: 'Admission paper generated and saved.',
        ),
      );
    } on AdmissionPaperGenerationException catch (e) {
      emit(s.copyWith(message: e.message));
    } catch (e) {
      emit(AdmissionTestError('Could not generate paper: $e'));
    }
  }

  Future<void> _saveCustomPaper(
    SaveCustomAdmissionPaper event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    try {
      await _repository.savePaper(event.value);
      emit(
        s.copyWith(
          papers: [
            event.value,
            ...s.papers.where((paper) => paper.id != event.value.id),
          ],
          preview: event.value,
          message: 'Manual / hybrid paper saved.',
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not save custom paper: $e'));
    }
  }

  Future<void> _saveCandidate(
    SaveAdmissionCandidate event,
    Emitter<AdmissionTestState> emit,
  ) async {
    final s = state;
    if (s is! AdmissionTestLoaded) return;
    try {
      await _repository.saveCandidate(event.value);
      emit(
        s.copyWith(
          candidates: [
            event.value,
            ...s.candidates.where((c) => c.id != event.value.id),
          ],
          message: 'Candidate assessment saved.',
        ),
      );
    } catch (e) {
      emit(AdmissionTestError('Could not save candidate: $e'));
    }
  }
}

List<AdmissionPaperTemplateEntity> defaultAdmissionTemplates() {
  final now = DateTime.now();
  AdmissionPaperTemplateEntity value(
    String level,
    AdmissionAssessmentMode mode,
    int duration,
    List<AdmissionTemplateSection> sections,
  ) => AdmissionPaperTemplateEntity(
    id: 'default_${level.toLowerCase().replaceAll(' ', '_')}',
    classLevel: level,
    mode: mode,
    durationMinutes: duration,
    passingPercentage: 50,
    sections: sections,
    updatedAt: now,
  );
  return [
    value('Nursery', AdmissionAssessmentMode.earlyYears, 30, const [
      AdmissionTemplateSection(subject: 'Oral & Observation', questionCount: 8),
    ]),
    value('KG', AdmissionAssessmentMode.earlyYears, 35, const [
      AdmissionTemplateSection(subject: 'Oral & Observation', questionCount: 8),
    ]),
    for (final level in ['Class 1', 'Class 2'])
      value(level, AdmissionAssessmentMode.written, 60, const [
        AdmissionTemplateSection(subject: 'English', questionCount: 5),
        AdmissionTemplateSection(subject: 'Urdu', questionCount: 5),
        AdmissionTemplateSection(subject: 'Mathematics', questionCount: 5),
        AdmissionTemplateSection(
          subject: 'General Knowledge',
          questionCount: 5,
        ),
      ]),
    for (final level in ['Class 3', 'Class 4', 'Class 5'])
      value(level, AdmissionAssessmentMode.written, 75, const [
        AdmissionTemplateSection(subject: 'English', questionCount: 5),
        AdmissionTemplateSection(subject: 'Urdu', questionCount: 5),
        AdmissionTemplateSection(subject: 'Mathematics', questionCount: 5),
        AdmissionTemplateSection(subject: 'Science / GK', questionCount: 5),
      ]),
    for (final level in ['Class 6', 'Class 7', 'Class 8'])
      value(level, AdmissionAssessmentMode.written, 90, const [
        AdmissionTemplateSection(subject: 'English', questionCount: 6),
        AdmissionTemplateSection(subject: 'Urdu', questionCount: 6),
        AdmissionTemplateSection(subject: 'Mathematics', questionCount: 6),
        AdmissionTemplateSection(subject: 'Science', questionCount: 6),
        AdmissionTemplateSection(subject: 'Reasoning', questionCount: 4),
      ]),
  ];
}
