import '../entities/exam_entity.dart'; abstract class ExamRepository { Future<List<ExamEntity>> getExams(); Future<void> save(ExamEntity exam); String generateId(); }
