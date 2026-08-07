import '../../domain/entities/school_branding_entity.dart';
import '../../domain/repositories/school_branding_repository.dart';
import '../datasources/school_branding_remote_datasource.dart';
import '../models/school_branding_model.dart';

class SchoolBrandingRepositoryImpl
    implements SchoolBrandingRepository {
  const SchoolBrandingRepositoryImpl(
    this._remoteDataSource,
  );

  final SchoolBrandingRemoteDataSource
      _remoteDataSource;

  @override
  Future<SchoolBrandingEntity?> getBranding() {
    return _remoteDataSource.getBranding();
  }

  @override
  Future<void> saveBranding(
    SchoolBrandingEntity branding,
  ) {
    return _remoteDataSource.saveBranding(
      SchoolBrandingModel.fromEntity(
        branding,
      ),
    );
  }

  @override
  Future<void> updateSchoolLogo(
    String logoUrl,
  ) async {
    final current =
        await _currentOrEmpty();

    await saveBranding(
      current.copyWith(
        schoolLogoUrl: logoUrl,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updatePrincipalSignature(
    String signatureUrl,
    PrincipalSignatureSource source,
  ) async {
    final current =
        await _currentOrEmpty();

    await saveBranding(
      current.copyWith(
        principalSignatureUrl:
            signatureUrl,
        principalSignatureSource:
            source,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> updatePrincipalInformation({
    required String principalName,
    required String principalDesignation,
  }) async {
    final current =
        await _currentOrEmpty();

    await saveBranding(
      current.copyWith(
        principalName:
            principalName.trim(),
        principalDesignation:
            principalDesignation.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deleteSchoolLogo() async {
    final current =
        await _currentOrEmpty();

    await saveBranding(
      current.copyWith(
        schoolLogoUrl: '',
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> deletePrincipalSignature() async {
    final current =
        await _currentOrEmpty();

    await saveBranding(
      current.copyWith(
        principalSignatureUrl: '',
        principalSignatureSource:
            PrincipalSignatureSource.none,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<SchoolBrandingEntity>
      _currentOrEmpty() async {
    final current =
        await getBranding();

    if (current != null) {
      return current;
    }

    return SchoolBrandingEntity(
      schoolName: '',
      schoolLogoUrl: '',
      principalName: '',
      principalDesignation:
          'Principal',
      principalSignatureUrl: '',
      principalSignatureSource:
          PrincipalSignatureSource.none,
      updatedAt: DateTime.now(),
    );
  }
}
