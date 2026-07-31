$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Write-ProjectFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $fullPath = Join-Path $projectRoot $RelativePath
    $directory = Split-Path -Parent $fullPath

    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    [System.IO.File]::WriteAllText(
        $fullPath,
        $Content,
        $utf8NoBom
    )

    Write-Host "Written: $RelativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Staff Leave Phase 4A Core Setup" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# DOMAIN ENTITY
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\entities\staff_leave_entity.dart" `
    -Content @'
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
'@

# ============================================================
# DATA MODEL
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\data\models\staff_leave_model.dart" `
    -Content @'
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
'@

# ============================================================
# DOMAIN REPOSITORY
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\repositories\staff_leave_repository.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';

abstract class StaffLeaveRepository {
  Future<List<StaffLeaveEntity>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveEntity>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveEntity>> getPendingLeaves();

  Future<void> saveLeave(
    StaffLeaveEntity leave,
  );

  Future<void> deleteLeave(
    String leaveId,
  );

  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  });
}
'@

# ============================================================
# REMOTE DATA SOURCE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\data\datasources\staff_leave_remote_datasource.dart" `
    -Content @'
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../../domain/entities/staff_leave_entity.dart';
import '../models/staff_leave_model.dart';

abstract class StaffLeaveRemoteDataSource {
  Future<List<StaffLeaveModel>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveModel>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<StaffLeaveModel>> getPendingLeaves();

  Future<void> saveLeave(
    StaffLeaveModel leave,
  );

  Future<void> deleteLeave(
    String leaveId,
  );

  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  });
}

class StaffLeaveRemoteDataSourceImpl
    implements StaffLeaveRemoteDataSource {
  StaffLeaveRemoteDataSourceImpl(
    this._firestoreService,
  );

  final FirebaseFirestoreService _firestoreService;

  @override
  Future<List<StaffLeaveModel>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .where(
          'startDate',
          isLessThanOrEqualTo:
              normalizedEndDate.toIso8601String(),
        )
        .get();

    final leaves = snapshot.docs
        .map(
          (document) {
            return StaffLeaveModel.fromMap({
              ...document.data(),
              'id': document.id,
            });
          },
        )
        .where(
          (leave) =>
              !leave.endDate.isBefore(normalizedStartDate),
        )
        .toList();

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<List<StaffLeaveModel>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    );

    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .where(
          'staffId',
          isEqualTo: staffId,
        )
        .where(
          'startDate',
          isLessThanOrEqualTo:
              normalizedEndDate.toIso8601String(),
        )
        .get();

    final leaves = snapshot.docs
        .map(
          (document) {
            return StaffLeaveModel.fromMap({
              ...document.data(),
              'id': document.id,
            });
          },
        )
        .where(
          (leave) =>
              !leave.endDate.isBefore(normalizedStartDate),
        )
        .toList();

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<List<StaffLeaveModel>> getPendingLeaves() async {
    final snapshot = await _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .where(
          'status',
          isEqualTo: StaffLeaveStatus.pending.name,
        )
        .get();

    final leaves = snapshot.docs.map(
      (document) {
        return StaffLeaveModel.fromMap({
          ...document.data(),
          'id': document.id,
        });
      },
    ).toList();

    _sortLeaves(leaves);

    return leaves;
  }

  @override
  Future<void> saveLeave(
    StaffLeaveModel leave,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leave.id)
        .set(leave.toMap());
  }

  @override
  Future<void> deleteLeave(
    String leaveId,
  ) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leaveId)
        .delete();
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  }) {
    return _firestoreService
        .collection(FirestorePaths.staffLeaves)
        .doc(leaveId)
        .update({
      'status': status.name,
      'approvalRemarks': approvalRemarks,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    });
  }

  void _sortLeaves(
    List<StaffLeaveModel> leaves,
  ) {
    leaves.sort((first, second) {
      final dateComparison =
          second.startDate.compareTo(first.startDate);

      if (dateComparison != 0) {
        return dateComparison;
      }

      return first.staffName.toLowerCase().compareTo(
            second.staffName.toLowerCase(),
          );
    });
  }
}
'@

# ============================================================
# REPOSITORY IMPLEMENTATION
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\data\repositories\staff_leave_repository_impl.dart" `
    -Content @'
