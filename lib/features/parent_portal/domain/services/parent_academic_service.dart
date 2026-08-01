import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_academic_dashboard_entity.dart';

abstract class ParentAcademicService {
  Future<ParentAcademicDashboardEntity> loadDashboard({
    required StudentEntity student,
    required String academicSession,
  });
}
