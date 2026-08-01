import '../entities/homework_entity.dart';

abstract class HomeworkRepository {
  Future<List<HomeworkEntity>> getHomework({
    required String academicSession,
    HomeworkStatus? status,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? teacherId,
    DateTime? fromDate,
    DateTime? toDate,
  });

  Future<void> saveHomework(HomeworkEntity homework);
  Future<void> deleteHomework(String id);
  Future<bool> duplicateExists(HomeworkEntity homework);
  String generateId();
}
