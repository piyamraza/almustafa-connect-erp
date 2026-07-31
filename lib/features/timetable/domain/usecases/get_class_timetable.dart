import '../entities/class_timetable_entry_entity.dart';
import '../repositories/timetable_repository.dart';

class GetClassTimetable {
  const GetClassTimetable(this._repository);

  final TimetableRepository _repository;

  Future<List<ClassTimetableEntryEntity>> call({
    required String branchId,
    required String academicSession,
    required String classId,
    required String sectionId,
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
    if (classId.trim().isEmpty) {
      throw ArgumentError.value(classId, 'classId', 'Class is required.');
    }
    if (sectionId.trim().isEmpty) {
      throw ArgumentError.value(sectionId, 'sectionId', 'Section is required.');
    }

    return _repository.getClassTimetable(
      branchId: branchId.trim(),
      academicSession: academicSession.trim(),
      classId: classId.trim(),
      sectionId: sectionId.trim(),
    );
  }
}
