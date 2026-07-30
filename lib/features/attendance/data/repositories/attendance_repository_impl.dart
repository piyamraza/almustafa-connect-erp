import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl
    implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<List<AttendanceEntity>> getAttendance() {
    return remoteDataSource.getAttendance();
  }

  @override
  Future<void> addAttendance(
    AttendanceEntity attendance,
  ) async {
    await remoteDataSource.addAttendance(
      AttendanceModel.fromEntity(attendance),
    );
  }

  @override
  Future<void> updateAttendance(
    AttendanceEntity attendance,
  ) async {
    await remoteDataSource.updateAttendance(
      AttendanceModel.fromEntity(attendance),
    );
  }

  @override
  Future<void> deleteAttendance(
    String attendanceId,
  ) {
    return remoteDataSource.deleteAttendance(
      attendanceId,
    );
  }

  @override
  Future<List<AttendanceEntity>>
      getAttendanceByDate(
    DateTime date,
  ) {
    return remoteDataSource.getAttendanceByDate(
      date,
    );
  }

  @override
  Future<List<AttendanceEntity>>
      getAttendanceByStudent(
    String studentId,
  ) {
    return remoteDataSource.getAttendanceByStudent(
      studentId,
    );
  }

  @override
  Future<List<AttendanceEntity>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) => remoteDataSource.getAttendanceForReport(
        fromDate: fromDate,
        toDate: toDate,
      );

  @override
  String generateAttendanceId() {
    return remoteDataSource.generateAttendanceId();
  }
}
