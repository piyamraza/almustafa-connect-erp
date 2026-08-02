import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_entity.dart';
import '../../domain/entities/exam_result_entity.dart';
import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/usecases/generate_exam_results.dart';
import '../../domain/usecases/get_exam_results.dart';
import '../../domain/usecases/get_exam_subject_setups_for_exam.dart';
import '../../domain/usecases/get_exams.dart';
import '../../domain/usecases/update_exam_result_status.dart';
import 'exam_results_event.dart';
import 'exam_results_state.dart';

class ExamResultsBloc extends Bloc<ExamResultsEvent, ExamResultsState> {
  ExamResultsBloc({
    required this._getExams,
    required this._getSubjectSetupsForExam,
    required this._getExamResults,
    required this._generateExamResults,
    required this._updateResultStatus,
  }) : super(const ExamResultsInitial()) {
    on<LoadResultSummary>(_onLoad);
    on<RefreshResultSummary>(_onRefresh);
    on<SelectResultExam>(_onSelectExam);
    on<SelectResultClass>(_onSelectClass);
    on<SelectResultSection>(_onSelectSection);
    on<GenerateSelectedExamResults>(_onGenerate);
    on<ChangeFilteredResultsStatus>(_onChangeStatus);
    on<UnlockFilteredResults>(_onUnlock);
  }

  final GetExams _getExams;
  final GetExamSubjectSetupsForExam _getSubjectSetupsForExam;
  final GetExamResults _getExamResults;
  final GenerateExamResults _generateExamResults;
  final UpdateExamResultStatus _updateResultStatus;

