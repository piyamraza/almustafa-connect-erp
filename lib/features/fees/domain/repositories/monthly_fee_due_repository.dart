import '../entities/monthly_fee_due_entity.dart';

abstract class MonthlyFeeDueRepository {
  Future<List<MonthlyFeeDueEntity>> getMonthlyDues({
    String? academicSession,
    int? month,
    int? year,
    String? studentId,
  });

  Future<void> saveMonthlyDues(List<MonthlyFeeDueEntity> dues);

  Future<void> deleteMonthlyDue(String id);

  String generateId();
}
