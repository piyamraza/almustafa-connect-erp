import '../repositories/timetable_repository.dart';

class DeleteClassTimetableEntry {
  const DeleteClassTimetableEntry(this._repository);

  final TimetableRepository _repository;

  Future<void> call(String entryId) {
    if (entryId.trim().isEmpty) {
      throw ArgumentError.value(
        entryId,
        'entryId',
        'Timetable entry ID is required.',
      );
    }

    return _repository.deleteClassTimetableEntry(entryId.trim());
  }
}