import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/repositories/staff_leave_repository.dart';
import '../datasources/staff_leave_remote_datasource.dart';
import '../models/staff_leave_model.dart';

class StaffLeaveRepositoryImpl
    implements StaffLeaveRepository {
  const StaffLeaveRepositoryImpl(
    this._remoteDataSource,
  );

  final StaffLeaveRemoteDataSource _remoteDataSource;

  @override
  Future<List<StaffLeaveEntity>> getLeavesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getLeavesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<StaffLeaveEntity>> getLeavesByStaff({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _remoteDataSource.getLeavesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<StaffLeaveEntity>> getPendingLeaves() {
    return _remoteDataSource.getPendingLeaves();
  }

  @override
  Future<void> saveLeave(
    StaffLeaveEntity leave,
  ) {
    return _remoteDataSource.saveLeave(
      StaffLeaveModel.fromEntity(leave),
    );
  }

  @override
  Future<void> deleteLeave(
    String leaveId,
  ) {
    return _remoteDataSource.deleteLeave(leaveId);
  }

  @override
  Future<void> updateLeaveStatus({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
    required DateTime? approvedAt,
    required DateTime updatedAt,
  }) {
    return _remoteDataSource.updateLeaveStatus(
      leaveId: leaveId,
      status: status,
      approvalRemarks: approvalRemarks,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      updatedAt: updatedAt,
    );
  }
}
'@

# ============================================================
# USE CASES
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\get_staff_leaves_by_date_range.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetStaffLeavesByDateRange {
  const GetStaffLeavesByDateRange(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getLeavesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
'@

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\get_staff_leaves_by_staff.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetStaffLeavesByStaff {
  const GetStaffLeavesByStaff(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call({
    required String staffId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return repository.getLeavesByStaff(
      staffId: staffId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
'@

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\get_pending_staff_leaves.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class GetPendingStaffLeaves {
  const GetPendingStaffLeaves(this.repository);

  final StaffLeaveRepository repository;

  Future<List<StaffLeaveEntity>> call() {
    return repository.getPendingLeaves();
  }
}
'@

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\save_staff_leave.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class SaveStaffLeave {
  const SaveStaffLeave(this.repository);

  final StaffLeaveRepository repository;

  Future<void> call(
    StaffLeaveEntity leave,
  ) {
    return repository.saveLeave(leave);
  }
}
'@

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\delete_staff_leave.dart" `
    -Content @'
import '../repositories/staff_leave_repository.dart';

class DeleteStaffLeave {
  const DeleteStaffLeave(this.repository);

  final StaffLeaveRepository repository;

  Future<void> call(
    String leaveId,
  ) {
    return repository.deleteLeave(leaveId);
  }
}
'@

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\update_staff_leave_status.dart" `
    -Content @'
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_leave_repository.dart';

class UpdateStaffLeaveStatus {
  const UpdateStaffLeaveStatus(this.repository);

  final StaffLeaveRepository repository;

  Future<void> call({
    required String leaveId,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
  }) {
    final isDecision =
        status == StaffLeaveStatus.approved ||
        status == StaffLeaveStatus.rejected;

    return repository.updateLeaveStatus(
      leaveId: leaveId,
      status: status,
      approvalRemarks: approvalRemarks.trim(),
      approvedBy: isDecision ? approvedBy.trim() : '',
      approvedAt: isDecision ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }
}
'@

# ============================================================
# BLoC EVENT
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\bloc\staff_leave_event.dart" `
    -Content @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_leave_entity.dart';

sealed class StaffLeaveEvent extends Equatable {
  const StaffLeaveEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffLeavesByDateRangeEvent
    extends StaffLeaveEvent {
  const LoadStaffLeavesByDateRangeEvent({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        startDate,
        endDate,
      ];
}

class LoadStaffLeaveHistoryEvent extends StaffLeaveEvent {
  const LoadStaffLeaveHistoryEvent({
    required this.staffId,
    required this.startDate,
    required this.endDate,
  });

  final String staffId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  List<Object> get props => [
        staffId,
        startDate,
        endDate,
      ];
}

class LoadPendingStaffLeavesEvent
    extends StaffLeaveEvent {
  const LoadPendingStaffLeavesEvent();
}

class SaveStaffLeaveEvent extends StaffLeaveEvent {
  const SaveStaffLeaveEvent(this.leave);

  final StaffLeaveEntity leave;

  @override
  List<Object> get props => [leave];
}

class DeleteStaffLeaveEvent extends StaffLeaveEvent {
  const DeleteStaffLeaveEvent(this.leaveId);

  final String leaveId;

  @override
  List<Object> get props => [leaveId];
}

class UpdateStaffLeaveStatusEvent
    extends StaffLeaveEvent {
  const UpdateStaffLeaveStatusEvent({
    required this.leaveId,
    required this.status,
    required this.approvalRemarks,
    required this.approvedBy,
  });

  final String leaveId;
  final StaffLeaveStatus status;
  final String approvalRemarks;
  final String approvedBy;

  @override
  List<Object> get props => [
        leaveId,
        status,
        approvalRemarks,
        approvedBy,
      ];
}
'@

# ============================================================
# BLoC STATE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\bloc\staff_leave_state.dart" `
    -Content @'
import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_leave_entity.dart';

sealed class StaffLeaveState extends Equatable {
  const StaffLeaveState();

  @override
  List<Object?> get props => [];
}

class StaffLeaveInitial extends StaffLeaveState {
  const StaffLeaveInitial();
}

class StaffLeaveLoading extends StaffLeaveState {
  const StaffLeaveLoading();
}

class StaffLeaveLoaded extends StaffLeaveState {
  const StaffLeaveLoaded({
    required this.leaves,
    this.staffId,
    this.startDate,
    this.endDate,
    this.pendingOnly = false,
    this.successMessage,
  });

  final List<StaffLeaveEntity> leaves;
  final String? staffId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool pendingOnly;
  final String? successMessage;

  @override
  List<Object?> get props => [
        leaves,
        staffId,
        startDate,
        endDate,
        pendingOnly,
        successMessage,
      ];
}

class StaffLeaveError extends StaffLeaveState {
  const StaffLeaveError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}
'@

# ============================================================
# BLoC
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\presentation\bloc\staff_leave_bloc.dart" `
    -Content @'
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/staff_leave_entity.dart';
import '../../domain/usecases/delete_staff_leave.dart';
import '../../domain/usecases/get_pending_staff_leaves.dart';
import '../../domain/usecases/get_staff_leaves_by_date_range.dart';
import '../../domain/usecases/get_staff_leaves_by_staff.dart';
import '../../domain/usecases/save_staff_leave.dart';
import '../../domain/usecases/update_staff_leave_status.dart';
import 'staff_leave_event.dart';
import 'staff_leave_state.dart';

class StaffLeaveBloc
    extends Bloc<StaffLeaveEvent, StaffLeaveState> {
  StaffLeaveBloc(
    this._getStaffLeavesByDateRange,
    this._getStaffLeavesByStaff,
    this._getPendingStaffLeaves,
    this._saveStaffLeave,
    this._deleteStaffLeave,
    this._updateStaffLeaveStatus,
  ) : super(const StaffLeaveInitial()) {
    on<LoadStaffLeavesByDateRangeEvent>(
      _onLoadByDateRange,
    );
    on<LoadStaffLeaveHistoryEvent>(
      _onLoadHistory,
    );
    on<LoadPendingStaffLeavesEvent>(
      _onLoadPending,
    );
    on<SaveStaffLeaveEvent>(
      _onSaveLeave,
    );
    on<DeleteStaffLeaveEvent>(
      _onDeleteLeave,
    );
    on<UpdateStaffLeaveStatusEvent>(
      _onUpdateStatus,
    );
  }

  final GetStaffLeavesByDateRange
      _getStaffLeavesByDateRange;
  final GetStaffLeavesByStaff
      _getStaffLeavesByStaff;
  final GetPendingStaffLeaves
      _getPendingStaffLeaves;
  final SaveStaffLeave _saveStaffLeave;
  final DeleteStaffLeave _deleteStaffLeave;
  final UpdateStaffLeaveStatus
      _updateStaffLeaveStatus;

  String? _currentStaffId;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;
  bool _pendingOnly = false;

  Future<void> _onLoadByDateRange(
    LoadStaffLeavesByDateRangeEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    _currentStaffId = null;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _pendingOnly = false;

    await _loadCurrentView(emit);
  }

  Future<void> _onLoadHistory(
    LoadStaffLeaveHistoryEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    _currentStaffId = event.staffId;
    _currentStartDate = event.startDate;
    _currentEndDate = event.endDate;
    _pendingOnly = false;

    await _loadCurrentView(emit);
  }

  Future<void> _onLoadPending(
    LoadPendingStaffLeavesEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    _currentStaffId = null;
    _currentStartDate = null;
    _currentEndDate = null;
    _pendingOnly = true;

    await _loadCurrentView(emit);
  }

  Future<void> _onSaveLeave(
    SaveStaffLeaveEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    emit(const StaffLeaveLoading());

    try {
      await _saveStaffLeave(event.leave);

      await _loadCurrentView(
        emit,
        successMessage:
            'Staff leave saved successfully.',
        showLoading: false,
      );
    } catch (error) {
      emit(StaffLeaveError(error.toString()));
    }
  }

  Future<void> _onDeleteLeave(
    DeleteStaffLeaveEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    emit(const StaffLeaveLoading());

    try {
      await _deleteStaffLeave(event.leaveId);

      await _loadCurrentView(
        emit,
        successMessage:
            'Staff leave deleted successfully.',
        showLoading: false,
      );
    } catch (error) {
      emit(StaffLeaveError(error.toString()));
    }
  }

  Future<void> _onUpdateStatus(
    UpdateStaffLeaveStatusEvent event,
    Emitter<StaffLeaveState> emit,
  ) async {
    emit(const StaffLeaveLoading());

    try {
      await _updateStaffLeaveStatus(
        leaveId: event.leaveId,
        status: event.status,
        approvalRemarks: event.approvalRemarks,
        approvedBy: event.approvedBy,
      );

      final action = _statusAction(event.status);

      await _loadCurrentView(
        emit,
        successMessage:
            'Staff leave $action successfully.',
        showLoading: false,
      );
    } catch (error) {
      emit(StaffLeaveError(error.toString()));
    }
  }

  Future<void> _loadCurrentView(
    Emitter<StaffLeaveState> emit, {
    String? successMessage,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      emit(const StaffLeaveLoading());
    }

    try {
      late final List<StaffLeaveEntity> leaves;

      if (_pendingOnly) {
        leaves = await _getPendingStaffLeaves();
      } else if (_currentStaffId != null &&
          _currentStartDate != null &&
          _currentEndDate != null) {
        leaves = await _getStaffLeavesByStaff(
          staffId: _currentStaffId!,
          startDate: _currentStartDate!,
          endDate: _currentEndDate!,
        );
      } else {
        final now = DateTime.now();
        final startDate = _currentStartDate ??
            DateTime(now.year, now.month, 1);
        final endDate = _currentEndDate ??
            DateTime(now.year, now.month + 1, 0);

        _currentStartDate = startDate;
        _currentEndDate = endDate;

        leaves = await _getStaffLeavesByDateRange(
          startDate: startDate,
          endDate: endDate,
        );
      }

      emit(
        StaffLeaveLoaded(
          leaves: leaves,
          staffId: _currentStaffId,
          startDate: _currentStartDate,
          endDate: _currentEndDate,
          pendingOnly: _pendingOnly,
          successMessage: successMessage,
        ),
      );
    } catch (error) {
      emit(StaffLeaveError(error.toString()));
    }
  }

  String _statusAction(
    StaffLeaveStatus status,
  ) {
    switch (status) {
      case StaffLeaveStatus.pending:
        return 'reset to pending';
      case StaffLeaveStatus.approved:
        return 'approved';
      case StaffLeaveStatus.rejected:
        return 'rejected';
      case StaffLeaveStatus.cancelled:
        return 'cancelled';
    }
  }
}
'@

Write-Host ""
Write-Host "Phase 4A Staff Leave Core files created successfully." -ForegroundColor Cyan
Write-Host "Existing integration and UI files were not changed." -ForegroundColor Yellow
Write-Host ""
