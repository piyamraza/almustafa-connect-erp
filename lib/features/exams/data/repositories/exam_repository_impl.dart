import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_repository.dart';
import '../datasources/exam_remote_datasource.dart';
import '../models/exam_model.dart';

class ExamRepositoryImpl implements ExamRepository {
  ExamRepositoryImpl({
    required this._source,
    required AuditService auditService,
  }) : _auditService = auditService;

  final ExamRemoteDataSource _source;
  final AuditService _auditService;

  @override
  Future<List<ExamEntity>> getExams({String? academicSession, bool? isActive}) {
    return _source.getExams(
      academicSession: academicSession,
      isActive: isActive,
    );
  }

  @override
  Future<ExamEntity?> getExamById(String id) {
    return _source.getExamById(id);
  }

  @override
  Future<void> createExam(ExamEntity exam) async {
    final model = ExamModel.fromEntity(exam);

    await _source.createExam(model);

    await _auditService.logCreate(
      module: 'Examinations',
      recordId: exam.id,
      description: 'Exam created: ${exam.name}',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> updateExam(ExamEntity exam) async {
    final previous = await _source.getExamById(exam.id);
    final model = ExamModel.fromEntity(exam);

    await _source.updateExam(model);

    await _auditService.logUpdate(
      module: 'Examinations',
      recordId: exam.id,
      description: 'Exam updated: ${exam.name}',
      oldValues: previous == null
          ? const {}
          : ExamModel.fromEntity(previous).toMap(),
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> deleteExam(String id) async {
    final previous = await _source.getExamById(id);

    await _source.deleteExam(id);

    await _auditService.logDelete(
      module: 'Examinations',
      recordId: id,
      description: previous == null
          ? 'Exam deleted'
          : 'Exam deleted: ${previous.name}',
      oldValues: previous == null
          ? const {}
          : ExamModel.fromEntity(previous).toMap(),
    );
  }

  @override
  Future<void> setExamActiveStatus({
    required String id,
    required bool isActive,
  }) async {
    final previous = await _source.getExamById(id);

    await _source.setExamActiveStatus(id: id, isActive: isActive);

    await _auditService.logUpdate(
      module: 'Examinations',
      recordId: id,
      description: isActive ? 'Exam activated' : 'Exam deactivated',
      oldValues: {
        if (previous != null) ...ExamModel.fromEntity(previous).toMap(),
      },
      newValues: {
        'isActive': isActive,
        'status': isActive ? 'active' : 'draft',
      },
    );
  }

  @override
  String generateId() {
    return _source.generateId();
  }
}
