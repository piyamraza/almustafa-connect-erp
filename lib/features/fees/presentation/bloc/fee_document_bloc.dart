import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fee_document_request_entity.dart';
import '../../domain/services/fee_document_service.dart';

sealed class FeeDocumentEvent {
  const FeeDocumentEvent();
}

class PrintFeeChallan extends FeeDocumentEvent {
  const PrintFeeChallan(this.request);
  final FeeChallanDocumentRequest request;
}

class ShareFeeChallan extends FeeDocumentEvent {
  const ShareFeeChallan(this.request);
  final FeeChallanDocumentRequest request;
}

class PrintFeeReceipt extends FeeDocumentEvent {
  const PrintFeeReceipt(this.request);
  final FeeReceiptDocumentRequest request;
}

class ShareFeeReceipt extends FeeDocumentEvent {
  const ShareFeeReceipt(this.request);
  final FeeReceiptDocumentRequest request;
}

sealed class FeeDocumentState {
  const FeeDocumentState();
}

class FeeDocumentInitial extends FeeDocumentState {
  const FeeDocumentInitial();
}

class FeeDocumentLoading extends FeeDocumentState {
  const FeeDocumentLoading();
}

class FeeDocumentSuccess extends FeeDocumentState {
  const FeeDocumentSuccess(this.message);
  final String message;
}

class FeeDocumentError extends FeeDocumentState {
  const FeeDocumentError(this.message);
  final String message;
}

class FeeDocumentBloc extends Bloc<FeeDocumentEvent, FeeDocumentState> {
  FeeDocumentBloc(this._service) : super(const FeeDocumentInitial()) {
    on<PrintFeeChallan>(_printChallan);
    on<ShareFeeChallan>(_shareChallan);
    on<PrintFeeReceipt>(_printReceipt);
    on<ShareFeeReceipt>(_shareReceipt);
  }

  final FeeDocumentService _service;

  Future<void> _printChallan(
    PrintFeeChallan event,
    Emitter<FeeDocumentState> emit,
  ) async {
    await _run(
      emit,
      action: () => _service.printChallan(event.request),
      message: 'Challan print preview opened.',
    );
  }

  Future<void> _shareChallan(
    ShareFeeChallan event,
    Emitter<FeeDocumentState> emit,
  ) async {
    await _run(
      emit,
      action: () => _service.shareChallan(event.request),
      message: 'Challan PDF prepared.',
    );
  }

  Future<void> _printReceipt(
    PrintFeeReceipt event,
    Emitter<FeeDocumentState> emit,
  ) async {
    await _run(
      emit,
      action: () => _service.printReceipt(event.request),
      message: 'Receipt print preview opened.',
    );
  }

  Future<void> _shareReceipt(
    ShareFeeReceipt event,
    Emitter<FeeDocumentState> emit,
  ) async {
    await _run(
      emit,
      action: () => _service.shareReceipt(event.request),
      message: 'Receipt PDF prepared.',
    );
  }

  Future<void> _run(
    Emitter<FeeDocumentState> emit, {
    required Future<void> Function() action,
    required String message,
  }) async {
    emit(const FeeDocumentLoading());
    try {
      await action();
      emit(FeeDocumentSuccess(message));
    } catch (error) {
      emit(FeeDocumentError(error.toString().replaceFirst('StateError: ', '')));
    }
  }
}
