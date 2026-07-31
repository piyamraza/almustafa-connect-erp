import '../entities/academic_year_config_entity.dart';

abstract class AcademicYearConfigRepository {
  Future<AcademicYearConfigEntity?> getBySession(String academicSession);

  Future<void> save(AcademicYearConfigEntity config);

  String generateId();
}
