import '../entities/exam_mark_entity.dart';

abstract class ExamMarkRepository {
  Future<List<ExamMarkEntity>> getMarksForEntry(String entryKey);

  Future<List<ExamMarkEntity>> getMarksForExam(String examId);

  Future<void> saveMarks(List<ExamMarkEntity> marks);
  Future<void> deleteMark(String id);
}
