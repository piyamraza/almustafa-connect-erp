import 'package:get_it/get_it.dart';

import '../attendance/domain/repositories/attendance_repository.dart';
import 'data/services/parent_attendance_service_impl.dart';
import 'domain/services/parent_attendance_service.dart';

void registerParentAttendanceDependencies(GetIt sl) {
  if (!sl.isRegistered<ParentAttendanceService>()) {
    sl.registerLazySingleton<ParentAttendanceService>(
      () => ParentAttendanceServiceImpl(sl<AttendanceRepository>()),
    );
  }
}
