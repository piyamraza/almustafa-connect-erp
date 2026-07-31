import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class SaveStaffSalary {
  const SaveStaffSalary(this.repository);

  final StaffSalaryRepository repository;

  Future<void> call(
    StaffSalaryEntity salary,
  ) {
    return repository.saveSalary(salary);
  }
}