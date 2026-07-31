import '../entities/timetable_configuration_entity.dart';
import '../repositories/timetable_repository.dart';

class SaveTimetableConfiguration {
  const SaveTimetableConfiguration(this._repository);

  final TimetableRepository _repository;

  Future<void> call(TimetableConfigurationEntity configuration) {
    final errors = configuration.validationErrors;
    if (errors.isNotEmpty) {
      throw StateError(errors.join('\n'));
    }

    return _repository.saveConfiguration(configuration);
  }
}
