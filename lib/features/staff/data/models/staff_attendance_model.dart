import '../../domain/entities/staff_attendance_entity.dart';

class StaffAttendanceModel extends StaffAttendanceEntity {
  const StaffAttendanceModel({
    required super.id,
    required super.staffId,
    required super.staffCode,
    required super.staffName,
    required super.designation,
    required super.attendanceDate,
    required super.status,
    required super.remarks,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StaffAttendanceModel.fromEntity(
    StaffAttendanceEntity entity,
  ) {
    return StaffAttendanceModel(
      id: entity.id,
      staffId: entity.staffId,
      staffCode: entity.staffCode,
      staffName: entity.staffName,
      designation: entity.designation,
      attendanceDate: entity.attendanceDate,
      status: entity.status,
      remarks: entity.remarks,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StaffAttendanceModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return StaffAttendanceModel(
      id: map['id'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffCode: map['staffCode'] as String? ?? '',
      staffName: map['staffName'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      attendanceDate: _parseDate(map['attendanceDate']),
      status: StaffAttendanceStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => StaffAttendanceStatus.present,
      ),
      remarks: map['remarks'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffCode': staffCode,
      'staffName': staffName,
      'designation': designation,
      'attendanceDate': attendanceDate.toIso8601String(),
      'status': status.name,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }
}