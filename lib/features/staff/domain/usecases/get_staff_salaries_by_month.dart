import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class GetStaffSalariesByMonth {
  const GetStaffSalariesByMonth(this.repository);

  final StaffSalaryRepository repository;

  Future<List<StaffSalaryEntity>> call(
    DateTime month,
  ) {
    return repository.getSalariesByMonth(month);
  }
}