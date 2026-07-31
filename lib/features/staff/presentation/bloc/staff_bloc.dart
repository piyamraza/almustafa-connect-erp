import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/staff_entity.dart';
import '../../domain/usecases/add_staff.dart';
import '../../domain/usecases/delete_staff.dart';
import '../../domain/usecases/get_staff.dart';
import '../../domain/usecases/toggle_staff_status.dart';
import '../../domain/usecases/update_staff.dart';
import 'staff_event.dart';
import 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  StaffBloc({
    required GetStaff getStaff,
    required AddStaff addStaff,
    required UpdateStaff updateStaff,
    required DeleteStaff deleteStaff,
    required ToggleStaffStatus toggleStaffStatus,
  })  : _getStaff = getStaff,
        _addStaff = addStaff,
        _updateStaff = updateStaff,
        _deleteStaff = deleteStaff,
        _toggleStaffStatus = toggleStaffStatus,
        super(const StaffInitial()) {
    on<LoadStaffEvent>(_onLoadStaff);
    on<AddStaffEvent>(_onAddStaff);
    on<UpdateStaffEvent>(_onUpdateStaff);
    on<DeleteStaffEvent>(_onDeleteStaff);
    on<ToggleStaffStatusEvent>(_onToggleStaffStatus);
    on<SearchStaffEvent>(_onSearchStaff);
  }

  final GetStaff _getStaff;
  final AddStaff _addStaff;
  final UpdateStaff _updateStaff;
  final DeleteStaff _deleteStaff;
  final ToggleStaffStatus _toggleStaffStatus;

  Future<void> _onLoadStaff(
    LoadStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());

    try {
      final staff = await _getStaff();

      emit(
        StaffLoaded(
          allStaff: staff,
          visibleStaff: staff,
        ),
      );
    } catch (error) {
      emit(StaffError(error.toString()));
    }
  }

  Future<void> _onAddStaff(
    AddStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());

    try {
      await _addStaff(event.staff);

      final staff = await _getStaff();

      emit(
        StaffLoaded(
          allStaff: staff,
          visibleStaff: staff,
          successMessage: 'Staff member added successfully.',
        ),
      );
    } catch (error) {
      emit(StaffError(error.toString()));
    }
  }

  Future<void> _onUpdateStaff(
    UpdateStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());

    try {
      await _updateStaff(event.staff);

      final staff = await _getStaff();

      emit(
        StaffLoaded(
          allStaff: staff,
          visibleStaff: staff,
          successMessage: 'Staff member updated successfully.',
        ),
      );
    } catch (error) {
      emit(StaffError(error.toString()));
    }
  }

  Future<void> _onDeleteStaff(
    DeleteStaffEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());

    try {
      await _deleteStaff(event.id);

      final staff = await _getStaff();

      emit(
        StaffLoaded(
          allStaff: staff,
          visibleStaff: staff,
          successMessage: 'Staff member deleted successfully.',
        ),
      );
    } catch (error) {
      emit(StaffError(error.toString()));
    }
  }

  Future<void> _onToggleStaffStatus(
    ToggleStaffStatusEvent event,
    Emitter<StaffState> emit,
  ) async {
    emit(const StaffLoading());

    try {
      await _toggleStaffStatus(
        staff: event.staff,
        isActive: event.isActive,
      );

      final staff = await _getStaff();

      emit(
        StaffLoaded(
          allStaff: staff,
          visibleStaff: staff,
          successMessage: event.isActive
              ? 'Staff member activated successfully.'
              : 'Staff member deactivated successfully.',
        ),
      );
    } catch (error) {
      emit(StaffError(error.toString()));
    }
  }

  void _onSearchStaff(
    SearchStaffEvent event,
    Emitter<StaffState> emit,
  ) {
    final currentState = state;

    if (currentState is! StaffLoaded) {
      return;
    }

    final query = event.query.trim().toLowerCase();

    if (query.isEmpty) {
      emit(
        currentState.copyWith(
          visibleStaff: currentState.allStaff,
          searchQuery: '',
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    final filteredStaff = currentState.allStaff.where(
      (StaffEntity staff) {
        return staff.fullName.toLowerCase().contains(query) ||
            staff.staffId.toLowerCase().contains(query) ||
            staff.cnic.toLowerCase().contains(query) ||
            staff.phone.toLowerCase().contains(query) ||
            staff.designation.toLowerCase().contains(query);
      },
    ).toList();

    emit(
      currentState.copyWith(
        visibleStaff: filteredStaff,
        searchQuery: event.query,
        clearSuccessMessage: true,
      ),
    );
  }
}