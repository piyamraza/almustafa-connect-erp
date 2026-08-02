import '../../domain/entities/exam_subject_setup_entity.dart';
import '../../domain/repositories/exam_subject_setup_repository.dart';
import '../datasources/exam_subject_setup_remote_datasource.dart';
import '../models/exam_subject_setup_model.dart';

class ExamSubjectSetupRepositoryImpl implements ExamSubjectSetupRepository {
  ExamSubjectSetupRepositoryImpl({required this._source});
  final ExamSubjectSetupRemoteDataSource _source;
  @override
  Future<List<ExamSubjectSetupEntity>> getSetups() => _source.getSetups();
  @override
  Future<List<ExamSubjectSetupEntity>> getSetupsForExam(String examId) =>
      _source.getSetupsForExam(examId);
  @override
  Future<void> createSetups(List<ExamSubjectSetupEntity> setups) =>
      _source.createSetups(
        setups.map(ExamSubjectSetupModel.fromEntity).toList(growable: false),
      );
  @override
  Future<void> updateSetup(ExamSubjectSetupEntity setup) =>
      _source.updateSetup(ExamSubjectSetupModel.fromEntity(setup));
  @override
  Future<void> deleteSetup(String id) => _source.deleteSetup(id);
  @override
  Future<void> synchronizeExamSetups({
    required String examId,
    required List<ExamSubjectSetupEntity> selectedSetups,
  }) => _source.synchronizeExamSetups(
    examId: examId,
    selectedSetups: selectedSetups
        .map(ExamSubjectSetupModel.fromEntity)
        .toList(growable: false),
  );
  @override
  String generateId() => _source.generateId();
}
