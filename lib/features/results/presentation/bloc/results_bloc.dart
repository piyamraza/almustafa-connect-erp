import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_published_results.dart';
import 'results_event.dart';
import 'results_state.dart';

class ResultsBloc extends Bloc<ResultsEvent, ResultsState> {
  ResultsBloc({required GetPublishedResults getPublishedResults})
      : _getPublishedResults = getPublishedResults,
        super(const ResultsInitial()) {
    on<LoadPublishedResults>(_onLoad);
    on<RefreshPublishedResults>(_onRefresh);
    on<FilterResultsBySession>(_onFilterSession);
    on<FilterResultsByExam>(_onFilterExam);
    on<FilterResultsByClass>(_onFilterClass);
    on<FilterResultsBySection>(_onFilterSection);
    on<FilterResultsByStudent>(_onFilterStudent);
    on<SearchPublishedResults>(_onSearch);
  }

  final GetPublishedResults _getPublishedResults;

  Future<void> _onLoad(
    LoadPublishedResults event,
    Emitter<ResultsState> emit,
  ) async {
    emit(const ResultsLoading());
    try {
      emit(PublishedResultsLoaded(results: await _getPublishedResults()));
    } catch (error) {
      emit(ResultsFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshPublishedResults event,
    Emitter<ResultsState> emit,
  ) async {
    final current = state;
    if (current is! PublishedResultsLoaded) {
      await _onLoad(const LoadPublishedResults(), emit);
      return;
    }
    emit(current.copyWith(isLoading: true));
    try {
      final results = await _getPublishedResults();
      final session = results.any(
        (result) => result.academicSession == current.selectedAcademicSession,
      )
          ? current.selectedAcademicSession
          : null;
      final examId = results.any(
        (result) =>
            (session == null || result.academicSession == session) &&
            result.examId == current.selectedExamId,
      )
          ? current.selectedExamId
          : null;
      final classId = results.any(
        (result) =>
            (session == null || result.academicSession == session) &&
            (examId == null || result.examId == examId) &&
            result.classId == current.selectedClassId,
      )
          ? current.selectedClassId
          : null;
      final sectionId = results.any(
        (result) =>
            (session == null || result.academicSession == session) &&
            (examId == null || result.examId == examId) &&
            (classId == null || result.classId == classId) &&
            result.sectionId == current.selectedSectionId,
      )
          ? current.selectedSectionId
          : null;
      final studentId = results.any(
        (result) =>
            (session == null || result.academicSession == session) &&
            (examId == null || result.examId == examId) &&
            (classId == null || result.classId == classId) &&
            (sectionId == null || result.sectionId == sectionId) &&
            result.studentId == current.selectedStudentId,
      )
          ? current.selectedStudentId
          : null;
      emit(PublishedResultsLoaded(
        results: results,
        selectedAcademicSession: session,
        selectedExamId: examId,
        selectedClassId: classId,
        selectedSectionId: sectionId,
        selectedStudentId: studentId,
        searchQuery: current.searchQuery,
      ));
    } catch (error) {
      emit(ResultsFailure(_message(error)));
    }
  }

  void _onFilterSession(
    FilterResultsBySession event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(
      selectedAcademicSession: event.academicSession,
      clearExam: true,
      clearClass: true,
      clearSection: true,
      clearStudent: true,
    ));
  }

  void _onFilterExam(
    FilterResultsByExam event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(
      selectedExamId: event.examId,
      clearClass: true,
      clearSection: true,
      clearStudent: true,
    ));
  }

  void _onFilterClass(
    FilterResultsByClass event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(
      selectedClassId: event.classId,
      clearSection: true,
      clearStudent: true,
    ));
  }

  void _onFilterSection(
    FilterResultsBySection event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(
      selectedSectionId: event.sectionId,
      clearStudent: true,
    ));
  }

  void _onFilterStudent(
    FilterResultsByStudent event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(selectedStudentId: event.studentId));
  }

  void _onSearch(
    SearchPublishedResults event,
    Emitter<ResultsState> emit,
  ) {
    final current = state;
    if (current is! PublishedResultsLoaded) return;
    emit(current.copyWith(searchQuery: event.query));
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}
