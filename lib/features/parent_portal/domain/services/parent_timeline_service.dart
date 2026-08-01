import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_account_entity.dart';
import '../entities/parent_timeline_item_entity.dart';

abstract class ParentTimelineService {
  Future<List<ParentTimelineItemEntity>> loadTimeline({
    required ParentAccountEntity parent,
    required StudentEntity student,
    required String academicSession,
  });
}
