import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_entity.dart';
import '../../domain/usecases/create_exam.dart' as create_usecase;
import '../../domain/usecases/delete_exam.dart' as delete_usecase;
import '../../domain/usecases/get_exams.dart' as get_usecase;
import '../../domain/usecases/set_exam_active_status.dart' as status_usecase;
import '../../domain/usecases/update_exam.dart' as update_usecase;
import 'exam_event.dart';
import 'exam_state.dart';

class ExamBloc extends Bloc<ExamEvent, ExamState> {
  ExamBloc({
    required get_usecase.GetExams getExams,
    required create_usecase.CreateExam createExam,
    required update_usecase.UpdateExam updateExam,
    required delete_usecase.DeleteExam deleteExam,
    required status_usecase.SetExamActiveStatus setExamActiveStatus,
  })  : _getExams = getExams,
        _createExam = createExam,
        _updateExam = updateExam,
        _deleteExam = deleteExam,
        _setExamActiveStatus = setExamActiveStatus,
        super(const ExamInitial()) {
    on<LoadExams>(_onLoadExams);
    on<RefreshExams>(_onRefreshExams);
    on<CreateExam>(_onCreateExam);
    on<UpdateExam>(_onUpdateExam);
    on<DeleteExam>(_onDeleteExam);
    on<ToggleExamActiveStatus>(_onToggleExamActiveStatus);
    on<SearchExams>(_onSearchExams);
  }

  final get_usecase.GetExams _getExams;
  final create_usecase.CreateExam _createExam;
  final update_usecase.UpdateExam _updateExam;
  final delete_usecase.DeleteExam _deleteExam;
  final status_usecase.SetExamActiveStatus _setExamActiveStatus;

  Future<void> _onLoadExams(
    LoadExams event,
    Emitter<ExamState> emit,
  ) async {
    await _loadExams(
      emit,
      academicSession: event.academicSession,
      isActive: event.isActive,
    );
  }

  Future<void> _onRefreshExams(
    RefreshExams event,
    Emitter<ExamState> emit,
  ) async {
    final currentState = state;
    await _loadExams(
      emit,
      academicSession: event.academicSession ??
          (currentState is ExamLoaded ? currentState.academicSession : null),
      isActive: event.isActive ??
          (currentState is ExamLoaded ? currentState.isActive : null),
      searchQuery: event.searchQuery ??
          (currentState is ExamLoaded ? currentState.searchQuery : ''),
    );
  }

  Future<void> _onCreateExam(
    CreateExam event,
    Emitter<ExamState> emit,
  ) async {
    final previousState = state;
    emit(const ExamLoading());
    try {
      await _createExam(event.exam);
      await _reloadUsingCurrentFilters(
        emit,
        previousState,
        successMessage: 'Exam created successfully.',
      );
    } catch (error) {
      emit(ExamError(error.toString()));
    }
  }

  Future<void> _onUpdateExam(
    UpdateExam event,
    Emitter<ExamState> emit,
  ) async {
    final previousState = state;
    emit(const ExamLoading());
    try {
      await _updateExam(event.exam);
      await _reloadUsingCurrentFilters(
        emit,
        previousState,
        successMessage: 'Exam updated successfully.',
      );
    } catch (error) {
      emit(ExamError(error.toString()));
    }
  }

  Future<void> _onDeleteExam(
    DeleteExam event,
    Emitter<ExamState> emit,
  ) async {
    final previousState = state;
    emit(const ExamLoading());
    try {
      await _deleteExam(event.examId);
      await _reloadUsingCurrentFilters(
        emit,
        previousState,
        successMessage: 'Exam deleted successfully.',
      );
    } catch (error) {
      emit(ExamError(error.toString()));
    }
  }

  Future<void> _onToggleExamActiveStatus(
    ToggleExamActiveStatus event,
    Emitter<ExamState> emit,
  ) async {
    final previousState = state;
    emit(const ExamLoading());
    try {
      await _setExamActiveStatus(
        id: event.examId,
        isActive: event.isActive,
      );
      await _reloadUsingCurrentFilters(
        emit,
        previousState,
        successMessage: event.isActive
            ? 'Exam activated successfully.'
            : 'Exam deactivated successfully.',
      );
    } catch (error) {
      emit(ExamError(error.toString()));
    }
  }

  Future<void> _onSearchExams(
    SearchExams event,
    Emitter<ExamState> emit,
  ) async {
    final currentState = state;
    if (currentState is ExamLoaded) {
      final normalizedQuery = event.query.trim();
      emit(
        ExamLoaded(
          _filterExams(currentState.allExams, normalizedQuery),
          allExams: currentState.allExams,
          searchQuery: normalizedQuery,
          academicSession: currentState.academicSession,
          isActive: currentState.isActive,
        ),
      );
      return;
    }

    await _loadExams(emit, searchQuery: event.query);
  }

  Future<void> _reloadUsingCurrentFilters(
    Emitter<ExamState> emit,
    ExamState previousState, {
    String? successMessage,
  }) {
    return _loadExams(
      emit,
      academicSession:
          previousState is ExamLoaded ? previousState.academicSession : null,
      isActive: previousState is ExamLoaded ? previousState.isActive : null,
      searchQuery:
          previousState is ExamLoaded ? previousState.searchQuery : '',
      showLoading: false,
      successMessage: successMessage,
    );
  }

  Future<void> _loadExams(
    Emitter<ExamState> emit, {
    String? academicSession,
    bool? isActive,
    String searchQuery = '',
    bool showLoading = true,
    String? successMessage,
  }) async {
    if (showLoading) {
      emit(const ExamLoading());
    }

    try {
      final allExams = await _getExams(
        academicSession: academicSession,
        isActive: isActive,
      );
      final normalizedQuery = searchQuery.trim();
      emit(
        ExamLoaded(
          _filterExams(allExams, normalizedQuery),
          allExams: allExams,
          searchQuery: normalizedQuery,
          academicSession: academicSession,
          isActive: isActive,
          successMessage: successMessage,
        ),
      );
    } catch (error) {
      emit(ExamError(error.toString()));
    }
  }

  List<ExamEntity> _filterExams(
    List<ExamEntity> exams,
    String query,
  ) {
    if (query.isEmpty) {
      return exams;
    }

    final normalizedQuery = query.toLowerCase();
    return exams.where((exam) {
      return exam.name.toLowerCase().contains(normalizedQuery) ||
          exam.subject.toLowerCase().contains(normalizedQuery) ||
          exam.classId.toLowerCase().contains(normalizedQuery) ||
          exam.sectionId.toLowerCase().contains(normalizedQuery) ||
          exam.academicSession.toLowerCase().contains(normalizedQuery) ||
          exam.type.name.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

}
