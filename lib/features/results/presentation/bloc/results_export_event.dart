import 'package:equatable/equatable.dart';

import '../../domain/entities/result_export_request.dart';

enum ResultExportAction { exportPdf, exportExcel, print, sharePdf, shareExcel }

sealed class ResultsExportEvent extends Equatable {
  const ResultsExportEvent();

  @override
  List<Object?> get props => const [];
}

class RunResultsExport extends ResultsExportEvent {
  const RunResultsExport({required this.action, required this.request});

  final ResultExportAction action;
  final ResultExportRequest request;

  @override
  List<Object?> get props => [action, request];
}
