import '../entities/staff_entity.dart';

abstract class StaffRepository {
  Future<List<StaffEntity>> getStaff();

  Future<void> saveStaff(StaffEntity staff);

  Future<void> deleteStaff(String id);

  String generateStaffId();
}