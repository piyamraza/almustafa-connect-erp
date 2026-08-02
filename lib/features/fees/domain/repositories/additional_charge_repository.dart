import '../entities/additional_charge_entity.dart';

abstract class AdditionalChargeRepository {
  Future<List<AdditionalChargeEntity>> getCharges({
    required String academicSession,
    AdditionalChargeScope? scope,
    AdditionalChargeCategory? category,
    bool? isActive,
  });
  Future<AdditionalChargeEntity?> getChargeById(String id);
  Future<void> saveCharge(AdditionalChargeEntity charge);
  Future<void> deleteCharge(String id);
  Future<void> markGenerated(String id, int studentCount);
  String generateId();
}
