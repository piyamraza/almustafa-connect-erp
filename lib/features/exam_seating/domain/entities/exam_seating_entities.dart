import 'package:equatable/equatable.dart';

class ExamRoomEntity extends Equatable {
  const ExamRoomEntity({
    required this.id,
    required this.name,
    required this.capacity,
  });
  final String id;
  final String name;
  final int capacity;

  @override
  List<Object> get props => [id, name, capacity];
}

class ExamRoomSetupEntity extends Equatable {
  const ExamRoomSetupEntity({
    required this.examId,
    required this.examName,
    required this.rooms,
    required this.updatedAt,
  });
  final String examId;
  final String examName;
  final List<ExamRoomEntity> rooms;
  final DateTime updatedAt;
  int get totalCapacity => rooms.fold(0, (sum, room) => sum + room.capacity);

  @override
  List<Object> get props => [examId, examName, rooms, updatedAt];
}

class StudentSeatAssignmentEntity extends Equatable {
  const StudentSeatAssignmentEntity({
    required this.studentId,
    required this.studentName,
    this.fatherName = '',
    required this.rollNumber,
    required this.classId,
    required this.sectionId,
    required this.className,
    required this.roomId,
    required this.roomName,
    required this.seatNumber,
  });
  final String studentId;
  final String studentName;
  final String fatherName;
  final String rollNumber;
  final String classId;
  final String sectionId;
  final String className;
  final String roomId;
  final String roomName;
  final int seatNumber;

  @override
  List<Object> get props => [
    studentId,
    studentName,
    fatherName,
    rollNumber,
    classId,
    sectionId,
    className,
    roomId,
    roomName,
    seatNumber,
  ];
}

class TeacherDutyAssignmentEntity extends Equatable {
  const TeacherDutyAssignmentEntity({
    required this.teacherId,
    required this.teacherName,
    required this.role,
    this.roomId = '',
    this.roomName = '',
  });
  final String teacherId;
  final String teacherName;
  final String role;
  final String roomId;
  final String roomName;

  bool get isRest => role == 'rest';
  bool get isPaperSupport => role == 'paperSupport';

  @override
  List<Object> get props => [teacherId, teacherName, role, roomId, roomName];
}

enum ExamPlanStatus { draft, finalized }

class DailyExamPlanEntity extends Equatable {
  const DailyExamPlanEntity({
    required this.id,
    required this.examId,
    required this.examName,
    required this.dateSheetId,
    required this.examDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.rooms,
    required this.studentAssignments,
    required this.teacherAssignments,
    required this.status,
    required this.paperSupportEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String examId;
  final String examName;
  final String dateSheetId;
  final DateTime examDate;
  final int startMinutes;
  final int endMinutes;
  final List<ExamRoomEntity> rooms;
  final List<StudentSeatAssignmentEntity> studentAssignments;
  final List<TeacherDutyAssignmentEntity> teacherAssignments;
  final ExamPlanStatus status;
  final bool paperSupportEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get sessionLabel => '${_time(startMinutes)} - ${_time(endMinutes)}';
  static String _time(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  @override
  List<Object> get props => [
    id,
    examId,
    examName,
    dateSheetId,
    examDate,
    startMinutes,
    endMinutes,
    rooms,
    studentAssignments,
    teacherAssignments,
    status,
    paperSupportEnabled,
    createdAt,
    updatedAt,
  ];
}
