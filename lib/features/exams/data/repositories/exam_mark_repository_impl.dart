import '../../domain/entities/exam_mark_entity.dart';
import '../../domain/repositories/exam_mark_repository.dart';
import '../datasources/exam_mark_remote_datasource.dart';
import '../models/exam_mark_model.dart';

class ExamMarkRepositoryImpl implements ExamMarkRepository {
  ExamMarkRepositoryImpl({required this._source});

  final ExamMarkRemoteDataSource _source;

  @override
  Future<List<ExamMarkEntity>> getMarksForEntry(String entryKey) {
    return _source.getMarksForEntry(entryKey);
  }

  @override
  Future<List<ExamMarkEntity>> getMarksForExam(String examId) {
    return _source.getMarksForExam(examId);
  }

  @override
  Future<void> saveMarks(List<ExamMarkEntity> marks) {
    return _source.saveMarks(
      marks.map(ExamMarkModel.fromEntity).toList(growable: false),
    );
  }

  @override
  Future<void> deleteMark(String id) {
    return _source.deleteMark(id);
  }
}
