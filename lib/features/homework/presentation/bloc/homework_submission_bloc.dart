import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/homework_submission_entity.dart';
import '../../domain/repositories/homework_submission_repository.dart';

sealed class HomeworkSubmissionEvent {
  const HomeworkSubmissionEvent();
}

class LoadHomeworkSubmissions extends HomeworkSubmissionEvent {
  const LoadHomeworkSubmissions({
    this.homeworkId,
    this.studentId,
    this.classId,
    this.sectionId,
    this.status,
  });

  final String? homeworkId;
  final String? studentId;
  final String? classId;
  final String? sectionId;
  final HomeworkSubmissionStatus? status;
}

class SaveHomeworkSubmission extends HomeworkSubmissionEvent {
  const SaveHomeworkSubmission(this.submission);

  final HomeworkSubmissionEntity submission;
}

class DeleteHomeworkSubmission extends HomeworkSubmissionEvent {
  const DeleteHomeworkSubmission(this.id);

  final String id;
}

sealed class HomeworkSubmissionState {
  const HomeworkSubmissionState();
}

class HomeworkSubmissionInitial extends HomeworkSubmissionState {
  const HomeworkSubmissionInitial();
}

class HomeworkSubmissionLoading extends HomeworkSubmissionState {
  const HomeworkSubmissionLoading();
}

class HomeworkSubmissionLoaded extends HomeworkSubmissionState {
  const HomeworkSubmissionLoaded(this.items, {this.message});

  final List<HomeworkSubmissionEntity> items;
  final String? message;
}

class HomeworkSubmissionError extends HomeworkSubmissionState {
  const HomeworkSubmissionError(this.message);

  final String message;
}

class HomeworkSubmissionBloc
    extends Bloc<HomeworkSubmissionEvent, HomeworkSubmissionState> {
  HomeworkSubmissionBloc(this._repository)
    : super(const HomeworkSubmissionInitial()) {
    on<LoadHomeworkSubmissions>(_load);
    on<SaveHomeworkSubmission>(_save);
    on<DeleteHomeworkSubmission>(_delete);
  }

  final HomeworkSubmissionRepository _repository;
  LoadHomeworkSubmissions _lastLoad = const LoadHomeworkSubmissions();

  Future<void> _load(
    LoadHomeworkSubmissions event,
    Emitter<HomeworkSubmissionState> emit,
  ) async {
    _lastLoad = event;
    await _reload(emit);
  }

  Future<void> _save(
    SaveHomeworkSubmission event,
    Emitter<HomeworkSubmissionState> emit,
  ) async {
    emit(const HomeworkSubmissionLoading());
    try {
      await _repository.saveSubmission(event.submission);
      await _reload(emit, message: 'Submission saved.');
    } catch (error) {
      emit(HomeworkSubmissionError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteHomeworkSubmission event,
    Emitter<HomeworkSubmissionState> emit,
  ) async {
    emit(const HomeworkSubmissionLoading());
    try {
      await _repository.deleteSubmission(event.id);
      await _reload(emit, message: 'Submission deleted.');
    } catch (error) {
      emit(HomeworkSubmissionError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<HomeworkSubmissionState> emit, {
    String? message,
  }) async {
    emit(const HomeworkSubmissionLoading());
    try {
      final values = await _repository.getSubmissions(
        homeworkId: _lastLoad.homeworkId,
        studentId: _lastLoad.studentId,
        classId: _lastLoad.classId,
        sectionId: _lastLoad.sectionId,
        status: _lastLoad.status,
      );
      emit(HomeworkSubmissionLoaded(values, message: message));
    } catch (error) {
      emit(HomeworkSubmissionError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
