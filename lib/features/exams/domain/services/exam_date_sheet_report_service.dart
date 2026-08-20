import '../entities/exam_date_sheet_report_entity.dart';

abstract class ExamDateSheetReportService {
  Future<void> printPdf(ExamDateSheetReportRequest request);

  Future<void> sharePdf(ExamDateSheetReportRequest request);

  Future<void> downloadAllClassesPdf(ExamDateSheetReportRequest request);

  Future<void> exportExcel(ExamDateSheetReportRequest request);
}
