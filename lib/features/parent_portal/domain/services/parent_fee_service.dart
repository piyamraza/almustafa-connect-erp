import '../entities/parent_fee_summary.dart';

abstract class ParentFeeService {
  Future<ParentFeeSummary> loadStudentFeeSummary({
    required String studentId,
    String? academicSession,
  });
}
