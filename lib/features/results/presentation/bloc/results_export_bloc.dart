import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/services/results_export_service.dart';
import 'results_export_event.dart';
import 'results_export_state.dart';

class ResultsExportBloc extends Bloc<ResultsExportEvent, ResultsExportState> {
  ResultsExportBloc({required this.exportService})
    : super(const ResultsExportInitial()) {
    on<RunResultsExport>(_onRun);
  }

  final ResultsExportService exportService;

  Future<void> _onRun(
    RunResultsExport event,
    Emitter<ResultsExportState> emit,
  ) async {
    if (event.request.results.isEmpty) {
      emit(
        const ResultsExportFailure(
          'No published results are available to export.',
        ),
      );
      return;
    }
    emit(ResultsExportInProgress(event.action));
    try {
      switch (event.action) {
        case ResultExportAction.exportPdf:
          await exportService.exportPdf(event.request);
        case ResultExportAction.exportExcel:
          await exportService.exportExcel(event.request);
        case ResultExportAction.print:
          await exportService.printPdf(event.request);
        case ResultExportAction.sharePdf:
          await exportService.sharePdf(event.request);
        case ResultExportAction.shareExcel:
          await exportService.shareExcel(event.request);
      }
      emit(ResultsExportSuccess(_message(event.action)));
    } catch (error) {
      emit(ResultsExportFailure(_errorMessage(error)));
    }
  }

  String _message(ResultExportAction action) => switch (action) {
    ResultExportAction.exportPdf => 'PDF export is ready.',
    ResultExportAction.exportExcel => 'Excel export is ready.',
    ResultExportAction.print => 'Print dialog opened.',
    ResultExportAction.sharePdf => 'PDF share action opened.',
    ResultExportAction.shareExcel => 'Excel share action opened.',
  };

  String _errorMessage(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}
