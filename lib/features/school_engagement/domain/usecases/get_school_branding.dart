import '../entities/school_branding_entity.dart';
import '../repositories/school_branding_repository.dart';

class GetSchoolBranding {
  final SchoolBrandingRepository _repository;

  const GetSchoolBranding(
    this._repository,
  );

  Future<SchoolBrandingEntity?> call() {
    return _repository.getBranding();
  }
}
