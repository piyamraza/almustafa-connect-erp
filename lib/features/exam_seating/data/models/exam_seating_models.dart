import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/exam_seating_entities.dart';

DateTime _date(Object? value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
    ? value
    : DateTime.tryParse('$value') ?? DateTime.now();

Map<String, dynamic> roomToMap(ExamRoomEntity room) => {
  'id': room.id,
  'name': room.name,
  'capacity': room.capacity,
};
ExamRoomEntity roomFromMap(Map<String, dynamic> map) => ExamRoomEntity(
  id: '${map['id'] ?? ''}',
  name: '${map['name'] ?? ''}',
  capacity: (map['capacity'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> roomSetupToMap(ExamRoomSetupEntity value) => {
  'examId': value.examId,
  'examName': value.examName,
  'rooms': value.rooms.map(roomToMap).toList(),
  'updatedAt': value.updatedAt,
};
ExamRoomSetupEntity roomSetupFromMap(Map<String, dynamic> map) =>
    ExamRoomSetupEntity(
      examId: '${map['examId'] ?? ''}',
      examName: '${map['examName'] ?? ''}',
      rooms: ((map['rooms'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => roomFromMap(Map<String, dynamic>.from(e)))
          .toList(),
      updatedAt: _date(map['updatedAt']),
    );

Map<String, dynamic> studentToMap(StudentSeatAssignmentEntity value) => {
  'studentId': value.studentId,
  'studentName': value.studentName,
  'fatherName': value.fatherName,
  'rollNumber': value.rollNumber,
  'classId': value.classId,
  'sectionId': value.sectionId,
  'className': value.className,
  'roomId': value.roomId,
  'roomName': value.roomName,
  'seatNumber': value.seatNumber,
};
StudentSeatAssignmentEntity studentFromMap(Map<String, dynamic> map) =>
    StudentSeatAssignmentEntity(
      studentId: '${map['studentId'] ?? ''}',
      studentName: '${map['studentName'] ?? ''}',
      fatherName: '${map['fatherName'] ?? ''}',
      rollNumber: '${map['rollNumber'] ?? ''}',
      classId: '${map['classId'] ?? ''}',
      sectionId: '${map['sectionId'] ?? ''}',
      className: '${map['className'] ?? ''}',
      roomId: '${map['roomId'] ?? ''}',
      roomName: '${map['roomName'] ?? ''}',
      seatNumber: (map['seatNumber'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> teacherToMap(TeacherDutyAssignmentEntity value) => {
  'teacherId': value.teacherId,
  'teacherName': value.teacherName,
  'role': value.role,
  'roomId': value.roomId,
  'roomName': value.roomName,
};
TeacherDutyAssignmentEntity teacherFromMap(Map<String, dynamic> map) =>
    TeacherDutyAssignmentEntity(
      teacherId: '${map['teacherId'] ?? ''}',
      teacherName: '${map['teacherName'] ?? ''}',
      role: '${map['role'] ?? 'invigilator'}',
      roomId: '${map['roomId'] ?? ''}',
      roomName: '${map['roomName'] ?? ''}',
    );

Map<String, dynamic> planToMap(DailyExamPlanEntity value) => {
  'examId': value.examId,
  'examName': value.examName,
  'dateSheetId': value.dateSheetId,
  'examDate': value.examDate,
  'startMinutes': value.startMinutes,
  'endMinutes': value.endMinutes,
  'rooms': value.rooms.map(roomToMap).toList(),
  'studentAssignments': value.studentAssignments.map(studentToMap).toList(),
  'teacherAssignments': value.teacherAssignments.map(teacherToMap).toList(),
  'status': value.status.name,
  'paperSupportEnabled': value.paperSupportEnabled,
  'createdAt': value.createdAt,
  'updatedAt': value.updatedAt,
};
DailyExamPlanEntity planFromMap(String id, Map<String, dynamic> map) =>
    DailyExamPlanEntity(
      id: id,
      examId: '${map['examId'] ?? ''}',
      examName: '${map['examName'] ?? ''}',
      dateSheetId: '${map['dateSheetId'] ?? ''}',
      examDate: _date(map['examDate']),
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
      rooms: ((map['rooms'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => roomFromMap(Map<String, dynamic>.from(e)))
          .toList(),
      studentAssignments: ((map['studentAssignments'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => studentFromMap(Map<String, dynamic>.from(e)))
          .toList(),
      teacherAssignments: ((map['teacherAssignments'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => teacherFromMap(Map<String, dynamic>.from(e)))
          .toList(),
      status:
          ExamPlanStatus.values
              .where((e) => e.name == map['status'])
              .firstOrNull ??
          ExamPlanStatus.draft,
      paperSupportEnabled: map['paperSupportEnabled'] == true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
