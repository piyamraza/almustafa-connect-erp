import '../entities/staff_salary_entity.dart';
import '../repositories/staff_salary_repository.dart';

class UpdateStaffSalaryPaymentStatus {
  const UpdateStaffSalaryPaymentStatus(this.repository);

  final StaffSalaryRepository repository;

  Future<void> call({
    required String salaryId,
    required StaffSalaryPaymentStatus paymentStatus,
    required DateTime? paymentDate,
    required StaffSalaryPaymentMethod? paymentMethod,
    required String paymentReference,
  }) {
    return repository.updatePaymentStatus(
      salaryId: salaryId,
      paymentStatus: paymentStatus,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference.trim(),
      updatedAt: DateTime.now(),
    );
  }
}