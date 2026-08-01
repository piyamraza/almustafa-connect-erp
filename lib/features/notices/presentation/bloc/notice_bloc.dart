import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notice_entity.dart';
import '../../domain/repositories/notice_repository.dart';

sealed class NoticeEvent {
  const NoticeEvent();
}

class LoadNotices extends NoticeEvent {
  const LoadNotices(
    this.academicSession, {
    this.status,
    this.audienceType,
    this.priority,
  });

  final String academicSession;
  final NoticeStatus? status;
  final NoticeAudienceType? audienceType;
  final NoticePriority? priority;
}

class SaveNotice extends NoticeEvent {
  const SaveNotice(this.notice);
  final NoticeEntity notice;
}

class DeleteNotice extends NoticeEvent {
  const DeleteNotice(this.id);
  final String id;
}

class ChangeNoticeStatus extends NoticeEvent {
  const ChangeNoticeStatus(this.notice, this.status);
  final NoticeEntity notice;
  final NoticeStatus status;
}

sealed class NoticeState {
  const NoticeState();
}

class NoticeInitial extends NoticeState {
  const NoticeInitial();
}

class NoticeLoading extends NoticeState {
  const NoticeLoading();
}

class NoticeLoaded extends NoticeState {
  const NoticeLoaded(this.items, {this.message});
  final List<NoticeEntity> items;
  final String? message;
}

class NoticeError extends NoticeState {
  const NoticeError(this.message);
  final String message;
}

class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  NoticeBloc(this._repository) : super(const NoticeInitial()) {
    on<LoadNotices>(_load);
    on<SaveNotice>(_save);
    on<DeleteNotice>(_delete);
    on<ChangeNoticeStatus>(_changeStatus);
  }

  final NoticeRepository _repository;
  LoadNotices _lastLoad = const LoadNotices('2026-2027');

  Future<void> _load(LoadNotices event, Emitter<NoticeState> emit) async {
    _lastLoad = event;
    await _reload(emit);
  }

  Future<void> _save(SaveNotice event, Emitter<NoticeState> emit) async {
    emit(const NoticeLoading());
    try {
      await _repository.saveNotice(event.notice);
      await _reload(emit, message: 'Notice saved.');
    } catch (error) {
      emit(NoticeError(_message(error)));
    }
  }

  Future<void> _delete(DeleteNotice event, Emitter<NoticeState> emit) async {
    emit(const NoticeLoading());
    try {
      await _repository.deleteNotice(event.id);
      await _reload(emit, message: 'Notice deleted.');
    } catch (error) {
      emit(NoticeError(_message(error)));
    }
  }

  Future<void> _changeStatus(
    ChangeNoticeStatus event,
    Emitter<NoticeState> emit,
  ) async {
    emit(const NoticeLoading());
    try {
      final now = DateTime.now();
      await _repository.saveNotice(
        event.notice.copyWith(
          status: event.status,
          updatedBy: 'Admin',
          updatedAt: now,
          publishedBy: event.status == NoticeStatus.published ? 'Admin' : null,
          publishedAt: event.status == NoticeStatus.published ? now : null,
        ),
      );
      await _reload(emit, message: 'Notice status updated.');
    } catch (error) {
      emit(NoticeError(_message(error)));
    }
  }

  Future<void> _reload(Emitter<NoticeState> emit, {String? message}) async {
    emit(const NoticeLoading());
    try {
      final values = await _repository.getNotices(
        academicSession: _lastLoad.academicSession,
        status: _lastLoad.status,
        audienceType: _lastLoad.audienceType,
        priority: _lastLoad.priority,
      );
      emit(NoticeLoaded(values, message: message));
    } catch (error) {
      emit(NoticeError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
