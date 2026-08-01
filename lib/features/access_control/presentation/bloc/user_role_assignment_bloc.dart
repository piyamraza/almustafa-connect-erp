import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_role_assignment_entity.dart';
import '../../domain/repositories/user_role_assignment_repository.dart';

sealed class UserRoleAssignmentEvent {
  const UserRoleAssignmentEvent();
}

class LoadUserRoleAssignments extends UserRoleAssignmentEvent {
  const LoadUserRoleAssignments({this.roleId, this.isActive, this.searchText});

  final String? roleId;
  final bool? isActive;
  final String? searchText;
}

class SaveUserRoleAssignment extends UserRoleAssignmentEvent {
  const SaveUserRoleAssignment(this.assignment);

  final UserRoleAssignmentEntity assignment;
}

class DeleteUserRoleAssignment extends UserRoleAssignmentEvent {
  const DeleteUserRoleAssignment(this.id);

  final String id;
}

sealed class UserRoleAssignmentState {
  const UserRoleAssignmentState();
}

class UserRoleAssignmentInitial extends UserRoleAssignmentState {
  const UserRoleAssignmentInitial();
}

class UserRoleAssignmentLoading extends UserRoleAssignmentState {
  const UserRoleAssignmentLoading();
}

class UserRoleAssignmentLoaded extends UserRoleAssignmentState {
  const UserRoleAssignmentLoaded(this.assignments, {this.message});

  final List<UserRoleAssignmentEntity> assignments;
  final String? message;
}

class UserRoleAssignmentError extends UserRoleAssignmentState {
  const UserRoleAssignmentError(this.message);

  final String message;
}

class UserRoleAssignmentBloc
    extends Bloc<UserRoleAssignmentEvent, UserRoleAssignmentState> {
  UserRoleAssignmentBloc(this._repository)
    : super(const UserRoleAssignmentInitial()) {
    on<LoadUserRoleAssignments>(_load);
    on<SaveUserRoleAssignment>(_save);
    on<DeleteUserRoleAssignment>(_delete);
  }

  final UserRoleAssignmentRepository _repository;
  LoadUserRoleAssignments _lastLoad = const LoadUserRoleAssignments();

  Future<void> _load(
    LoadUserRoleAssignments event,
    Emitter<UserRoleAssignmentState> emit,
  ) async {
    _lastLoad = event;
    await _reload(emit);
  }

  Future<void> _save(
    SaveUserRoleAssignment event,
    Emitter<UserRoleAssignmentState> emit,
  ) async {
    emit(const UserRoleAssignmentLoading());

    try {
      await _repository.saveAssignment(event.assignment);
      await _reload(emit, message: 'User role assignment saved.');
    } catch (error) {
      emit(
        UserRoleAssignmentError(
          error.toString().replaceFirst('StateError: ', ''),
        ),
      );
    }
  }

  Future<void> _delete(
    DeleteUserRoleAssignment event,
    Emitter<UserRoleAssignmentState> emit,
  ) async {
    emit(const UserRoleAssignmentLoading());

    try {
      await _repository.deleteAssignment(event.id);
      await _reload(emit, message: 'Assignment deleted.');
    } catch (error) {
      emit(UserRoleAssignmentError(error.toString()));
    }
  }

  Future<void> _reload(
    Emitter<UserRoleAssignmentState> emit, {
    String? message,
  }) async {
    emit(const UserRoleAssignmentLoading());

    try {
      emit(
        UserRoleAssignmentLoaded(
          await _repository.getAssignments(
            roleId: _lastLoad.roleId,
            isActive: _lastLoad.isActive,
            searchText: _lastLoad.searchText,
          ),
          message: message,
        ),
      );
    } catch (error) {
      emit(UserRoleAssignmentError(error.toString()));
    }
  }
}
