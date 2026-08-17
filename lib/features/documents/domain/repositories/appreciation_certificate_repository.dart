import '../entities/appreciation_certificate_entity.dart';

abstract class AppreciationCertificateRepository {
  Future<List<AppreciationCertificateEntity>> getCertificates();
  Future<void> saveCertificate(AppreciationCertificateEntity value);
  String newId();
}
