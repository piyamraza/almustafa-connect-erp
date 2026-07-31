import '../../domain/entities/attendance_entity.dart';

class AttendanceModel extends AttendanceEntity {
  const AttendanceModel({
    required super.id,
    required super.studentId,
    required super.admissionNo,
    required super.studentName,
    required super.classId,
    required super.sectionId,
    required super.attendanceDate,
    required super.status,
    required super.remarks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AttendanceModel.fromEntity(
    AttendanceEntity entity,
  ) {
    return AttendanceModel(
      id: entity.id,
      studentId: entity.studentId,
      admissionNo: entity.admissionNo,
      studentName: entity.studentName,
      classId: entity.classId,
      sectionId: entity.sectionId,
      attendanceDate: entity.attendanceDate,
      status: entity.status,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory AttendanceModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AttendanceModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      admissionNo: map['admissionNo'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      sectionId: map['sectionId'] ?? '',
      attendanceDate: DateTime.parse(
        map['attendanceDate'],
      ),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AttendanceStatus.present,
      ),
      remarks: map['remarks'] ?? '',
      createdAt: DateTime.parse(
        map['createdAt'],
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'admissionNo': admissionNo,
      'studentName': studentName,
      'classId': classId,
      'sectionId': sectionId,
      'attendanceDate': attendanceDate.toIso8601String(),
      'status': status.name,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  AttendanceModel copyWith({
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
    return AttendanceModel(
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
}