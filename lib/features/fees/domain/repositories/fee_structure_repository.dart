import '../entities/fee_structure_entity.dart';

abstract class FeeStructureRepository {
  Future<List<FeeStructureEntity>> getFeeStructures({
    String? academicSession,
    String? classId,
    String? sectionId,
    bool? isActive,
  });

  Future<void> saveFeeStructure(FeeStructureEntity structure);

  Future<void> deleteFeeStructure(String id);

  String generateId();
}
