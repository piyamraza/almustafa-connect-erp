import 'dart:typed_data';

import '../entities/result_export_request.dart';

abstract class ResultsExportService {
  Future<Uint8List> buildPdf(ResultExportRequest request);

  Future<Uint8List> buildExcel(ResultExportRequest request);

  Future<void> exportPdf(ResultExportRequest request);

  Future<void> exportExcel(ResultExportRequest request);

  Future<void> printPdf(ResultExportRequest request);

  Future<void> sharePdf(ResultExportRequest request);

  Future<void> shareExcel(ResultExportRequest request);

  String fileName(ResultExportRequest request, String extension);
}
