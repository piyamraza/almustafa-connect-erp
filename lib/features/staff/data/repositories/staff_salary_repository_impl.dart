import '../../domain/entities/staff_salary_entity.dart';
import '../../domain/repositories/staff_salary_repository.dart';
import '../datasources/staff_salary_remote_datasource.dart';
import '../models/staff_salary_model.dart';

class StaffSalaryRepositoryImpl
    implements StaffSalaryRepository {
  const StaffSalaryRepositoryImpl({
    required this._remoteDataSource,
  });

  final StaffSalaryRemoteDataSource _remoteDataSource;

  @override
  Future<List<StaffSalaryEntity>> getSalariesByMonth(
    DateTime month,
  ) {
    return _remoteDataSource.getSalariesByMonth(month);
  }

  @override
  Future<List<StaffSalaryEntity>> getSalariesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getSalariesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> saveSalary(
    StaffSalaryEntity salary,
  ) {
    return _remoteDataSource.saveSalary(
      StaffSalaryModel.fromEntity(salary),
    );
  }

  @override
  Future<void> saveSalaries(
    List<StaffSalaryEntity> salaries,
  ) {
    return _remoteDataSource.saveSalaries(
      salaries
          .map(StaffSalaryModel.fromEntity)
          .toList(growable: false),
    );
  }

  @override
  Future<void> updatePaymentStatus({
    required String salaryId,
    required StaffSalaryPaymentStatus paymentStatus,
    required DateTime? paymentDate,
    required StaffSalaryPaymentMethod? paymentMethod,
    required String paymentReference,
    required DateTime updatedAt,
  }) {
    return _remoteDataSource.updatePaymentStatus(
      salaryId: salaryId,
      paymentStatus: paymentStatus,
      paymentDate: paymentDate,
      paymentMethod: paymentMethod,
      paymentReference: paymentReference,
      updatedAt: updatedAt,
    );
  }
}