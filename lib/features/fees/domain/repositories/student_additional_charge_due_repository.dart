import '../entities/student_additional_charge_due_entity.dart';

abstract class StudentAdditionalChargeDueRepository {
  Future<List<StudentAdditionalChargeDueEntity>> getDues({
    String? academicSession,
    String? chargeId,
    String? classId,
    String? sectionId,
    StudentAdditionalChargeDueStatus? status,
  });
  Future<List<StudentAdditionalChargeDueEntity>> getStudentDues(
    String studentId, {
    String? academicSession,
  });
  Future<void> saveDue(StudentAdditionalChargeDueEntity due);
  Future<void> saveDuesBatch(List<StudentAdditionalChargeDueEntity> dues);
  Future<void> updateDue(StudentAdditionalChargeDueEntity due);
  Future<void> deleteDue(String id);
  Future<bool> chargeAlreadyGeneratedForStudent(
    String chargeId,
    String studentId,
  );
  String generateId();
}
