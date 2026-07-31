import '../entities/staff_entity.dart';
import '../repositories/staff_repository.dart';

class ToggleStaffStatus {
  const ToggleStaffStatus(this.repository);

  final StaffRepository repository;

  Future<void> call({
    required StaffEntity staff,
    required bool isActive,
  }) {
    final updatedStaff = staff.copyWith(
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    return repository.saveStaff(updatedStaff);
  }
}