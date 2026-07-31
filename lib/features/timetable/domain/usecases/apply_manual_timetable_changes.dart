import '../entities/manual_timetable_change_entity.dart';
import '../repositories/timetable_repository.dart';

class ApplyManualTimetableChanges {
  const ApplyManualTimetableChanges(this._repository);

  final TimetableRepository _repository;

  Future<void> call(ManualTimetableChangeSet changes) {
    return _repository.applyManualTimetableChanges(changes);
  }
}
