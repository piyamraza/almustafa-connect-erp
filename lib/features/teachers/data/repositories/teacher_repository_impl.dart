import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/teacher_entity.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../datasources/teacher_remote_datasource.dart';
import '../models/teacher_model.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  TeacherRepositoryImpl({
    required this._remoteDataSource,
    required this._auditService,
  });

  final TeacherRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

  @override
  Future<List<TeacherEntity>> getTeachers() {
    return _remoteDataSource.getTeachers();
  }

  @override
  Future<void> saveTeacher(TeacherEntity teacher) async {
    final previous = await _remoteDataSource.getTeacherById(teacher.id);
    final model = TeacherModel.fromEntity(teacher);

    await _remoteDataSource.saveTeacher(model);

    if (previous == null) {
      await _auditService.logCreate(
        module: 'Teachers',
        recordId: teacher.id,
        description: 'Teacher record created',
        newValues: _auditValues(model),
      );
      return;
    }

    await _auditService.logUpdate(
      module: 'Teachers',
      recordId: teacher.id,
      description: 'Teacher record updated',
      oldValues: _auditValues(previous),
      newValues: _auditValues(model),
    );
  }

  @override
  Future<void> deleteTeacher(String id) async {
    final previous = await _remoteDataSource.getTeacherById(id);

    await _remoteDataSource.deleteTeacher(id);

    await _auditService.logDelete(
      module: 'Teachers',
      recordId: id,
      description: 'Teacher record deleted',
      oldValues: previous == null ? const {} : _auditValues(previous),
    );
  }

  @override
  String generateTeacherId() {
    return _remoteDataSource.generateTeacherId();
  }

  Map<String, dynamic> _auditValues(TeacherModel model) {
    final values = Map<String, dynamic>.from(model.toMap());
    values.remove('cnic');
    return values;
  }
}
