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