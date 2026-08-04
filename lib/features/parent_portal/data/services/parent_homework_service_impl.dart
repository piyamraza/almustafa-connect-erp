import '../../../homework/domain/entities/homework_entity.dart';
import '../../../homework/domain/repositories/homework_repository.dart';
import '../../domain/entities/parent_homework_summary.dart';
import '../../domain/services/parent_homework_service.dart';

class ParentHomeworkServiceImpl implements ParentHomeworkService {
  const ParentHomeworkServiceImpl(this._repository);

  final HomeworkRepository _repository;

  @override
  Future<ParentHomeworkSummary> loadHomework({
    required String academicSession,
    required String classId,
    required String sectionId,
  }) async {
    final values = await _repository.getHomework(
      academicSession: academicSession,
      status: HomeworkStatus.published,
      classId: classId.trim(),
      sectionId: sectionId.trim(),
    );

    final items = values.toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final endOfToday = DateTime(today.year, today.month, today.day, 23, 59, 59);

    var dueToday = 0;
    var upcoming = 0;
    var overdue = 0;

    for (final item in items) {
      if (item.dueDate.isBefore(startOfToday)) {
        overdue++;
      } else if (!item.dueDate.isAfter(endOfToday)) {
        dueToday++;
      } else {
        upcoming++;
      }
    }

    return ParentHomeworkSummary(
      items: List<HomeworkEntity>.unmodifiable(items),
      total: items.length,
      dueToday: dueToday,
      upcoming: upcoming,
      overdue: overdue,
    );
  }
}
