import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/result_analytics_entity.dart';
import '../../domain/usecases/get_results_analytics_data.dart';
import 'results_analytics_event.dart';
import 'results_analytics_state.dart';

class ResultsAnalyticsBloc
    extends Bloc<ResultsAnalyticsEvent, ResultsAnalyticsState> {
  ResultsAnalyticsBloc({required GetResultsAnalyticsData getAnalyticsData})
      : _getAnalyticsData = getAnalyticsData,
        super(const ResultsAnalyticsInitial()) {
    on<LoadResultsAnalytics>(_onLoad);
    on<RefreshResultsAnalytics>(_onRefresh);
    on<FilterAnalyticsBySession>(_onSession);
    on<FilterAnalyticsByExam>(_onExam);
    on<FilterAnalyticsByClass>(_onClass);
    on<FilterAnalyticsBySection>(_onSection);
    on<FilterAnalyticsBySubject>(_onSubject);
    on<FilterAnalyticsByStudent>(_onStudent);
    on<SearchAnalyticsStudents>(_onSearch);
    on<SortAnalyticsSubjectRows>(_onSort);
    on<SetAnalyticsBorderlineMargin>(_onBorderlineMargin);
    on<SetAnalyticsLowPerformanceThreshold>(_onLowPerformanceThreshold);
  }

  final GetResultsAnalyticsData _getAnalyticsData;

  Future<void> _onLoad(
    LoadResultsAnalytics event,
    Emitter<ResultsAnalyticsState> emit,
  ) async {
    emit(const ResultsAnalyticsLoading());
    try {
      emit(ResultsAnalyticsLoaded(data: await _getAnalyticsData()));
    } catch (error) {
      emit(ResultsAnalyticsFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshResultsAnalytics event,
    Emitter<ResultsAnalyticsState> emit,
  ) async {
    final current = state;
    if (current is! ResultsAnalyticsLoaded) {
      await _onLoad(const LoadResultsAnalytics(), emit);
      return;
    }
    emit(current.copyWith(isRefreshing: true));
    try {
      final data = await _getAnalyticsData();
      emit(ResultsAnalyticsLoaded(data: data, filter: current.filter));
    } catch (error) {
      emit(ResultsAnalyticsFailure(_message(error)));
    }
  }

  void _onSession(
    FilterAnalyticsBySession event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        academicSession: event.value,
        clearAcademicSession: event.value == null,
        clearExam: true,
        clearClass: true,
        clearSection: true,
        clearSubject: true,
        clearStudent: true,
      ),
    );
  }

  void _onExam(
    FilterAnalyticsByExam event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        examId: event.value,
        clearExam: event.value == null,
        clearClass: true,
        clearSection: true,
        clearSubject: true,
        clearStudent: true,
      ),
    );
  }

  void _onClass(
    FilterAnalyticsByClass event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        classId: event.value,
        clearClass: event.value == null,
        clearSection: true,
        clearSubject: true,
        clearStudent: true,
      ),
    );
  }

  void _onSection(
    FilterAnalyticsBySection event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        sectionId: event.value,
        clearSection: event.value == null,
        clearSubject: true,
        clearStudent: true,
      ),
    );
  }

  void _onSubject(
    FilterAnalyticsBySubject event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        subjectName: event.value,
        clearSubject: event.value == null,
      ),
    );
  }

  void _onStudent(
    FilterAnalyticsByStudent event,
    Emitter<ResultsAnalyticsState> emit,
  ) {
    _update(
      emit,
      (filter) => filter.copyWith(
        studentId: event.value,
        clearStudent: event.value == null,
      ),
    );
  }

  void _onSearch(
    SearchAnalyticsStudents event,
    Emitter<ResultsAnalyticsState> emit,
  ) => _update(emit, (filter) => filter.copyWith(searchQuery: event.query));

  void _onSort(
    SortAnalyticsSubjectRows event,
    Emitter<ResultsAnalyticsState> emit,
  ) => _update(emit, (filter) => filter.copyWith(sort: event.sort));

  void _onBorderlineMargin(
    SetAnalyticsBorderlineMargin event,
    Emitter<ResultsAnalyticsState> emit,
  ) => _update(
    emit,
    (filter) => filter.copyWith(borderlineMargin: event.value),
  );

  void _onLowPerformanceThreshold(
    SetAnalyticsLowPerformanceThreshold event,
    Emitter<ResultsAnalyticsState> emit,
  ) => _update(
    emit,
    (filter) => filter.copyWith(lowPerformanceThreshold: event.value),
  );

  void _update(
    Emitter<ResultsAnalyticsState> emit,
    ResultAnalyticsFilter Function(ResultAnalyticsFilter filter) update,
  ) {
    final current = state;
    if (current is! ResultsAnalyticsLoaded) return;
    emit(current.copyWith(filter: update(current.filter)));
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}
