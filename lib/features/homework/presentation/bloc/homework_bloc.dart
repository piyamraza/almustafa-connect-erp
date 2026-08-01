import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/homework_entity.dart';
import '../../domain/repositories/homework_repository.dart';

sealed class HomeworkEvent {
  const HomeworkEvent();
}

class LoadHomework extends HomeworkEvent {
  const LoadHomework(
    this.session, {
    this.status,
    this.classId,
    this.sectionId,
    this.subjectId,
    this.teacherId,
  });

  final String session;
  final HomeworkStatus? status;
  final String? classId;
  final String? sectionId;
  final String? subjectId;
  final String? teacherId;
}

class SaveHomework extends HomeworkEvent {
  const SaveHomework(this.homework);
  final HomeworkEntity homework;
}

class DeleteHomework extends HomeworkEvent {
  const DeleteHomework(this.id);
  final String id;
}

class ChangeHomeworkStatus extends HomeworkEvent {
  const ChangeHomeworkStatus(this.homework, this.status);
  final HomeworkEntity homework;
  final HomeworkStatus status;
}

class BulkChangeHomeworkStatus extends HomeworkEvent {
  const BulkChangeHomeworkStatus(this.items, this.status);
  final List<HomeworkEntity> items;
  final HomeworkStatus status;
}

class BulkDeleteHomework extends HomeworkEvent {
  const BulkDeleteHomework(this.items);
  final List<HomeworkEntity> items;
}

sealed class HomeworkState {
  const HomeworkState();
}

class HomeworkInitial extends HomeworkState {
  const HomeworkInitial();
}

class HomeworkLoading extends HomeworkState {
  const HomeworkLoading();
}

class HomeworkLoaded extends HomeworkState {
  const HomeworkLoaded(this.items, {this.message});
  final List<HomeworkEntity> items;
  final String? message;
}

class HomeworkError extends HomeworkState {
  const HomeworkError(this.message);
  final String message;
}

class HomeworkBloc extends Bloc<HomeworkEvent, HomeworkState> {
  HomeworkBloc(this._repository) : super(const HomeworkInitial()) {
    on<LoadHomework>(_load);
    on<SaveHomework>(_save);
    on<DeleteHomework>(_delete);
    on<ChangeHomeworkStatus>(_status);
    on<BulkChangeHomeworkStatus>(_bulkStatus);
    on<BulkDeleteHomework>(_bulkDelete);
  }

  final HomeworkRepository _repository;
  LoadHomework _lastLoad = const LoadHomework('2026-2027');

  Future<void> _load(LoadHomework event, Emitter<HomeworkState> emit) async {
    _lastLoad = event;
    await _reload(emit);
  }

  Future<void> _save(SaveHomework event, Emitter<HomeworkState> emit) async {
    emit(const HomeworkLoading());
    try {
      await _repository.saveHomework(event.homework);
      await _reload(emit, message: 'Homework saved.');
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteHomework event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      await _repository.deleteHomework(event.id);
      await _reload(emit, message: 'Homework deleted.');
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  Future<void> _status(
    ChangeHomeworkStatus event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      await _saveStatus(event.homework, event.status);
      await _reload(emit, message: 'Homework status updated.');
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  Future<void> _bulkStatus(
    BulkChangeHomeworkStatus event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      for (final item in event.items) {
        await _saveStatus(item, event.status);
      }
      await _reload(
        emit,
        message: '${event.items.length} homework records updated.',
      );
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  Future<void> _bulkDelete(
    BulkDeleteHomework event,
    Emitter<HomeworkState> emit,
  ) async {
    emit(const HomeworkLoading());
    try {
      for (final item in event.items) {
        await _repository.deleteHomework(item.id);
      }
      await _reload(
        emit,
        message: '${event.items.length} homework records deleted.',
      );
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  Future<void> _saveStatus(HomeworkEntity item, HomeworkStatus status) async {
    final now = DateTime.now();
    await _repository.saveHomework(
      item.copyWith(
        status: status,
        updatedAt: now,
        updatedBy: 'Admin',
        publishedBy: status == HomeworkStatus.published ? 'Admin' : null,
        publishedAt: status == HomeworkStatus.published
            ? now
            : item.publishedAt,
      ),
    );
  }

  Future<void> _reload(Emitter<HomeworkState> emit, {String? message}) async {
    emit(const HomeworkLoading());
    try {
      final values = await _repository.getHomework(
        academicSession: _lastLoad.session,
        status: _lastLoad.status,
        classId: _lastLoad.classId,
        sectionId: _lastLoad.sectionId,
        subjectId: _lastLoad.subjectId,
        teacherId: _lastLoad.teacherId,
      );
      emit(HomeworkLoaded(values, message: message));
    } catch (error) {
      emit(HomeworkError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
