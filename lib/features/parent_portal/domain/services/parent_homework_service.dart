import '../entities/parent_homework_summary.dart';

abstract class ParentHomeworkService {
  Future<ParentHomeworkSummary> loadHomework({
    required String academicSession,
    required String classId,
    required String sectionId,
  });
}
