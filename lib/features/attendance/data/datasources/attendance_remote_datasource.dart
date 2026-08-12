import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<List<AttendanceModel>> getAttendance();

  Future<void> addAttendance(AttendanceModel attendance);

  Future<void> updateAttendance(AttendanceModel attendance);

  Future<void> deleteAttendance(String attendanceId);

  Future<List<AttendanceModel>> getAttendanceByDate(DateTime date);

  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId);

  Future<List<AttendanceModel>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  });

  String generateAttendanceId();
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'attendance';

  @override
  Future<List<AttendanceModel>> getAttendance() async {
    final snapshot = await _firestore
        .collection(_collection)
        .orderBy('attendanceDate', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          }),
        )
        .toList();
  }

  @override
  Future<void> addAttendance(AttendanceModel attendance) async {
    final existingDocumentId = await _findExistingDocumentId(attendance);
    final documentId = existingDocumentId ?? attendance.id;
    await _firestore
        .collection(_collection)
        .doc(documentId)
        .set(
          attendance.copyWith(id: documentId).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> updateAttendance(AttendanceModel attendance) async {
    final existingDocumentId = await _findExistingDocumentId(attendance);
    final documentId = existingDocumentId ?? attendance.id;
    await _firestore
        .collection(_collection)
        .doc(documentId)
        .set(
          attendance.copyWith(id: documentId).toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteAttendance(String attendanceId) async {
    await _firestore.collection(_collection).doc(attendanceId).delete();
  }

  @override
  Future<List<AttendanceModel>> getAttendanceByDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);

    final end = start.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection(_collection)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: start.toIso8601String(),
        )
        .where('attendanceDate', isLessThan: end.toIso8601String())
        .get();

    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          }),
        )
        .toList();
  }

  @override
  Future<List<AttendanceModel>> getAttendanceByStudent(String studentId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: studentId)
        .get();

    final records = snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          }),
        )
        .toList();
    records.sort(
      (first, second) => second.attendanceDate.compareTo(first.attendanceDate),
    );
    return records;
  }

  @override
  Future<List<AttendanceModel>> getAttendanceForReport({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(
      toDate.year,
      toDate.month,
      toDate.day,
    ).add(const Duration(days: 1));
    final snapshot = await _firestore
        .collection(_collection)
        .where(
          'attendanceDate',
          isGreaterThanOrEqualTo: start.toIso8601String(),
        )
        .where('attendanceDate', isLessThan: end.toIso8601String())
        .orderBy('attendanceDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => AttendanceModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          }),
        )
        .toList();
  }

  @override
  String generateAttendanceId() {
    return _firestore.collection(_collection).doc().id;
  }

  Future<String?> _findExistingDocumentId(AttendanceModel attendance) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('studentId', isEqualTo: attendance.studentId)
        .get();
    final day = DateTime(
      attendance.attendanceDate.year,
      attendance.attendanceDate.month,
      attendance.attendanceDate.day,
    );
    for (final document in snapshot.docs) {
      final data = document.data();
      final rawDate = data['attendanceDate'];
      if (rawDate is! String) continue;
      final storedDate = DateTime.tryParse(rawDate);
      if (storedDate == null) continue;
      if (storedDate.year == day.year &&
          storedDate.month == day.month &&
          storedDate.day == day.day) {
        return document.id;
      }
    }
    return null;
  }
}
