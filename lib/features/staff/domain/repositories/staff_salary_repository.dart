import '../entities/staff_salary_entity.dart';

abstract class StaffSalaryRepository {
  Future<List<StaffSalaryEntity>> getSalariesByMonth(
    DateTime month,
  );

  Future<List<StaffSalaryEntity>> getSalariesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> saveSalary(
    StaffSalaryEntity salary,
  );

  Future<void> saveSalaries(
    List<StaffSalaryEntity> salaries,
  );

  Future<void> updatePaymentStatus({
    required String salaryId,
    required StaffSalaryPaymentStatus paymentStatus,
    required DateTime? paymentDate,
    required StaffSalaryPaymentMethod? paymentMethod,
    required String paymentReference,
    required DateTime updatedAt,
  });
}