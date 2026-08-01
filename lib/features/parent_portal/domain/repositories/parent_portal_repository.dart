import '../../../students/domain/entities/student_entity.dart';
import '../entities/parent_account_entity.dart';

abstract class ParentPortalRepository {
  Future<List<ParentAccountEntity>> getParents();

  Future<ParentAccountEntity?> getParentById(String id);

  Future<List<StudentEntity>> getLinkedStudents(ParentAccountEntity parent);

  Future<List<StudentEntity>> findStudentsByGuardian({
    required String mobileNumber,
    required String email,
  });

  Future<void> saveParent(ParentAccountEntity parent);

  Future<void> deleteParent(String id);

  String generateId();
}
