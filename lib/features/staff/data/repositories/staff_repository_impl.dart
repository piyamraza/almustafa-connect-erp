import '../../domain/entities/staff_entity.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_remote_datasource.dart';
import '../models/staff_model.dart';

class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl({
    required this._remoteDataSource,
  });

  final StaffRemoteDataSource _remoteDataSource;

  @override
  Future<List<StaffEntity>> getStaff() {
    return _remoteDataSource.getStaff();
  }

  @override
  Future<void> saveStaff(StaffEntity staff) {
    return _remoteDataSource.saveStaff(
      StaffModel.fromEntity(staff),
    );
  }

  @override
  Future<void> deleteStaff(String id) {
    return _remoteDataSource.deleteStaff(id);
  }

  @override
  String generateStaffId() {
    return _remoteDataSource.generateStaffId();
  }
}