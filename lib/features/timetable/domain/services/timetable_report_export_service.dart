import 'dart:typed_data';

import '../entities/timetable_report_entity.dart';

abstract class TimetableReportExportService {
  Future<Uint8List> buildPdf(TimetableReportEntity report);

  Future<Uint8List> buildExcel(TimetableReportEntity report);

  Future<void> printPdf(TimetableReportEntity report);

  Future<void> sharePdf(TimetableReportEntity report);

  Future<void> exportExcel(TimetableReportEntity report);
}
