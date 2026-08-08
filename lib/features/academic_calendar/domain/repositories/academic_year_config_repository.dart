import '../entities/academic_year_config_entity.dart';

abstract class AcademicYearConfigRepository {
  Future<List<AcademicYearConfigEntity>> getAll();
  Future<AcademicYearConfigEntity?> getBySession(String academicSession);

  Future<void> save(AcademicYearConfigEntity config);

  String generateId();
}
