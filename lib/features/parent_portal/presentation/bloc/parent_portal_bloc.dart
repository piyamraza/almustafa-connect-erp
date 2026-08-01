import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../students/domain/entities/student_entity.dart';
import '../../domain/entities/parent_account_entity.dart';
import '../../domain/repositories/parent_portal_repository.dart';

sealed class ParentPortalEvent {
  const ParentPortalEvent();
}

class LoadParentAccounts extends ParentPortalEvent {
  const LoadParentAccounts();
}

class SelectParentAccount extends ParentPortalEvent {
  const SelectParentAccount(this.parent);

  final ParentAccountEntity parent;
}

class SaveParentAccount extends ParentPortalEvent {
  const SaveParentAccount(this.parent);

  final ParentAccountEntity parent;
}

class DeleteParentAccount extends ParentPortalEvent {
  const DeleteParentAccount(this.id);

  final String id;
}

sealed class ParentPortalState {
  const ParentPortalState();
}

class ParentPortalInitial extends ParentPortalState {
  const ParentPortalInitial();
}

class ParentPortalLoading extends ParentPortalState {
  const ParentPortalLoading();
}

class ParentPortalLoaded extends ParentPortalState {
  const ParentPortalLoaded({
    required this.parents,
    required this.selectedParent,
    required this.linkedStudents,
    this.message,
  });

  final List<ParentAccountEntity> parents;
  final ParentAccountEntity? selectedParent;
  final List<StudentEntity> linkedStudents;
  final String? message;
}

class ParentPortalError extends ParentPortalState {
  const ParentPortalError(this.message);

  final String message;
}

class ParentPortalBloc extends Bloc<ParentPortalEvent, ParentPortalState> {
  ParentPortalBloc(this._repository) : super(const ParentPortalInitial()) {
    on<LoadParentAccounts>(_load);
    on<SelectParentAccount>(_select);
    on<SaveParentAccount>(_save);
    on<DeleteParentAccount>(_delete);
  }

  final ParentPortalRepository _repository;
  ParentAccountEntity? _selected;

  Future<void> _load(
    LoadParentAccounts event,
    Emitter<ParentPortalState> emit,
  ) async {
    await _reload(emit);
  }

  Future<void> _select(
    SelectParentAccount event,
    Emitter<ParentPortalState> emit,
  ) async {
    _selected = event.parent;
    await _reload(emit);
  }

  Future<void> _save(
    SaveParentAccount event,
    Emitter<ParentPortalState> emit,
  ) async {
    emit(const ParentPortalLoading());
    try {
      await _repository.saveParent(event.parent);
      _selected = event.parent;
      await _reload(emit, message: 'Parent account saved successfully.');
    } catch (error) {
      emit(ParentPortalError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteParentAccount event,
    Emitter<ParentPortalState> emit,
  ) async {
    emit(const ParentPortalLoading());
    try {
      await _repository.deleteParent(event.id);
      if (_selected?.id == event.id) _selected = null;
      await _reload(emit, message: 'Parent account deleted.');
    } catch (error) {
      emit(ParentPortalError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<ParentPortalState> emit, {
    String? message,
  }) async {
    emit(const ParentPortalLoading());

    try {
      final parents = await _repository.getParents();

      if (_selected != null) {
        _selected = parents
            .where((item) => item.id == _selected!.id)
            .firstOrNull;
      }

      final linkedStudents = _selected == null
          ? <StudentEntity>[]
          : await _repository.getLinkedStudents(_selected!);

      emit(
        ParentPortalLoaded(
          parents: parents,
          selectedParent: _selected,
          linkedStudents: linkedStudents,
          message: message,
        ),
      );
    } catch (error) {
      emit(ParentPortalError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
