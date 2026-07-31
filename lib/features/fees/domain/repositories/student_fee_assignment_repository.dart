import '../entities/student_fee_assignment_entity.dart';

abstract class StudentFeeAssignmentRepository {
  Future<List<StudentFeeAssignmentEntity>> getAssignments({
    String? academicSession,
    String? studentId,
    bool? isActive,
  });

  Future<void> saveAssignment(StudentFeeAssignmentEntity assignment);

  Future<void> deleteAssignment(String id);

  String generateId();
}
