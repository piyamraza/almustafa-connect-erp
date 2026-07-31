import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class GetStaffSalaryByStaff {
  const GetStaffSalaryByStaff(this.repository);

  final StaffSalaryRepository repository;

  Future<List<StaffSalaryEntity>> call({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getSalariesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}