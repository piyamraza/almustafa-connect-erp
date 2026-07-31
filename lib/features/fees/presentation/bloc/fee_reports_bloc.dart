import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fee_report_entity.dart';
import '../../domain/repositories/fee_payment_repository.dart';
import '../../domain/repositories/monthly_fee_due_repository.dart';
import '../../domain/services/fee_report_service.dart';

sealed class FeeReportsEvent {
  const FeeReportsEvent();
}

class LoadFeeReport extends FeeReportsEvent {
  const LoadFeeReport({
    required this.type,
    required this.academicSession,
    required this.startDate,
    required this.endDate,
  });

  final FeeReportType type;
  final String academicSession;
  final DateTime startDate;
  final DateTime endDate;
}

class PrintLoadedFeeReport extends FeeReportsEvent {
  const PrintLoadedFeeReport();
}

class ShareLoadedFeeReport extends FeeReportsEvent {
  const ShareLoadedFeeReport();
}

class ExportLoadedFeeReportExcel extends FeeReportsEvent {
  const ExportLoadedFeeReportExcel();
}

sealed class FeeReportsState {
  const FeeReportsState();
}

class FeeReportsInitial extends FeeReportsState {
  const FeeReportsInitial();
}

class FeeReportsLoading extends FeeReportsState {
  const FeeReportsLoading();
}

class FeeReportsLoaded extends FeeReportsState {
  const FeeReportsLoaded(this.report, {this.message});

  final FeeReportData report;
  final String? message;
}

class FeeReportsError extends FeeReportsState {
  const FeeReportsError(this.message);

  final String message;
}

class FeeReportsBloc extends Bloc<FeeReportsEvent, FeeReportsState> {
  FeeReportsBloc(
    this._dueRepository,
    this._paymentRepository,
    this._reportService,
  ) : super(const FeeReportsInitial()) {
    on<LoadFeeReport>(_load);
    on<PrintLoadedFeeReport>(_print);
    on<ShareLoadedFeeReport>(_share);
    on<ExportLoadedFeeReportExcel>(_excel);
  }

  final MonthlyFeeDueRepository _dueRepository;
  final FeePaymentRepository _paymentRepository;
  final FeeReportService _reportService;
  FeeReportData? _current;

  Future<void> _load(LoadFeeReport event, Emitter<FeeReportsState> emit) async {
    emit(const FeeReportsLoading());

    try {
      final dues = await _dueRepository.getMonthlyDues(
        academicSession: event.academicSession,
      );
      final payments = await _paymentRepository.getPayments(
        academicSession: event.academicSession,
      );

      final filteredDues = dues.where((item) {
        final date = DateTime(item.year, item.month);
        return !date.isBefore(
              DateTime(event.startDate.year, event.startDate.month),
            ) &&
            !date.isAfter(DateTime(event.endDate.year, event.endDate.month));
      }).toList();

      final filteredPayments = payments.where((item) {
        final date = DateTime(
          item.paymentDate.year,
          item.paymentDate.month,
          item.paymentDate.day,
        );
        final start = DateTime(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        );
        final end = DateTime(
          event.endDate.year,
          event.endDate.month,
          event.endDate.day,
          23,
          59,
          59,
        );
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();

      _current = FeeReportData(
        type: event.type,
        dues: filteredDues,
        payments: filteredPayments,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(FeeReportsLoaded(_current!));
    } catch (error) {
      emit(FeeReportsError(_message(error)));
    }
  }

  Future<void> _print(
    PrintLoadedFeeReport event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.printPdf(_requiredReport()),
      message: 'Print preview opened.',
    );
  }

  Future<void> _share(
    ShareLoadedFeeReport event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.sharePdf(_requiredReport()),
      message: 'PDF report prepared.',
    );
  }

  Future<void> _excel(
    ExportLoadedFeeReportExcel event,
    Emitter<FeeReportsState> emit,
  ) async {
    await _run(
      emit,
      action: () => _reportService.exportExcel(_requiredReport()),
      message: 'Excel report prepared.',
    );
  }

  FeeReportData _requiredReport() {
    final report = _current;
    if (report == null) {
      throw StateError('Load a report first.');
    }
    return report;
  }

  Future<void> _run(
    Emitter<FeeReportsState> emit, {
    required Future<void> Function() action,
    required String message,
  }) async {
    final report = _requiredReport();
    emit(const FeeReportsLoading());

    try {
      await action();
      emit(FeeReportsLoaded(report, message: message));
    } catch (error) {
      emit(FeeReportsError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
