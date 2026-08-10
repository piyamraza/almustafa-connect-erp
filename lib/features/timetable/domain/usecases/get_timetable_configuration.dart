import '../entities/timetable_configuration_entity.dart';
import '../repositories/timetable_repository.dart';

class GetTimetableConfiguration {
  const GetTimetableConfiguration(this._repository);

  final TimetableRepository _repository;

  Future<TimetableConfigurationEntity?> call({
    required String branchId,
    required String academicSession,
    String? classId,
  }) {
    if (branchId.trim().isEmpty) {
      throw ArgumentError.value(branchId, 'branchId', 'Branch is required.');
    }
    if (academicSession.trim().isEmpty) {
      throw ArgumentError.value(
        academicSession,
        'academicSession',
        'Academic session is required.',
      );
    }

    return _repository.getConfiguration(
      branchId: branchId.trim(),
      academicSession: academicSession.trim(),
      classId: classId?.trim(),
    );
  }
}
