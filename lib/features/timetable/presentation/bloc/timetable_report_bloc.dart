import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/timetable_report_entity.dart';
import '../../domain/services/timetable_report_export_service.dart';
import '../../domain/usecases/generate_timetable_report.dart';
import 'timetable_report_event.dart';
import 'timetable_report_state.dart';

class TimetableReportBloc
    extends Bloc<TimetableReportEvent, TimetableReportState> {
  TimetableReportBloc(this._generateTimetableReport, this._exportService)
    : super(const TimetableReportInitial()) {
    on<GenerateTimetableReportEvent>(_onGenerate);
    on<ExportTimetableReportEvent>(_onExport);
  }

  final GenerateTimetableReport _generateTimetableReport;
  final TimetableReportExportService _exportService;

  TimetableReportEntity? _currentReport;

  Future<void> _onGenerate(
    GenerateTimetableReportEvent event,
    Emitter<TimetableReportState> emit,
  ) async {
    emit(const TimetableReportLoading());

    try {
      final report = await _generateTimetableReport(event.request);
      _currentReport = report;
      emit(TimetableReportLoaded(report));
    } catch (error) {
      emit(
        TimetableReportError(_message(error), previousReport: _currentReport),
      );
    }
  }

  Future<void> _onExport(
    ExportTimetableReportEvent event,
    Emitter<TimetableReportState> emit,
  ) async {
    final report = _currentReport;
    if (report == null) {
      emit(const TimetableReportError('Generate a report before exporting.'));
      return;
    }

    emit(TimetableReportExporting(report));

    try {
      final message = switch (event.action) {
        TimetableReportExportAction.printPdf => await _print(report),
        TimetableReportExportAction.sharePdf => await _sharePdf(report),
        TimetableReportExportAction.exportExcel => await _exportExcel(report),
      };

      emit(TimetableReportLoaded(report, successMessage: message));
    } catch (error) {
      emit(TimetableReportError(_message(error), previousReport: report));
    }
  }

  Future<String> _print(TimetableReportEntity report) async {
    await _exportService.printPdf(report);
    return 'Print dialog opened.';
  }

  Future<String> _sharePdf(TimetableReportEntity report) async {
    await _exportService.sharePdf(report);
    return 'PDF report prepared successfully.';
  }

  Future<String> _exportExcel(TimetableReportEntity report) async {
    await _exportService.exportExcel(report);
    return 'Excel report prepared successfully.';
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('Invalid argument: ', '');
}
