import '../entities/fee_report_entity.dart';

abstract class FeeReportService {
  Future<void> printPdf(FeeReportData report);

  Future<void> sharePdf(FeeReportData report);

  Future<void> exportExcel(FeeReportData report);
}
