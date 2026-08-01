import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notice_receipt_entity.dart';
import '../../domain/repositories/notice_receipt_repository.dart';

sealed class NoticeReceiptEvent {
  const NoticeReceiptEvent();
}

class LoadNoticeReceipts extends NoticeReceiptEvent {
  const LoadNoticeReceipts({this.noticeId, this.status});

  final String? noticeId;
  final NoticeDeliveryStatus? status;
}

class SaveNoticeReceipt extends NoticeReceiptEvent {
  const SaveNoticeReceipt(this.receipt);

  final NoticeReceiptEntity receipt;
}

sealed class NoticeReceiptState {
  const NoticeReceiptState();
}

class NoticeReceiptInitial extends NoticeReceiptState {
  const NoticeReceiptInitial();
}

class NoticeReceiptLoading extends NoticeReceiptState {
  const NoticeReceiptLoading();
}

class NoticeReceiptLoaded extends NoticeReceiptState {
  const NoticeReceiptLoaded(this.items, {this.message});

  final List<NoticeReceiptEntity> items;
  final String? message;
}

class NoticeReceiptError extends NoticeReceiptState {
  const NoticeReceiptError(this.message);

  final String message;
}

class NoticeReceiptBloc extends Bloc<NoticeReceiptEvent, NoticeReceiptState> {
  NoticeReceiptBloc(this._repository) : super(const NoticeReceiptInitial()) {
    on<LoadNoticeReceipts>(_load);
    on<SaveNoticeReceipt>(_save);
  }

  final NoticeReceiptRepository _repository;
  LoadNoticeReceipts _lastLoad = const LoadNoticeReceipts();

  Future<void> _load(
    LoadNoticeReceipts event,
    Emitter<NoticeReceiptState> emit,
  ) async {
    _lastLoad = event;
    await _reload(emit);
  }

  Future<void> _save(
    SaveNoticeReceipt event,
    Emitter<NoticeReceiptState> emit,
  ) async {
    emit(const NoticeReceiptLoading());
    try {
      await _repository.saveReceipt(event.receipt);
      await _reload(emit, message: 'Receipt updated.');
    } catch (error) {
      emit(NoticeReceiptError(error.toString()));
    }
  }

  Future<void> _reload(
    Emitter<NoticeReceiptState> emit, {
    String? message,
  }) async {
    emit(const NoticeReceiptLoading());
    try {
      final values = await _repository.getReceipts(
        noticeId: _lastLoad.noticeId,
        status: _lastLoad.status,
      );
      emit(NoticeReceiptLoaded(values, message: message));
    } catch (error) {
      emit(NoticeReceiptError(error.toString()));
    }
  }
}
