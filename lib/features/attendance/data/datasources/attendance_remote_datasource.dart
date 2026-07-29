import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceModel>> getAttendance();

  Future<void> addAttendance(
    AttendanceModel attendance,
  );

  Future<void> updateAttendance(
    AttendanceModel attendance,
  );

  Future<void> deleteAttendance(
    String attendanceId,
  );

  Future<List<AttendanceModel>> getAttendanceByDate(
    DateTime date,
  );

  Future<List<AttendanceModel>> getAttendanceByStudent(
    String studentId,
  );

  String generateAttendanceId();
}

class AttendanceRemoteDataSourceImpl
    implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
  }) : _firestore =
            firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection =
      'attendance';

  @override
  Future<List<AttendanceModel>> getAttendance() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('attendanceDate', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  Future<void> addAttendance(
    AttendanceModel attendance,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(attendance.id)
        .set(
          attendance.toMap(),
        );
  }

  @override
  Future<void> updateAttendance(
    AttendanceModel attendance,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(attendance.id)
        .update(
          attendance.toMap(),
        );
  }

  @override
  Future<void> deleteAttendance(
    String attendanceId,
  ) async {
    await _firestore
        .collection(_collection)
        .doc(attendanceId)
        .delete();
  }

  @override
  Future<List<AttendanceModel>>
      getAttendanceByDate(
    DateTime date,
  ) async {
    final start = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final end = start.add(
      const Duration(days: 1),
    );

    final snapshot = await _firestore
        .collection(_collection)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo:
              start.toIso8601String(),
        )
        .where(
          'attendanceDate',
          isLessThan:
              end.toIso8601String(),
        )
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  Future<List<AttendanceModel>>
      getAttendanceByStudent(
    String studentId,
  ) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where(
          'studentId',
          isEqualTo: studentId,
        )
        .orderBy(
          'attendanceDate',
          descending: true,
        )
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  String generateAttendanceId() {
    return _firestore
        .collection(_collection)
        .doc()
        .id;
  }
}