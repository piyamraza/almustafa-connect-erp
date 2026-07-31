import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';

sealed class ExamDateSheetEvent {
  const ExamDateSheetEvent();
}

class LoadExamDateSheets extends ExamDateSheetEvent {
  const LoadExamDateSheets({this.examId, this.academicSession});

  final String? examId;
  final String? academicSession;
}

class DeleteExamDateSheet extends ExamDateSheetEvent {
  const DeleteExamDateSheet(this.id);
  final String id;
}

sealed class ExamDateSheetState {
  const ExamDateSheetState();
}

class ExamDateSheetInitial extends ExamDateSheetState {
  const ExamDateSheetInitial();
}

class ExamDateSheetLoading extends ExamDateSheetState {
  const ExamDateSheetLoading();
}

class ExamDateSheetLoaded extends ExamDateSheetState {
  const ExamDateSheetLoaded(this.values, {this.message});

  final List<ExamDateSheetEntity> values;
  final String? message;
}

class ExamDateSheetError extends ExamDateSheetState {
  const ExamDateSheetError(this.message);
  final String message;
}

class ExamDateSheetBloc extends Bloc<ExamDateSheetEvent, ExamDateSheetState> {
  ExamDateSheetBloc(this._repository) : super(const ExamDateSheetInitial()) {
    on<LoadExamDateSheets>(_load);
    on<DeleteExamDateSheet>(_delete);
  }

  final ExamDateSheetRepository _repository;
  String? _examId;
  String? _session;

  Future<void> _load(
    LoadExamDateSheets event,
    Emitter<ExamDateSheetState> emit,
  ) async {
    _examId = event.examId;
    _session = event.academicSession;
    await _reload(emit);
  }

  Future<void> _delete(
    DeleteExamDateSheet event,
    Emitter<ExamDateSheetState> emit,
  ) async {
    emit(const ExamDateSheetLoading());
    try {
      await _repository.deleteDateSheet(event.id);
      await _reload(emit, message: 'Date sheet deleted.');
    } catch (error) {
      emit(ExamDateSheetError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<ExamDateSheetState> emit, {
    String? message,
  }) async {
    emit(const ExamDateSheetLoading());
    try {
      final values = await _repository.getDateSheets(
        examId: _examId,
        academicSession: _session,
      );
      emit(ExamDateSheetLoaded(values, message: message));
    } catch (error) {
      emit(ExamDateSheetError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
