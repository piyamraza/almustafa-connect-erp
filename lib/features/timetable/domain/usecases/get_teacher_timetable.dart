import '../entities/class_timetable_entry_entity.dart';
import '../repositories/timetable_repository.dart';

class GetTeacherTimetable {
  const GetTeacherTimetable(this._repository);

  final TimetableRepository _repository;

  Future<List<ClassTimetableEntryEntity>> call({
    required String branchId,
    required String academicSession,
    required String teacherId,
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
    if (teacherId.trim().isEmpty) {
      throw ArgumentError.value(teacherId, 'teacherId', 'Teacher is required.');
    }

    return _repository.getTeacherTimetable(
      branchId: branchId.trim(),
      academicSession: academicSession.trim(),
      teacherId: teacherId.trim(),
    );
  }
}
