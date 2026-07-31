import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';

sealed class ExamDateSheetWorkflowEvent {
  const ExamDateSheetWorkflowEvent();
}

class LoadExamDateSheetWorkflow extends ExamDateSheetWorkflowEvent {
  const LoadExamDateSheetWorkflow();
}

class PublishExamDateSheet extends ExamDateSheetWorkflowEvent {
  const PublishExamDateSheet(this.dateSheet);
  final ExamDateSheetEntity dateSheet;
}

class ArchiveExamDateSheet extends ExamDateSheetWorkflowEvent {
  const ArchiveExamDateSheet(this.dateSheet);
  final ExamDateSheetEntity dateSheet;
}

class ReviseExamDateSheet extends ExamDateSheetWorkflowEvent {
  const ReviseExamDateSheet(this.dateSheet);
  final ExamDateSheetEntity dateSheet;
}

sealed class ExamDateSheetWorkflowState {
  const ExamDateSheetWorkflowState();
}

class ExamDateSheetWorkflowInitial extends ExamDateSheetWorkflowState {
  const ExamDateSheetWorkflowInitial();
}

class ExamDateSheetWorkflowLoading extends ExamDateSheetWorkflowState {
  const ExamDateSheetWorkflowLoading();
}

class ExamDateSheetWorkflowLoaded extends ExamDateSheetWorkflowState {
  const ExamDateSheetWorkflowLoaded(
    this.dateSheets, {
    this.message,
    this.createdDraft,
  });

  final List<ExamDateSheetEntity> dateSheets;
  final String? message;
  final ExamDateSheetEntity? createdDraft;
}

class ExamDateSheetWorkflowError extends ExamDateSheetWorkflowState {
  const ExamDateSheetWorkflowError(this.message);
  final String message;
}

class ExamDateSheetWorkflowBloc
    extends Bloc<ExamDateSheetWorkflowEvent, ExamDateSheetWorkflowState> {
  ExamDateSheetWorkflowBloc(this._repository)
    : super(const ExamDateSheetWorkflowInitial()) {
    on<LoadExamDateSheetWorkflow>(_load);
    on<PublishExamDateSheet>(_publish);
    on<ArchiveExamDateSheet>(_archive);
    on<ReviseExamDateSheet>(_revise);
  }

  final ExamDateSheetRepository _repository;

  Future<void> _load(
    LoadExamDateSheetWorkflow event,
    Emitter<ExamDateSheetWorkflowState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _publish(
    PublishExamDateSheet event,
    Emitter<ExamDateSheetWorkflowState> emit,
  ) async {
    if (event.dateSheet.status != ExamDateSheetStatus.draft) {
      emit(
        const ExamDateSheetWorkflowError(
          'Only a draft date sheet can be published.',
        ),
      );
      return;
    }
    if (event.dateSheet.papers.isEmpty) {
      emit(
        const ExamDateSheetWorkflowError(
          'An empty date sheet cannot be published.',
        ),
      );
      return;
    }

    emit(const ExamDateSheetWorkflowLoading());
    try {
      await _repository.publishDateSheet(event.dateSheet.id);
      await _reload(emit, message: 'Date sheet published successfully.');
    } catch (error) {
      emit(ExamDateSheetWorkflowError(_message(error)));
    }
  }

  Future<void> _archive(
    ArchiveExamDateSheet event,
    Emitter<ExamDateSheetWorkflowState> emit,
  ) async {
    if (event.dateSheet.status == ExamDateSheetStatus.archived) {
      return;
    }

    emit(const ExamDateSheetWorkflowLoading());
    try {
      await _repository.archiveDateSheet(event.dateSheet.id);
      await _reload(emit, message: 'Date sheet archived successfully.');
    } catch (error) {
      emit(ExamDateSheetWorkflowError(_message(error)));
    }
  }

  Future<void> _revise(
    ReviseExamDateSheet event,
    Emitter<ExamDateSheetWorkflowState> emit,
  ) async {
    emit(const ExamDateSheetWorkflowLoading());
    try {
      final now = DateTime.now();
      final source = event.dateSheet;
      final draft = ExamDateSheetEntity(
        id: _repository.generateDateSheetId(),
        examId: source.examId,
        examName: source.examName,
        academicSession: source.academicSession,
        title: '${source.title} - Revised Draft',
        creationMode: source.creationMode,
        status: ExamDateSheetStatus.draft,
        papers: source.papers,
        createdAt: now,
        updatedAt: now,
        generatorOptionLabel: source.generatorOptionLabel,
      );

      await _repository.saveDateSheet(draft);
      await _reload(
        emit,
        message: 'Editable revision draft created.',
        createdDraft: draft,
      );
    } catch (error) {
      emit(ExamDateSheetWorkflowError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<ExamDateSheetWorkflowState> emit, {
    String? message,
    ExamDateSheetEntity? createdDraft,
  }) async {
    emit(const ExamDateSheetWorkflowLoading());
    try {
      final dateSheets = await _repository.getDateSheets();
      emit(
        ExamDateSheetWorkflowLoaded(
          dateSheets,
          message: message,
          createdDraft: createdDraft,
        ),
      );
    } catch (error) {
      emit(ExamDateSheetWorkflowError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
