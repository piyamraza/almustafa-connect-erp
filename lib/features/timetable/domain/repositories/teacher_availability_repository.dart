import '../entities/teacher_availability_entity.dart';

abstract class TeacherAvailabilityRepository {
  Future<List<TeacherAvailabilityEntity>> getAvailabilities({
    required String branchId,
    required String academicSession,
  });

  Future<void> saveAvailability(TeacherAvailabilityEntity availability);

  Future<void> deleteAvailability(String id);

  String generateId();
}
