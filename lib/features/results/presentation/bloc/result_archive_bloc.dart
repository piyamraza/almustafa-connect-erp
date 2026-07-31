import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_result_archive.dart';
import 'result_archive_event.dart';
import 'result_archive_state.dart';

class ResultArchiveBloc extends Bloc<ResultArchiveEvent, ResultArchiveState> {
  ResultArchiveBloc({required this.getResultArchive})
    : super(const ResultArchiveInitial()) {
    on<LoadResultArchive>(_onLoad);
    on<RefreshResultArchive>(_onRefresh);
    on<FilterArchiveBySession>(_onSession);
    on<FilterArchiveByExam>(_onExam);
    on<FilterArchiveByClass>(_onClass);
    on<FilterArchiveBySection>(_onSection);
    on<FilterArchiveByStudent>(_onStudent);
    on<FilterArchiveByStatus>(_onStatus);
    on<FilterArchiveByPublicationDates>(_onDates);
    on<SearchResultArchive>(_onSearch);
  }

  final GetResultArchive getResultArchive;

  Future<void> _onLoad(
    LoadResultArchive event,
    Emitter<ResultArchiveState> emit,
  ) async {
    emit(const ResultArchiveLoading());
    try {
      emit(ResultArchiveLoaded(results: await getResultArchive()));
    } catch (error) {
      emit(ResultArchiveFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshResultArchive event,
    Emitter<ResultArchiveState> emit,
  ) async {
    final current = state;
    if (current is! ResultArchiveLoaded) {
      await _onLoad(const LoadResultArchive(), emit);
      return;
    }
    emit(current.copyWith(isRefreshing: true));
    try {
      emit(
        current.copyWith(
          results: await getResultArchive(),
          isRefreshing: false,
        ),
      );
    } catch (error) {
      emit(ResultArchiveFailure(_message(error)));
    }
  }

  void _onSession(
    FilterArchiveBySession event,
    Emitter<ResultArchiveState> emit,
  ) {
    _update(
      emit,
      (current) => current.copyWith(
        academicSession: event.value,
        clearSession: event.value == null,
        clearExam: true,
        clearClass: true,
        clearSection: true,
        clearStudent: true,
      ),
    );
  }

  void _onExam(FilterArchiveByExam event, Emitter<ResultArchiveState> emit) {
    _update(
      emit,
      (current) => current.copyWith(
        examId: event.value,
        clearExam: event.value == null,
        clearClass: true,
        clearSection: true,
        clearStudent: true,
      ),
    );
  }

  void _onClass(FilterArchiveByClass event, Emitter<ResultArchiveState> emit) {
    _update(
      emit,
      (current) => current.copyWith(
        classId: event.value,
        clearClass: event.value == null,
        clearSection: true,
        clearStudent: true,
      ),
    );
  }

  void _onSection(
    FilterArchiveBySection event,
    Emitter<ResultArchiveState> emit,
  ) {
    _update(
      emit,
      (current) => current.copyWith(
        sectionId: event.value,
        clearSection: event.value == null,
        clearStudent: true,
      ),
    );
  }

  void _onStudent(
    FilterArchiveByStudent event,
    Emitter<ResultArchiveState> emit,
  ) {
    _update(
      emit,
      (current) => current.copyWith(
        studentId: event.value,
        clearStudent: event.value == null,
      ),
    );
  }

  void _onStatus(
    FilterArchiveByStatus event,
    Emitter<ResultArchiveState> emit,
  ) {
    _update(
      emit,
      (current) => current.copyWith(
        status: event.value,
        clearStatus: event.value == null,
      ),
    );
  }

  void _onDates(
    FilterArchiveByPublicationDates event,
    Emitter<ResultArchiveState> emit,
  ) {
    _update(
      emit,
      (current) => current.copyWith(
        publicationRange: event.range,
        clearPublicationRange: event.range == null,
      ),
    );
  }

  void _onSearch(SearchResultArchive event, Emitter<ResultArchiveState> emit) {
    _update(emit, (current) => current.copyWith(searchQuery: event.query));
  }

  void _update(
    Emitter<ResultArchiveState> emit,
    ResultArchiveLoaded Function(ResultArchiveLoaded current) update,
  ) {
    final current = state;
    if (current is ResultArchiveLoaded) {
      emit(update(current));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}
