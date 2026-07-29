import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String id;

  final String studentId;
  final String admissionNo;
  final String studentName;

  final String classId;
  final String sectionId;

  final DateTime attendanceDate;

  final AttendanceStatus status;

  final String remarks;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AttendanceEntity({
    required this.id,
    required this.studentId,
    required this.admissionNo,
    required this.studentName,
    required this.classId,
    required this.sectionId,
    required this.attendanceDate,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  AttendanceEntity copyWith({
    String? id,
    String? studentId,
    String? admissionNo,
    String? studentName,
    String? classId,
    String? sectionId,
    DateTime? attendanceDate,
    AttendanceStatus? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      admissionNo: admissionNo ?? this.admissionNo,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        admissionNo,
        studentName,
        classId,
        sectionId,
        attendanceDate,
        status,
        remarks,
        createdAt,
        updatedAt,
      ];
}

enum AttendanceStatus {
  present,
  absent,
  leave,
  late,
}