import '../repositories/staff_repository.dart';

class GenerateStaffId {
  const GenerateStaffId(this.repository);

  final StaffRepository repository;

  String call() {
    return repository.generateStaffId();
  }
}