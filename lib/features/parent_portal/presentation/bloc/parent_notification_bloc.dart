import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/parent_notification_entity.dart';
import '../../domain/repositories/parent_notification_repository.dart';

sealed class ParentNotificationEvent {
  const ParentNotificationEvent();
}

class LoadParentNotifications extends ParentNotificationEvent {
  const LoadParentNotifications({
    required this.parentId,
    this.studentId,
    this.type,
    this.isRead,
  });

  final String parentId;
  final String? studentId;
  final ParentNotificationType? type;
  final bool? isRead;
}

class MarkParentNotificationRead extends ParentNotificationEvent {
  const MarkParentNotificationRead(this.id);
  final String id;
}

class MarkAllParentNotificationsRead extends ParentNotificationEvent {
  const MarkAllParentNotificationsRead({
    required this.parentId,
    this.studentId,
  });

  final String parentId;
  final String? studentId;
}

class DeleteParentNotification extends ParentNotificationEvent {
  const DeleteParentNotification(this.id);
  final String id;
}

sealed class ParentNotificationState {
  const ParentNotificationState();
}

class ParentNotificationInitial extends ParentNotificationState {
  const ParentNotificationInitial();
}

class ParentNotificationLoading extends ParentNotificationState {
  const ParentNotificationLoading();
}

class ParentNotificationLoaded extends ParentNotificationState {
  const ParentNotificationLoaded(this.items);
  final List<ParentNotificationEntity> items;
}

class ParentNotificationError extends ParentNotificationState {
  const ParentNotificationError(this.message);
  final String message;
}

class ParentNotificationBloc
    extends Bloc<ParentNotificationEvent, ParentNotificationState> {
  ParentNotificationBloc(this._repository)
    : super(const ParentNotificationInitial()) {
    on<LoadParentNotifications>(_load);
    on<MarkParentNotificationRead>(_markRead);
    on<MarkAllParentNotificationsRead>(_markAllRead);
    on<DeleteParentNotification>(_delete);
  }

  final ParentNotificationRepository _repository;
  LoadParentNotifications? _lastLoad;

  Future<void> _load(
    LoadParentNotifications event,
    Emitter<ParentNotificationState> emit,
  ) async {
    _lastLoad = event;
    emit(const ParentNotificationLoading());
    try {
      emit(
        ParentNotificationLoaded(
          await _repository.getNotifications(
            parentId: event.parentId,
            studentId: event.studentId,
            type: event.type,
            isRead: event.isRead,
          ),
        ),
      );
    } catch (error) {
      emit(ParentNotificationError(error.toString()));
    }
  }

  Future<void> _markRead(
    MarkParentNotificationRead event,
    Emitter<ParentNotificationState> emit,
  ) async {
    await _repository.markRead(event.id);
    await _reload();
  }

  Future<void> _markAllRead(
    MarkAllParentNotificationsRead event,
    Emitter<ParentNotificationState> emit,
  ) async {
    await _repository.markAllRead(
      parentId: event.parentId,
      studentId: event.studentId,
    );
    await _reload();
  }

  Future<void> _delete(
    DeleteParentNotification event,
    Emitter<ParentNotificationState> emit,
  ) async {
    await _repository.deleteNotification(event.id);
    await _reload();
  }

  Future<void> _reload() async {
    final last = _lastLoad;
    if (last != null) add(last);
  }
}
