import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_account_entity.dart';

abstract class ParentPortalRepository {
  Future<List<ParentAccountEntity>> getParents();

  Future<ParentAccountEntity?> getParentById(String id);

  Future<ParentAccountEntity?> getParentByUserId(String userId);

  Future<List<StudentEntity>> getLinkedStudents(ParentAccountEntity parent);

  Future<List<StudentEntity>> findStudentsByGuardian({
    required String mobileNumber,
    required String email,
  });

  Future<List<ParentAccountEntity>> getParentsForStudent(String studentId);

  Future<bool> isUserLinkedToAnotherParent(
    String userId, {
    String? excludingParentId,
  });

  Future<bool> canParentAccessStudent({
    required String parentUserId,
    required String studentId,
  });

  Future<void> saveParent(ParentAccountEntity parent);

  Future<void> setParentStatus({
    required String parentId,
    required String accountStatus,
  });

  Future<void> deleteParent(String id);

  String generateId();
}
