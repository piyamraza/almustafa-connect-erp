import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_account_entity.dart';
import '../entities/parent_communication_dashboard_entity.dart';

abstract class ParentCommunicationService {
  Future<ParentCommunicationDashboardEntity> loadDashboard({
    required ParentAccountEntity parent,
    required StudentEntity student,
    required String academicSession,
  });

  Future<void> markNoticeRead({
    required String parentId,
    required String noticeId,
    required String parentName,
  });

  Future<void> acknowledgeNotice({
    required String parentId,
    required String noticeId,
    required String parentName,
  });
}
