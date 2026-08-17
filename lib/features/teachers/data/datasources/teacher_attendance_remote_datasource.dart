import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/teacher_attendance_model.dart';

abstract class TeacherAttendanceRemoteDataSource {
  Future<List<TeacherAttendanceModel>> getByDate(DateTime date);
  Future<List<TeacherAttendanceModel>> getByTeacher(
    String teacherId,
    DateTime fromDate,
    DateTime toDate,
  );
  Future<void> save(TeacherAttendanceModel record);
}

class TeacherAttendanceRemoteDataSourceImpl
    implements TeacherAttendanceRemoteDataSource {
  TeacherAttendanceRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;
  final FirebaseFirestoreService _service;
  @override
  Future<List<TeacherAttendanceModel>> getByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snapshot = await _service
        .collection(FirestorePaths.teacherAttendance)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: start.toIso8601String(),
        )
        .where('attendanceDate', isLessThan: end.toIso8601String())
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              TeacherAttendanceModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .toList();
  }

  @override
  Future<List<TeacherAttendanceModel>> getByTeacher(
    String teacherId,
    DateTime fromDate,
    DateTime toDate,
  ) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
    ).add(const Duration(days: 1));
    final snapshot = await _service
        .collection(FirestorePaths.teacherAttendance)
        .where('teacherId', isEqualTo: teacherId)
        .get();
    final records = snapshot.docs
        .map(
          (doc) =>
              TeacherAttendanceModel.fromMap({...doc.data(), 'id': doc.id}),
        )
        .where(
          (record) =>
              !record.attendanceDate.isBefore(start) &&
              record.attendanceDate.isBefore(end),
        )
        .toList();
    records.sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));
    return records;
  }

  @override
  Future<void> save(TeacherAttendanceModel record) => _service
      .collection(FirestorePaths.teacherAttendance)
      .doc(record.id)
      .set(record.toMap());
}
