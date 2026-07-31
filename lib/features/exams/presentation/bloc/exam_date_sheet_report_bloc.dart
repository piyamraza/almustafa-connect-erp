import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_date_sheet_report_entity.dart';
import '../../domain/services/exam_date_sheet_report_service.dart';

sealed class ExamDateSheetReportEvent {
  const ExamDateSheetReportEvent();
}

class ExportExamDateSheetReport extends ExamDateSheetReportEvent {
  const ExportExamDateSheetReport({
    required this.request,
    required this.action,
  });

  final ExamDateSheetReportRequest request;
  final ExamDateSheetReportAction action;
}

sealed class ExamDateSheetReportState {
  const ExamDateSheetReportState();
}

class ExamDateSheetReportInitial extends ExamDateSheetReportState {
  const ExamDateSheetReportInitial();
}

class ExamDateSheetReportLoading extends ExamDateSheetReportState {
  const ExamDateSheetReportLoading();
}

class ExamDateSheetReportSuccess extends ExamDateSheetReportState {
  const ExamDateSheetReportSuccess(this.message);

  final String message;
}

class ExamDateSheetReportError extends ExamDateSheetReportState {
  const ExamDateSheetReportError(this.message);

  final String message;
}

class ExamDateSheetReportBloc
    extends Bloc<ExamDateSheetReportEvent, ExamDateSheetReportState> {
  ExamDateSheetReportBloc(this._service)
    : super(const ExamDateSheetReportInitial()) {
    on<ExportExamDateSheetReport>(_export);
  }

  final ExamDateSheetReportService _service;

  Future<void> _export(
    ExportExamDateSheetReport event,
    Emitter<ExamDateSheetReportState> emit,
  ) async {
    emit(const ExamDateSheetReportLoading());

    try {
      final message = switch (event.action) {
        ExamDateSheetReportAction.printPdf => await _print(event.request),
        ExamDateSheetReportAction.sharePdf => await _share(event.request),
        ExamDateSheetReportAction.exportExcel => await _excel(event.request),
      };
      emit(ExamDateSheetReportSuccess(message));
    } catch (error) {
      emit(
        ExamDateSheetReportError(
          error
              .toString()
              .replaceFirst('StateError: ', '')
              .replaceFirst('Invalid argument(s): ', ''),
        ),
      );
    }
  }

  Future<String> _print(ExamDateSheetReportRequest request) async {
    await _service.printPdf(request);
    return 'Print preview opened.';
  }

  Future<String> _share(ExamDateSheetReportRequest request) async {
    await _service.sharePdf(request);
    return 'PDF report prepared successfully.';
  }

  Future<String> _excel(ExamDateSheetReportRequest request) async {
    await _service.exportExcel(request);
    return 'Excel report prepared successfully.';
  }
}
