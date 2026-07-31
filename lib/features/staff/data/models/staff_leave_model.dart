import '../../domain/entities/staff_leave_entity.dart';

class StaffLeaveModel extends StaffLeaveEntity {
  const StaffLeaveModel({
    required super.id,
    required super.staffId,
    required super.staffCode,
    required super.staffName,
    required super.designation,
    required super.leaveType,
    required super.startDate,
    required super.endDate,
    required super.duration,
    required super.totalDays,
    required super.reason,
    required super.status,
    required super.approvalRemarks,
    required super.approvedBy,
    required super.createdAt,
    required super.updatedAt,
    super.approvedAt,
  });

  factory StaffLeaveModel.fromEntity(
    StaffLeaveEntity entity,
  ) {
    return StaffLeaveModel(
      id: entity.id,
      staffId: entity.staffId,
      staffCode: entity.staffCode,
      staffName: entity.staffName,
      designation: entity.designation,
      leaveType: entity.leaveType,
      startDate: entity.startDate,
      endDate: entity.endDate,
      duration: entity.duration,
      totalDays: entity.totalDays,
      reason: entity.reason,
      status: entity.status,
      approvalRemarks: entity.approvalRemarks,
      approvedBy: entity.approvedBy,
      approvedAt: entity.approvedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory StaffLeaveModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return StaffLeaveModel(
      id: map['id'] as String? ?? '',
      staffId: map['staffId'] as String? ?? '',
      staffCode: map['staffCode'] as String? ?? '',
      staffName: map['staffName'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      leaveType: _parseLeaveType(map['leaveType']),
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      duration: _parseDuration(map['duration']),
      totalDays: _parseDouble(map['totalDays']),
      reason: map['reason'] as String? ?? '',
      status: _parseStatus(map['status']),
      approvalRemarks:
          map['approvalRemarks'] as String? ?? '',
      approvedBy: map['approvedBy'] as String? ?? '',
      approvedAt: _parseNullableDate(map['approvedAt']),
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
      'leaveType': leaveType.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration.name,
      'totalDays': totalDays,
      'reason': reason,
      'status': status.name,
      'approvalRemarks': approvalRemarks,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static StaffLeaveType _parseLeaveType(dynamic value) {
    if (value is String) {
      for (final type in StaffLeaveType.values) {
        if (type.name == value) {
          return type;
        }
      }
    }

    return StaffLeaveType.casual;
  }

  static StaffLeaveDuration _parseDuration(dynamic value) {
    if (value is String) {
      for (final duration in StaffLeaveDuration.values) {
        if (duration.name == value) {
          return duration;
        }
      }
    }

    return StaffLeaveDuration.fullDay;
  }

  static StaffLeaveStatus _parseStatus(dynamic value) {
    if (value is String) {
      for (final status in StaffLeaveStatus.values) {
        if (status.name == value) {
          return status;
        }
      }
    }

    return StaffLeaveStatus.pending;
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime _parseDate(dynamic value) {
    return _parseNullableDate(value) ?? DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}