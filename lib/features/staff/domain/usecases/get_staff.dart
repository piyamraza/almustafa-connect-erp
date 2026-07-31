import '../entities/staff_entity.dart';
import '../repositories/staff_repository.dart';

class GetStaff {
  const GetStaff(this.repository);

  final StaffRepository repository;

  Future<List<StaffEntity>> call() {
    return repository.getStaff();
  }
}