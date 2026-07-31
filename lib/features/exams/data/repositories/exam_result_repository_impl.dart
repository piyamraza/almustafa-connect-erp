import '../../domain/entities/exam_result_entity.dart';
import '../../domain/repositories/exam_result_repository.dart';
import '../datasources/exam_result_remote_datasource.dart';
import '../models/exam_result_model.dart';

class ExamResultRepositoryImpl implements ExamResultRepository {
  ExamResultRepositoryImpl({required ExamResultRemoteDataSource source})
      : _source = source;

  final ExamResultRemoteDataSource _source;

  @override
  Future<List<ExamResultEntity>> getResultsForExam(String examId) {
    return _source.getResultsForExam(examId);
  }

  @override
  Future<List<ExamResultEntity>> getPublishedResults({
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
  }) {
    return _source.getPublishedResults(
      examId: examId,
      classId: classId,
      sectionId: sectionId,
      studentId: studentId,
    );
  }

  @override
  Future<void> saveResults(List<ExamResultEntity> results) {
    return _source.saveResults(
      results.map(ExamResultModel.fromEntity).toList(growable: false),
    );
  }

  @override
  Future<void> updateStatus({
    required List<String> resultIds,
    required ResultStatus status,
    bool setPublishedAt = true,
  }) {
    return _source.updateStatus(
      resultIds: resultIds,
      status: status,
      setPublishedAt: setPublishedAt,
    );
  }
}
