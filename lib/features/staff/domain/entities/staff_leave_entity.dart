import 'package:equatable/equatable.dart';

enum StaffLeaveType {
  casual,
  sick,
  annual,
  unpaid,
  other,
}

enum StaffLeaveDuration {
  fullDay,
  halfDay,
}

enum StaffLeaveStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class StaffLeaveEntity extends Equatable {
  const StaffLeaveEntity({
    required this.id,
    required this.staffId,
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.approvalRemarks,
    required this.approvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
  });

  final String id;

  /// Firestore document ID of the staff member.
  final String staffId;

  /// Readable staff code, for example STF123456.
  final String staffCode;

  final String staffName;
  final String designation;
  final StaffLeaveType leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final StaffLeaveDuration duration;
  final double totalDays;
  final String reason;
  final StaffLeaveStatus status;
  final String approvalRemarks;
  final String approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == StaffLeaveStatus.pending;

  bool get isApproved => status == StaffLeaveStatus.approved;

  bool get isRejected => status == StaffLeaveStatus.rejected;

  bool get isCancelled => status == StaffLeaveStatus.cancelled;

  StaffLeaveEntity copyWith({
    String? id,
    String? staffId,
    String? staffCode,
    String? staffName,
    String? designation,
    StaffLeaveType? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    StaffLeaveDuration? duration,
    double? totalDays,
    String? reason,
    StaffLeaveStatus? status,
    String? approvalRemarks,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearApprovedAt = false,
  }) {
    return StaffLeaveEntity(
      id: id ?? this.id,
      staffId: staffId ?? this.staffId,
      staffCode: staffCode ?? this.staffCode,
      staffName: staffName ?? this.staffName,
      designation: designation ?? this.designation,
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      duration: duration ?? this.duration,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvalRemarks:
          approvalRemarks ?? this.approvalRemarks,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt:
          clearApprovedAt ? null : approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        staffId,
        staffCode,
        staffName,
        designation,
        leaveType,
        startDate,
        endDate,
        duration,
        totalDays,
        reason,
        status,
        approvalRemarks,
        approvedBy,
        approvedAt,
        createdAt,
        updatedAt,
      ];
}