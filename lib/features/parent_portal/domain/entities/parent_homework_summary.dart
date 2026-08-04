import '../../../homework/domain/entities/homework_entity.dart';

class ParentHomeworkSummary {
  const ParentHomeworkSummary({
    required this.items,
    required this.total,
    required this.dueToday,
    required this.upcoming,
    required this.overdue,
  });

  final List<HomeworkEntity> items;
  final int total;
  final int dueToday;
  final int upcoming;
  final int overdue;
}
