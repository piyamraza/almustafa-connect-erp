import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_entity.dart';

sealed class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

class LoadStaffEvent extends StaffEvent {
  const LoadStaffEvent();
}

class AddStaffEvent extends StaffEvent {
  const AddStaffEvent(this.staff);

  final StaffEntity staff;

  @override
  List<Object> get props => [staff];
}

class UpdateStaffEvent extends StaffEvent {
  const UpdateStaffEvent(this.staff);

  final StaffEntity staff;

  @override
  List<Object> get props => [staff];
}

class DeleteStaffEvent extends StaffEvent {
  const DeleteStaffEvent(this.id);

  final String id;

  @override
  List<Object> get props => [id];
}

class ToggleStaffStatusEvent extends StaffEvent {
  const ToggleStaffStatusEvent({
    required this.staff,
    required this.isActive,
  });

  final StaffEntity staff;
  final bool isActive;

  @override
  List<Object> get props => [staff, isActive];
}

class SearchStaffEvent extends StaffEvent {
  const SearchStaffEvent(this.query);

  final String query;

  @override
  List<Object> get props => [query];
}