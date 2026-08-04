import '../../../../core/audit/domain/services/audit_service.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  AttendanceRepositoryImpl({
    required this._remoteDataSource,
    required this._auditService,
  });

  final AttendanceRemoteDataSource _remoteDataSource;
  final AuditService _auditService;

  @override
  Future<List<AttendanceEntity>> getAttendance() {
    return _remoteDataSource.getAttendance();
  }

  @override
  Future<void> addAttendance(AttendanceEntity attendance) async {
    final model = AttendanceModel.fromEntity(attendance);

    await _remoteDataSource.addAttendance(model);

    await _auditService.logCreate(
      module: 'Attendance',
      recordId: attendance.id,
      description: 'Daily student attendance recorded',
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> updateAttendance(AttendanceEntity attendance) async {
    final previous = await _findById(attendance.id);
    final model = AttendanceModel.fromEntity(attendance);

    await _remoteDataSource.updateAttendance(model);

    await _auditService.logUpdate(
      module: 'Attendance',
      recordId: attendance.id,
      description: 'Daily student attendance corrected',
      oldValues: previous == null
          ? const {}
          : AttendanceModel.fromEntity(previous).toMap(),
      newValues: model.toMap(),
    );
  }

  @override
  Future<void> deleteAttendance(String attendanceId) async {
    final previous = await _findById(attendanceId);

    await _remoteDataSource.deleteAttendance(attendanceId);

    await _auditService.logDelete(
      module: 'Attendance',
      recordId: attendanceId,
      description: 'Daily student attendance deleted',
      oldValues: previous == null
          ? const {}
          : AttendanceModel.fromEntity(previous).toMap(),
    );
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceByDate(DateTime date) {
    return _remoteDataSource.getAttendanceByDate(date);
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceByStudent(String studentId) {
    return _remoteDataSource.getAttendanceByStudent(studentId);
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return _remoteDataSource.getAttendanceForReport(
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  @override
  String generateAttendanceId() {
    return _remoteDataSource.generateAttendanceId();
  }

  Future<AttendanceEntity?> _findById(String id) async {
    final records = await _remoteDataSource.getAttendance();

    for (final item in records) {
      if (item.id == id) {
        return item;
      }
    }

    return null;
  }
}
