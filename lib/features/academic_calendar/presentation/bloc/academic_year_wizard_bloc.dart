import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/academic_year_config_entity.dart';
import '../../domain/repositories/academic_year_config_repository.dart';
import '../../domain/usecases/save_academic_year_wizard.dart';

sealed class AcademicYearWizardEvent {
  const AcademicYearWizardEvent();
}

class LoadAcademicYearConfig extends AcademicYearWizardEvent {
  const LoadAcademicYearConfig(this.academicSession);

  final String academicSession;
}

class SaveAcademicYearConfig extends AcademicYearWizardEvent {
  const SaveAcademicYearConfig(this.config);

  final AcademicYearConfigEntity config;
}

sealed class AcademicYearWizardState {
  const AcademicYearWizardState();
}

class AcademicYearWizardInitial extends AcademicYearWizardState {
  const AcademicYearWizardInitial();
}

class AcademicYearWizardLoading extends AcademicYearWizardState {
  const AcademicYearWizardLoading();
}

class AcademicYearWizardLoaded extends AcademicYearWizardState {
  const AcademicYearWizardLoaded({this.config, this.message});

  final AcademicYearConfigEntity? config;
  final String? message;
}

class AcademicYearWizardError extends AcademicYearWizardState {
  const AcademicYearWizardError(this.message);

  final String message;
}

class AcademicYearWizardBloc
    extends Bloc<AcademicYearWizardEvent, AcademicYearWizardState> {
  AcademicYearWizardBloc(this._repository, this._saveWizard)
    : super(const AcademicYearWizardInitial()) {
    on<LoadAcademicYearConfig>(_load);
    on<SaveAcademicYearConfig>(_save);
  }

  final AcademicYearConfigRepository _repository;
  final SaveAcademicYearWizard _saveWizard;

  Future<void> _load(
    LoadAcademicYearConfig event,
    Emitter<AcademicYearWizardState> emit,
  ) async {
    emit(const AcademicYearWizardLoading());
    try {
      final config = await _repository.getBySession(event.academicSession);
      emit(AcademicYearWizardLoaded(config: config));
    } catch (error) {
      emit(AcademicYearWizardError(_message(error)));
    }
  }

  Future<void> _save(
    SaveAcademicYearConfig event,
    Emitter<AcademicYearWizardState> emit,
  ) async {
    emit(const AcademicYearWizardLoading());
    try {
      await _saveWizard(event.config);
      emit(
        AcademicYearWizardLoaded(
          config: event.config,
          message: 'Academic Year Wizard saved successfully.',
        ),
      );
    } catch (error) {
      emit(AcademicYearWizardError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