  Future<void> _onLoad(
    LoadResultSummary event,
    Emitter<ExamResultsState> emit,
  ) async {
    emit(const ExamResultsLoading());
    try {
      final exams = await _getExams();
      emit(ExamResultsLoaded(exams: exams));
    } catch (error) {
      emit(ExamResultsFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshResultSummary event,
    Emitter<ExamResultsState> emit,
  ) async {
    final current = state;
    if (current is! ExamResultsLoaded) {
      await _onLoad(const LoadResultSummary(), emit);
      return;
    }
    if (current.selectedExamId == null) {
      emit(current.copyWith(isLoading: true, clearMessages: true));
      try {
        emit(
          current.copyWith(
            exams: await _getExams(),
            isLoading: false,
            clearMessages: true,
          ),
        );
      } catch (error) {
        emit(
          current.copyWith(errorMessage: _message(error), clearMessages: true),
        );
      }
      return;
    }

    emit(current.copyWith(isLoading: true, clearMessages: true));
    try {
      emit(await _loadExamData(current, current.selectedExamId!));
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
    SelectResultExam event,
    Emitter<ExamResultsState> emit,
  ) async {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    emit(
      current.copyWith(
        selectedExamId: event.examId,
        subjectSetups: const [],
        results: const [],
        clearClass: true,
        clearSection: true,
        isLoading: true,
        clearMessages: true,
      ),
    );
    try {
      emit(await _loadExamData(current, event.examId, clearFilters: true));
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

  void _onSelectClass(SelectResultClass event, Emitter<ExamResultsState> emit) {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    emit(
      current.copyWith(
        selectedClassId: event.classId,
        clearSection: true,
        clearMessages: true,
      ),
    );
  }

  void _onSelectSection(
    SelectResultSection event,
    Emitter<ExamResultsState> emit,
  ) {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    emit(
      current.copyWith(selectedSectionId: event.sectionId, clearMessages: true),
    );
  }

  Future<void> _onGenerate(
    GenerateSelectedExamResults event,
    Emitter<ExamResultsState> emit,
  ) async {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    final examId = current.selectedExamId;
    if (examId == null) {
      emit(
        current.copyWith(
          errorMessage: 'Select an exam before generating results.',
          clearMessages: true,
        ),
      );
      return;
    }
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _generateExamResults(examId);
      final results = await _getExamResults(examId);
      emit(
        current.copyWith(
          results: results,
          isProcessing: false,
          successMessage: 'Results calculated successfully.',
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _onChangeStatus(
    ChangeFilteredResultsStatus event,
    Emitter<ExamResultsState> emit,
  ) async {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    final selected = current.filteredResults;
    final validation = _validateStatusChange(selected, event.status);
    if (validation != null) {
      emit(current.copyWith(errorMessage: validation, clearMessages: true));
      return;
    }
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _updateResultStatus(
        resultIds: selected.map((result) => result.id).toList(growable: false),
        status: event.status,
        actorId: event.actorId,
        reason: event.reason,
      );
      final refreshed = await _getExamResults(current.selectedExamId!);
      emit(
        current.copyWith(
          results: refreshed,
          isProcessing: false,
          successMessage: _statusMessage(event.status),
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<void> _onUnlock(
    UnlockFilteredResults event,
    Emitter<ExamResultsState> emit,
  ) async {
    final current = state;
    if (current is! ExamResultsLoaded) return;
    final selected = current.filteredResults;
    if (selected.isEmpty) {
      emit(
        current.copyWith(
          errorMessage: 'No calculated results match the current filters.',
          clearMessages: true,
        ),
      );
      return;
    }
    if (!selected.every((result) => result.status == ResultStatus.locked)) {
      emit(
        current.copyWith(
          errorMessage: 'Only locked results can be unlocked.',
          clearMessages: true,
        ),
      );
      return;
    }
    emit(current.copyWith(isProcessing: true, clearMessages: true));
    try {
      await _updateResultStatus(
        resultIds: selected.map((result) => result.id).toList(growable: false),
        status: ResultStatus.published,
        actorId: event.actorId,
        reason: event.reason,
        setPublishedAt: false,
      );
      final refreshed = await _getExamResults(current.selectedExamId!);
      emit(
        current.copyWith(
          results: refreshed,
          isProcessing: false,
          successMessage: 'Results unlocked and restored to published status.',
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        current.copyWith(
          isProcessing: false,
          errorMessage: _message(error),
          clearMessages: true,
        ),
      );
    }
  }

  Future<ExamResultsLoaded> _loadExamData(
    ExamResultsLoaded base,
    String examId, {
    bool clearFilters = false,
  }) async {
    final responses = await Future.wait<Object>([
      _getExams(),
      _getSubjectSetupsForExam(examId),
      _getExamResults(examId),
    ]);
    final setups = responses[1] as List<ExamSubjectSetupEntity>;
    final validClass =
        !clearFilters &&
            setups.any((setup) => setup.classId == base.selectedClassId)
        ? base.selectedClassId
        : null;
    final validSection =
        validClass != null &&
            setups.any(
              (setup) =>
                  setup.classId == validClass &&
                  setup.sectionId == base.selectedSectionId,
            )
        ? base.selectedSectionId
        : null;
    return ExamResultsLoaded(
      exams: responses[0] as List<ExamEntity>,
      subjectSetups: setups,
      results: responses[2] as List<ExamResultEntity>,
      selectedExamId: examId,
      selectedClassId: validClass,
      selectedSectionId: validSection,
      isLoading: false,
      successMessage: base.successMessage,
      errorMessage: base.errorMessage,
    );
  }

  String? _validateStatusChange(
    List<ExamResultEntity> results,
    ResultStatus target,
  ) {
    if (results.isEmpty) {
      return 'No calculated results match the current filters.';
    }
    if (results.any((result) => result.status == ResultStatus.locked)) {
      return 'Locked results are read-only.';
    }
    final allowed = results.every(
      (result) =>
          ExamResultEntity.canTransition(current: result.status, next: target),
    );
    if (allowed) return null;
    return switch (target) {
      ResultStatus.generated =>
        'Only draft or verified results can be generated.',
      ResultStatus.verified =>
        'Only generated or approved results can be verified.',
      ResultStatus.approved =>
        'Only verified or published results can be approved.',
      ResultStatus.published =>
        'Only approved or unpublished results can be published.',
      ResultStatus.locked => 'Only published results can be locked.',
      ResultStatus.unpublished => 'Only published results can be unpublished.',
      ResultStatus.draft => 'Only generated results can return to draft.',
    };
  }

  String _statusMessage(ResultStatus status) => switch (status) {
    ResultStatus.generated => 'Results generated successfully.',
    ResultStatus.verified => 'Results verified successfully.',
    ResultStatus.approved => 'Results approved successfully.',
    ResultStatus.published => 'Results published successfully.',
    ResultStatus.locked => 'Published results are now locked and read-only.',
    ResultStatus.unpublished => 'Results are now unpublished.',
    ResultStatus.draft => 'Results saved as draft.',
  };

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}
