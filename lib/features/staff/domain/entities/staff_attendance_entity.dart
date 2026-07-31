import 'package:equatable/equatable.dart';

enum StaffAttendanceStatus {
  present,
  absent,
  late,
  leave,
}

class StaffAttendanceEntity extends Equatable {
  const StaffAttendanceEntity({
    required this.id,
    required this.staffId,
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.attendanceDate,
    required this.status,
    required this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Firestore document ID of the staff member.
  final String staffId;

  /// Readable staff ID, for example STF123456.
  final String staffCode;

  final String staffName;
  final String designation;
  final DateTime attendanceDate;
  final StaffAttendanceStatus status;
  final String remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffAttendanceEntity copyWith({
    String? id,
    String? staffId,
    String? staffCode,
    String? staffName,
    String? designation,
    DateTime? attendanceDate,
    StaffAttendanceStatus? status,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffAttendanceEntity(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      designation: designation ?? this.designation,
      attendanceDate: attendanceDate ?? this.attendanceDate,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
        id,
        staffId,
        staffCode,
        staffName,
        designation,
        attendanceDate,
        status,
        remarks,
        createdAt,
        updatedAt,
      ];
}