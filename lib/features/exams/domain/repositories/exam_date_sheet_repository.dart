import '../entities/exam_date_sheet_entity.dart';

abstract class ExamDateSheetRepository {
  Future<List<ExamDateSheetEntity>> getDateSheets({
    String? examId,
    String? academicSession,
  });

  Future<ExamDateSheetEntity?> getDateSheetById(String id);

  Future<void> saveDateSheet(ExamDateSheetEntity dateSheet);

  Future<void> deleteDateSheet(String id);

  Future<void> publishDateSheet(String id);

  Future<void> archiveDateSheet(String id);

  String generateDateSheetId();

  String generatePaperId();
}
