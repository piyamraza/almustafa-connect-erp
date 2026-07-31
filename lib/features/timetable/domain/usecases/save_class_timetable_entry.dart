import '../entities/class_timetable_entry_entity.dart';
import '../repositories/timetable_repository.dart';

class SaveClassTimetableEntry {
  const SaveClassTimetableEntry(this._repository);

  final TimetableRepository _repository;

  Future<void> call(ClassTimetableEntryEntity entry) {
    final errors = entry.validationErrors;
    if (errors.isNotEmpty) {
      throw StateError(errors.join('\n'));
    }

    return _repository.saveClassTimetableEntry(entry);
  }
}
