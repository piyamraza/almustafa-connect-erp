import '../repositories/staff_repository.dart';

class DeleteStaff {
  const DeleteStaff(this.repository);

  final StaffRepository repository;

  Future<void> call(String id) {
    return repository.deleteStaff(id);
  }
}