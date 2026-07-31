import '../entities/staff_entity.dart';
import '../repositories/staff_repository.dart';

class AddStaff {
  const AddStaff(this.repository);

  final StaffRepository repository;

  Future<void> call(StaffEntity staff) {
    return repository.saveStaff(staff);
  }
}