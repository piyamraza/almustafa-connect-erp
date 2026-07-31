import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl({required this._source});

  final ExamRemoteDataSource _source;

  @override
  Future<List<ExamEntity>> getExams({
    String? academicSession,
    bool? isActive,
  }) {
    return _source.getExams(
      academicSession: academicSession,
      isActive: isActive,
    );
  }

  @override
  Future<ExamEntity?> getExamById(String id) => _source.getExamById(id);

  @override
  Future<void> createExam(ExamEntity exam) {
    return _source.createExam(ExamModel.fromEntity(exam));
  }

  @override
  Future<void> updateExam(ExamEntity exam) {
    return _source.updateExam(ExamModel.fromEntity(exam));
  }

  @override
  Future<void> deleteExam(String id) => _source.deleteExam(id);

  @override
  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  }) {
    return _source.setExamActiveStatus(id: id, isActive: isActive);
  }

  @override
  String generateId() => _source.generateId();
}
