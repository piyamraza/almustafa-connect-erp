$ErrorActionPreference = "Stop"

$projectRoot = "D:\Projects\almustafa-connect-erp"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project folder not found: $projectRoot"
}

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

    if (Test-Path -LiteralPath $fullPath) {
        $backupPath = "$fullPath.leave_attendance_$timestamp.bak"
        Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
        Write-Host "Backup: $backupPath" -ForegroundColor DarkGray
    }

    [System.IO.File]::WriteAllText(
        $fullPath,
        $Content,
        $utf8NoBom
    )

    Write-Host "Updated: $RelativePath" -ForegroundColor Green
}

function Update-ServiceLocator {
    $relativePath = "lib\core\di\service_locator.dart"
    $fullPath = Join-Path $projectRoot $relativePath

    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Required file not found: $fullPath"
    }

    $content = [System.IO.File]::ReadAllText($fullPath)
    $originalContent = $content

    $pattern = @'
(?s)sl\.registerLazySingleton<UpdateStaffLeaveStatus>\(\s*\(\)\s*=>\s*UpdateStaffLeaveStatus\(\s*sl<StaffLeaveRepository>\(\),\s*\),\s*\);
'@

    $replacement = @'
sl.registerLazySingleton<UpdateStaffLeaveStatus>(
    () => UpdateStaffLeaveStatus(
      sl<StaffLeaveRepository>(),
      sl<StaffAttendanceRepository>(),
    ),
  );
'@

    if ($content.Contains("sl<StaffAttendanceRepository>(),") -and
        $content.Contains("UpdateStaffLeaveStatus(")) {
        Write-Host "Already configured: $relativePath" -ForegroundColor Yellow
        return
    }

    $updatedContent = [regex]::Replace(
        $content,
        $pattern,
        $replacement,
        1
    )

    if ($updatedContent -eq $content) {
        throw "UpdateStaffLeaveStatus registration marker was not found in service_locator.dart"
    }

    $backupPath = "$fullPath.leave_attendance_$timestamp.bak"
    Copy-Item -LiteralPath $fullPath -Destination $backupPath -Force
    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray

    [System.IO.File]::WriteAllText(
        $fullPath,
        $updatedContent,
        $utf8NoBom
    )

    Write-Host "Updated: $relativePath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Almustafa Connect ERP - Approved Leave to Attendance Integration" -ForegroundColor Cyan
Write-Host "Project: $projectRoot" -ForegroundColor DarkGray
Write-Host ""

# ============================================================
# UPDATE LEAVE STATUS USE CASE
# ============================================================

Write-ProjectFile `
    -RelativePath "lib\features\staff\domain\usecases\update_staff_leave_status.dart" `
    -Content @'
import '../entities/staff_attendance_entity.dart';
import '../entities/staff_leave_entity.dart';
import '../repositories/staff_attendance_repository.dart';
import '../repositories/staff_leave_repository.dart';

class UpdateStaffLeaveStatus {
  const UpdateStaffLeaveStatus(
    this._leaveRepository,
    this._attendanceRepository,
  );

  final StaffLeaveRepository _leaveRepository;
  final StaffAttendanceRepository _attendanceRepository;

  Future<void> call({
    required StaffLeaveEntity leave,
    required StaffLeaveStatus status,
    required String approvalRemarks,
    required String approvedBy,
  }) async {
    final now = DateTime.now();
    final isDecision =
        status == StaffLeaveStatus.approved ||
        status == StaffLeaveStatus.rejected;

    if (status == StaffLeaveStatus.approved) {
      await _markApprovedLeaveAttendance(
        leave: leave,
        updatedAt: now,
      );
    }

    await _leaveRepository.updateLeaveStatus(
      leaveId: leave.id,
      status: status,
      approvalRemarks: approvalRemarks.trim(),
      approvedBy: isDecision ? approvedBy.trim() : '',
      approvedAt: isDecision ? now : null,
      updatedAt: now,
    );
  }

