import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/app_role_entity.dart';
import '../../domain/repositories/app_role_repository.dart';

sealed class AppRoleEvent {
  const AppRoleEvent();
}

class LoadAppRoles extends AppRoleEvent {
  const LoadAppRoles();
}

class SaveAppRole extends AppRoleEvent {
  const SaveAppRole(this.role);
  final AppRoleEntity role;
}

class DeleteAppRole extends AppRoleEvent {
  const DeleteAppRole(this.id);
  final String id;
}

class SeedDefaultAppRoles extends AppRoleEvent {
  const SeedDefaultAppRoles();
}

sealed class AppRoleState {
  const AppRoleState();
}

class AppRoleInitial extends AppRoleState {
  const AppRoleInitial();
}

class AppRoleLoading extends AppRoleState {
  const AppRoleLoading();
}

class AppRoleLoaded extends AppRoleState {
  const AppRoleLoaded(this.roles, {this.message});
  final List<AppRoleEntity> roles;
  final String? message;
}

class AppRoleError extends AppRoleState {
  const AppRoleError(this.message);
  final String message;
}

class AppRoleBloc extends Bloc<AppRoleEvent, AppRoleState> {
  AppRoleBloc(this._repository) : super(const AppRoleInitial()) {
    on<LoadAppRoles>(_load);
    on<SaveAppRole>(_save);
    on<DeleteAppRole>(_delete);
    on<SeedDefaultAppRoles>(_seed);
  }

  final AppRoleRepository _repository;

  Future<void> _load(LoadAppRoles event, Emitter<AppRoleState> emit) async {
    await _reload(emit);
  }

  Future<void> _save(SaveAppRole event, Emitter<AppRoleState> emit) async {
    emit(const AppRoleLoading());
    try {
      await _repository.saveRole(event.role);
      await _reload(emit, message: 'Role saved successfully.');
    } catch (error) {
      emit(AppRoleError(_message(error)));
    }
  }

  Future<void> _delete(DeleteAppRole event, Emitter<AppRoleState> emit) async {
    emit(const AppRoleLoading());
    try {
      await _repository.deleteRole(event.id);
      await _reload(emit, message: 'Role deleted.');
    } catch (error) {
      emit(AppRoleError(_message(error)));
    }
  }

  Future<void> _seed(
    SeedDefaultAppRoles event,
    Emitter<AppRoleState> emit,
  ) async {
    emit(const AppRoleLoading());
    try {
      await _repository.seedDefaultRoles();
      await _reload(emit, message: 'Default roles created successfully.');
    } catch (error) {
      emit(AppRoleError(_message(error)));
    }
  }

  Future<void> _reload(Emitter<AppRoleState> emit, {String? message}) async {
    emit(const AppRoleLoading());
    try {
      emit(AppRoleLoaded(await _repository.getRoles(), message: message));
    } catch (error) {
      emit(AppRoleError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
