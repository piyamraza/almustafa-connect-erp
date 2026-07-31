import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_attendance_entity.dart';

sealed class StaffAttendanceState extends Equatable {
  const StaffAttendanceState();

  @override
  List<Object?> get props => [];
}

class StaffAttendanceInitial extends StaffAttendanceState {
  const StaffAttendanceInitial();
}

class StaffAttendanceLoading extends StaffAttendanceState {
  const StaffAttendanceLoading();
}

class StaffAttendanceLoaded extends StaffAttendanceState {
  const StaffAttendanceLoaded({
    required this.records,
    this.selectedDate,
    this.startDate,
    this.endDate,
    this.staffId,
    this.successMessage,
  });

  final List<StaffAttendanceEntity> records;
  final DateTime? selectedDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? staffId;
  final String? successMessage;

  StaffAttendanceLoaded copyWith({
    List<StaffAttendanceEntity>? records,
    DateTime? selectedDate,
    DateTime? startDate,
    DateTime? endDate,
    String? staffId,
    String? successMessage,
    bool clearSelectedDate = false,
    bool clearDateRange = false,
    bool clearStaffId = false,
    bool clearSuccessMessage = false,
  }) {
    return StaffAttendanceLoaded(
      records: records ?? this.records,
      selectedDate:
          clearSelectedDate ? null : selectedDate ?? this.selectedDate,
      startDate: clearDateRange ? null : startDate ?? this.startDate,
      endDate: clearDateRange ? null : endDate ?? this.endDate,
      staffId: clearStaffId ? null : staffId ?? this.staffId,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        records,
        selectedDate,
        startDate,
        endDate,
        staffId,
        successMessage,
      ];
}

class StaffAttendanceError extends StaffAttendanceState {
  const StaffAttendanceError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}