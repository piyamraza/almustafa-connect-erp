import '../entities/exam_entity.dart';

abstract class ExamRepository {
  Future<List<ExamEntity>> getExams({
    String? academicSession,
    bool? isActive,
  });

  Future<ExamEntity?> getExamById(String id);

  Future<void> createExam(ExamEntity exam);

  Future<void> updateExam(ExamEntity exam);

  Future<void> deleteExam(String id);

  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  });

  String generateId();
}