  Future<void> _markApprovedLeaveAttendance({
    required StaffLeaveEntity leave,
    required DateTime updatedAt,
  }) async {
    final startDate = _normalizeDate(leave.startDate);
    final endDate = _normalizeDate(leave.endDate);

    final existingAttendance =
        await _attendanceRepository.getAttendanceByStaff(
      staffId: leave.staffId,
      startDate: startDate,
      endDate: endDate,
    );

    final existingByDate = <String, StaffAttendanceEntity>{
      for (final attendance in existingAttendance)
        _dateKey(attendance.attendanceDate): attendance,
    };

    var currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      final key = _dateKey(currentDate);
      final existing = existingByDate[key];

      await _attendanceRepository.saveAttendance(
        StaffAttendanceEntity(
          id: existing?.id ??
              _attendanceId(
                staffId: leave.staffId,
                date: currentDate,
              ),
          staffId: leave.staffId,
          staffCode: leave.staffCode,
          staffName: leave.staffName,
          designation: leave.designation,
          attendanceDate: currentDate,
          status: StaffAttendanceStatus.leave,
          remarks: _attendanceRemarks(leave),
          createdAt: existing?.createdAt ?? updatedAt,
          updatedAt: updatedAt,
        ),
      );

      currentDate = currentDate.add(
        const Duration(days: 1),
      );
    }
  }

  String _attendanceRemarks(
    StaffLeaveEntity leave,
  ) {
    final leaveType = switch (leave.leaveType) {
      StaffLeaveType.casual => 'Casual Leave',
      StaffLeaveType.sick => 'Sick Leave',
      StaffLeaveType.annual => 'Annual Leave',
      StaffLeaveType.unpaid => 'Unpaid Leave',
      StaffLeaveType.other => 'Other Leave',
    };

    final duration = switch (leave.duration) {
      StaffLeaveDuration.fullDay => 'Full Day',
      StaffLeaveDuration.halfDay => 'Half Day',
    };

    return 'Approved $leaveType ($duration)';
  }

  String _attendanceId({
    required String staffId,
    required DateTime date,
  }) {
    return '${staffId}_${_dateKey(date)}';
  }

  String _dateKey(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    final month =
        normalizedDate.month.toString().padLeft(2, '0');
    final day =
        normalizedDate.day.toString().padLeft(2, '0');

    return '${normalizedDate.year}$month$day';
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}
'@

# ============================================================
# LEAVE EVENT
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
    required this.leave,
    required this.status,
    required this.approvalRemarks,
    required this.approvedBy,
  });

  final StaffLeaveEntity leave;
  final StaffLeaveStatus status;
  final String approvalRemarks;
  final String approvedBy;

  @override
  List<Object> get props => [
        leave,
        status,
        approvalRemarks,
        approvedBy,
      ];
}
'@

# ============================================================
# LEAVE BLOC
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
        leave: event.leave,
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

# ============================================================
# APPROVAL PAGE
# ============================================================

$approvalPagePath = Join-Path $projectRoot `
    "lib\features\staff\presentation\pages\staff_leave_approval_page.dart"

if (-not (Test-Path -LiteralPath $approvalPagePath)) {
    throw "Required file not found: $approvalPagePath"
}

$approvalContent =
    [System.IO.File]::ReadAllText($approvalPagePath)
$originalApprovalContent = $approvalContent

$approvalContent = $approvalContent.Replace(
    "leaveId: leave.id,",
    "leave: leave,"
)

if ($approvalContent -eq $originalApprovalContent -and
    -not $approvalContent.Contains("leave: leave,")) {
    throw "Approval page event marker 'leaveId: leave.id' was not found."
}

if ($approvalContent -ne $originalApprovalContent) {
    $backupPath =
        "$approvalPagePath.leave_attendance_$timestamp.bak"

    Copy-Item `
        -LiteralPath $approvalPagePath `
        -Destination $backupPath `
        -Force

    Write-Host "Backup: $backupPath" -ForegroundColor DarkGray

    [System.IO.File]::WriteAllText(
        $approvalPagePath,
        $approvalContent,
        $utf8NoBom
    )

    Write-Host `
        "Updated: lib\features\staff\presentation\pages\staff_leave_approval_page.dart" `
        -ForegroundColor Green
} else {
    Write-Host `
        "Already configured: staff_leave_approval_page.dart" `
        -ForegroundColor Yellow
}

# ============================================================
# SERVICE LOCATOR
# ============================================================

Update-ServiceLocator

Write-Host ""
Write-Host "Approved Leave to Staff Attendance integration completed." -ForegroundColor Cyan
Write-Host "Approved leave dates will now be saved as StaffAttendanceStatus.leave." -ForegroundColor Green
Write-Host "Existing attendance records on those dates will be updated, not duplicated." -ForegroundColor Green
Write-Host ""
