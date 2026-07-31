import '../../domain/entities/staff_attendance_entity.dart';
import '../../domain/repositories/staff_attendance_repository.dart';
import '../datasources/staff_attendance_remote_datasource.dart';
import '../models/staff_attendance_model.dart';

class StaffAttendanceRepositoryImpl
    implements StaffAttendanceRepository {
  const StaffAttendanceRepositoryImpl({
    required this._remoteDataSource,
  });

  final StaffAttendanceRemoteDataSource _remoteDataSource;

  @override
  Future<List<StaffAttendanceEntity>> getAttendanceByDate(
    DateTime date,
  ) {
    return _remoteDataSource.getAttendanceByDate(date);
  }

  @override
  Future<List<StaffAttendanceEntity>> getAttendanceByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getAttendanceByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<StaffAttendanceEntity>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getAttendanceByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<void> saveAttendance(
    StaffAttendanceEntity attendance,
  ) {
    return _remoteDataSource.saveAttendance(
      StaffAttendanceModel.fromEntity(attendance),
    );
  }
}