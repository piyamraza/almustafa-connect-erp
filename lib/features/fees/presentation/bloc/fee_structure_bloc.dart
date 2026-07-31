import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/fee_structure_entity.dart';
import '../../domain/repositories/fee_structure_repository.dart';

sealed class FeeStructureEvent {
  const FeeStructureEvent();
}

class LoadFeeStructures extends FeeStructureEvent {
  const LoadFeeStructures({this.academicSession});

  final String? academicSession;
}

class SaveFeeStructure extends FeeStructureEvent {
  const SaveFeeStructure(this.structure);

  final FeeStructureEntity structure;
}

class DeleteFeeStructure extends FeeStructureEvent {
  const DeleteFeeStructure(this.id);

  final String id;
}

sealed class FeeStructureState {
  const FeeStructureState();
}

class FeeStructureInitial extends FeeStructureState {
  const FeeStructureInitial();
}

class FeeStructureLoading extends FeeStructureState {
  const FeeStructureLoading();
}

class FeeStructureLoaded extends FeeStructureState {
  const FeeStructureLoaded(this.structures, {this.message});

  final List<FeeStructureEntity> structures;
  final String? message;
}

class FeeStructureError extends FeeStructureState {
  const FeeStructureError(this.message);

  final String message;
}

class FeeStructureBloc extends Bloc<FeeStructureEvent, FeeStructureState> {
  FeeStructureBloc(this._repository) : super(const FeeStructureInitial()) {
    on<LoadFeeStructures>(_load);
    on<SaveFeeStructure>(_save);
    on<DeleteFeeStructure>(_delete);
  }

  final FeeStructureRepository _repository;
  String? _session;

  Future<void> _load(
    LoadFeeStructures event,
    Emitter<FeeStructureState> emit,
  ) async {
    _session = event.academicSession;
    await _reload(emit);
  }

  Future<void> _save(
    SaveFeeStructure event,
    Emitter<FeeStructureState> emit,
  ) async {
    emit(const FeeStructureLoading());
    try {
      await _repository.saveFeeStructure(event.structure);
      await _reload(emit, message: 'Fee structure saved successfully.');
    } catch (error) {
      emit(FeeStructureError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteFeeStructure event,
    Emitter<FeeStructureState> emit,
  ) async {
    emit(const FeeStructureLoading());
    try {
      await _repository.deleteFeeStructure(event.id);
      await _reload(emit, message: 'Fee structure deleted.');
    } catch (error) {
      emit(FeeStructureError(_message(error)));
    }
  }

  Future<void> _reload(
    Emitter<FeeStructureState> emit, {
    String? message,
  }) async {
    emit(const FeeStructureLoading());
    try {
      final values = await _repository.getFeeStructures(
        academicSession: _session,
      );
      emit(FeeStructureLoaded(values, message: message));
    } catch (error) {
      emit(FeeStructureError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
