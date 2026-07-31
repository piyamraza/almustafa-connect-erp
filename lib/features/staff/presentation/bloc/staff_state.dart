import 'package:equatable/equatable.dart';

import '../../domain/entities/staff_entity.dart';

sealed class StaffState extends Equatable {
  const StaffState();

  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {
  const StaffInitial();
}

class StaffLoading extends StaffState {
  const StaffLoading();
}

class StaffLoaded extends StaffState {
  const StaffLoaded({
    required this.allStaff,
    required this.visibleStaff,
    this.searchQuery = '',
    this.successMessage,
  });

  final List<StaffEntity> allStaff;
  final List<StaffEntity> visibleStaff;
  final String searchQuery;
  final String? successMessage;

  StaffLoaded copyWith({
    List<StaffEntity>? allStaff,
    List<StaffEntity>? visibleStaff,
    String? searchQuery,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return StaffLoaded(
      allStaff: allStaff ?? this.allStaff,
      visibleStaff: visibleStaff ?? this.visibleStaff,
      searchQuery: searchQuery ?? this.searchQuery,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        allStaff,
        visibleStaff,
        searchQuery,
        successMessage,
      ];
}

class StaffError extends StaffState {
  const StaffError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}