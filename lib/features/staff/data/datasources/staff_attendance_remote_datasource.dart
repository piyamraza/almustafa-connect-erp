import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/staff_attendance_model.dart';

abstract class StaffAttendanceRemoteDataSource {
  Future<List<StaffAttendanceModel>> getAttendanceByDate(
    DateTime date,
  );

  Future<List<StaffAttendanceModel>> getAttendanceByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffAttendanceModel>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<void> saveAttendance(
    StaffAttendanceModel attendance,
  );
}

class StaffAttendanceRemoteDataSourceImpl
    implements StaffAttendanceRemoteDataSource {
  StaffAttendanceRemoteDataSourceImpl({
    required this._firestoreService,
  });

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StaffAttendanceModel>> getAttendanceByDate(
    DateTime date,
  ) async {
    final startDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final endDate = startDate.add(
      const Duration(days: 1),
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffAttendance)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        )
        .where(
          'attendanceDate',
          isLessThan: endDate.toIso8601String(),
        )
        .get();

    final records = snapshot.docs.map(
      (document) {
        return StaffAttendanceModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    records.sort(
      (first, second) => first.staffName.toLowerCase().compareTo(
            second.staffName.toLowerCase(),
          ),
    );

    return records;
  }

  @override
  Future<List<StaffAttendanceModel>> getAttendanceByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(
      const Duration(days: 1),
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffAttendance)
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: normalizedStartDate.toIso8601String(),
        )
        .where(
          'attendanceDate',
          isLessThan: normalizedEndDate.toIso8601String(),
        )
        .get();

    final records = snapshot.docs.map(
      (document) {
        return StaffAttendanceModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    records.sort(
      (first, second) => second.attendanceDate.compareTo(
        first.attendanceDate,
      ),
    );

    return records;
  }

  @override
  Future<List<StaffAttendanceModel>> getAttendanceByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(
      const Duration(days: 1),
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffAttendance)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: normalizedStartDate.toIso8601String(),
        )
        .where(
          'attendanceDate',
          isLessThan: normalizedEndDate.toIso8601String(),
        )
        .get();

    final records = snapshot.docs.map(
      (document) {
        return StaffAttendanceModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    records.sort(
      (first, second) {
        final dateComparison = second.attendanceDate.compareTo(
          first.attendanceDate,
        );

        if (dateComparison != 0) {
          return dateComparison;
        }

        return first.staffName.toLowerCase().compareTo(
              second.staffName.toLowerCase(),
            );
      },
    );

    return records;
  }

  @override
  Future<void> saveAttendance(
    StaffAttendanceModel attendance,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffAttendance)
        .doc(attendance.id)
        .set(attendance.toMap());
  }
}