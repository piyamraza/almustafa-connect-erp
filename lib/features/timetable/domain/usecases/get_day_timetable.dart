import '../entities/class_timetable_entry_entity.dart';
import '../repositories/timetable_repository.dart';

class GetDayTimetable {
  const GetDayTimetable(this._repository);

  final TimetableRepository _repository;

  Future<List<ClassTimetableEntryEntity>> call({
    required String branchId,
    required String academicSession,
    required int weekday,
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
    if (weekday < DateTime.monday || weekday > DateTime.sunday) {
      throw ArgumentError.value(weekday, 'weekday', 'Weekday is invalid.');
    }

    return _repository.getDayTimetable(
      branchId: branchId.trim(),
      academicSession: academicSession.trim(),
      weekday: weekday,
    );
  }
}
