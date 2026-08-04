import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/teacher_duty_entities.dart';

class TeacherDutyRepository {
  TeacherDutyRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String leaveCollection = 'teacher_leave_requests';
  static const String dutyCollection = 'teacher_substitute_duties';

  final FirebaseFirestore _firestore;

  Future<List<TeacherLeaveRequestEntity>> getLeaveRequests({
    String? teacherEmail,
  }) async {
    final snapshot =
        await _firestore.collection(leaveCollection).get();

    final values = snapshot.docs
        .map(
          (doc) => _leaveFromMap(
            doc.id,
            doc.data(),
          ),
        )
        .where(
          (item) =>
              teacherEmail == null ||
              item.teacherEmail.toLowerCase() ==
                  teacherEmail.toLowerCase(),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return values;
  }

  Future<void> submitLeave({
    required String teacherEmail,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
  }) async {
    final now = DateTime.now();
    final id = 'leave_${now.microsecondsSinceEpoch}';

    await _firestore.collection(leaveCollection).doc(id).set({
      'id': id,
      'teacherEmail': teacherEmail.trim(),
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'reason': reason.trim(),
      'status': TeacherLeaveStatus.pending.name,
      'createdAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateLeaveStatus({
    required String id,
    required TeacherLeaveStatus status,
  }) {
    return _firestore.collection(leaveCollection).doc(id).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<List<SubstituteDutyEntity>> getDuties({
    String? substituteTeacherEmail,
    DateTime? date,
  }) async {
    final snapshot =
        await _firestore.collection(dutyCollection).get();

    final values = snapshot.docs
        .map(
          (doc) => _dutyFromMap(
            doc.id,
            doc.data(),
          ),
        )
        .where((item) {
          final emailMatches =
              substituteTeacherEmail == null ||
              item.substituteTeacherEmail.toLowerCase() ==
                  substituteTeacherEmail.toLowerCase();

          final dateMatches = date == null ||
              (item.dutyDate.year == date.year &&
                  item.dutyDate.month == date.month &&
                  item.dutyDate.day == date.day);

          return emailMatches && dateMatches && item.isActive;
        })
        .toList()
      ..sort((a, b) => a.dutyDate.compareTo(b.dutyDate));

    return values;
  }

  Future<void> assignDuty(SubstituteDutyEntity duty) {
    return _firestore.collection(dutyCollection).doc(duty.id).set({
      'id': duty.id,
      'originalTeacherEmail': duty.originalTeacherEmail,
      'substituteTeacherEmail': duty.substituteTeacherEmail,
      'dutyDate': Timestamp.fromDate(duty.dutyDate),
      'periodLabel': duty.periodLabel,
      'className': duty.className,
      'sectionName': duty.sectionName,
      'subjectName': duty.subjectName,
      'room': duty.room,
      'notes': duty.notes,
      'isActive': duty.isActive,
      'createdAt': Timestamp.fromDate(duty.createdAt),
    });
  }

  Future<void> cancelDuty(String id) {
    return _firestore.collection(dutyCollection).doc(id).update({
      'isActive': false,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  TeacherLeaveRequestEntity _leaveFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TeacherLeaveRequestEntity(
      id: id,
      teacherEmail: map['teacherEmail'] as String? ?? '',
      fromDate: _date(map['fromDate']),
      toDate: _date(map['toDate']),
      reason: map['reason'] as String? ?? '',
      status: TeacherLeaveStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => TeacherLeaveStatus.pending,
      ),
      createdAt: _date(map['createdAt']),
    );
  }

  SubstituteDutyEntity _dutyFromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return SubstituteDutyEntity(
      id: id,
      originalTeacherEmail:
          map['originalTeacherEmail'] as String? ?? '',
      substituteTeacherEmail:
          map['substituteTeacherEmail'] as String? ?? '',
      dutyDate: _date(map['dutyDate']),
      periodLabel: map['periodLabel'] as String? ?? '',
      className: map['className'] as String? ?? '',
      sectionName: map['sectionName'] as String? ?? '',
      subjectName: map['subjectName'] as String? ?? '',
      room: map['room'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
    );
  }

  DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse('$value') ?? DateTime.now();
  }
}