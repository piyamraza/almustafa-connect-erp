import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/additional_charge_entity.dart';
import '../../domain/entities/student_additional_charge_due_entity.dart';
import '../../domain/repositories/additional_charge_repository.dart';
import '../../domain/repositories/student_additional_charge_due_repository.dart';
import '../../domain/services/additional_charge_generation_service.dart';

sealed class AdditionalChargesEvent {
  const AdditionalChargesEvent();
}

class LoadAdditionalCharges extends AdditionalChargesEvent {
  const LoadAdditionalCharges(this.session);
  final String session;
}

class SaveAdditionalCharge extends AdditionalChargesEvent {
  const SaveAdditionalCharge(this.charge);
  final AdditionalChargeEntity charge;
}

class DeleteAdditionalCharge extends AdditionalChargesEvent {
  const DeleteAdditionalCharge(this.charge);
  final AdditionalChargeEntity charge;
}

class GenerateAdditionalCharge extends AdditionalChargesEvent {
  const GenerateAdditionalCharge(this.charge);
  final AdditionalChargeEntity charge;
}

class LoadAdditionalChargeDues extends AdditionalChargesEvent {
  const LoadAdditionalChargeDues(this.charge);
  final AdditionalChargeEntity charge;
}

sealed class AdditionalChargesState {
  const AdditionalChargesState();
}

class AdditionalChargesInitial extends AdditionalChargesState {
  const AdditionalChargesInitial();
}

class AdditionalChargesLoading extends AdditionalChargesState {
  const AdditionalChargesLoading();
}

class AdditionalChargesLoaded extends AdditionalChargesState {
  const AdditionalChargesLoaded({
    required this.charges,
    required this.dues,
    required this.session,
    this.viewingCharge,
    this.message,
    this.generationResult,
  });
  final List<AdditionalChargeEntity> charges;
  final List<StudentAdditionalChargeDueEntity> dues;
  final String session;
  final AdditionalChargeEntity? viewingCharge;
  final String? message;
  final ChargeGenerationResult? generationResult;
}

class AdditionalChargesError extends AdditionalChargesState {
  const AdditionalChargesError(this.message);
  final String message;
}

class AdditionalChargesBloc
    extends Bloc<AdditionalChargesEvent, AdditionalChargesState> {
  AdditionalChargesBloc(this._charges, this._dues, this._generator)
    : super(const AdditionalChargesInitial()) {
    on<LoadAdditionalCharges>(_load);
    on<SaveAdditionalCharge>(_save);
    on<DeleteAdditionalCharge>(_delete);
    on<GenerateAdditionalCharge>(_generate);
    on<LoadAdditionalChargeDues>(_loadDues);
  }
  final AdditionalChargeRepository _charges;
  final StudentAdditionalChargeDueRepository _dues;
  final AdditionalChargeGenerationService _generator;
  String _session = '';

  Future<AdditionalChargesLoaded> _data({
    String? message,
    ChargeGenerationResult? result,
    AdditionalChargeEntity? viewing,
  }) async {
    final charges = await _charges.getCharges(academicSession: _session);
    final dues = await _dues.getDues(
      academicSession: _session,
      chargeId: viewing?.id,
    );
    return AdditionalChargesLoaded(
      charges: charges,
      dues: dues,
      session: _session,
      viewingCharge: viewing,
      message: message,
      generationResult: result,
    );
  }

  Future<void> _load(
    LoadAdditionalCharges e,
    Emitter<AdditionalChargesState> emit,
  ) async {
    emit(const AdditionalChargesLoading());
    try {
      _session = e.session;
      emit(await _data());
    } catch (error) {
      emit(AdditionalChargesError(_message(error)));
    }
  }

  Future<void> _save(
    SaveAdditionalCharge e,
    Emitter<AdditionalChargesState> emit,
  ) async {
    emit(const AdditionalChargesLoading());
    try {
      _session = e.charge.academicSession;
      await _charges.saveCharge(e.charge);
      emit(await _data(message: 'Additional charge saved successfully.'));
    } catch (error) {
      emit(AdditionalChargesError(_message(error)));
    }
  }

  Future<void> _delete(
    DeleteAdditionalCharge e,
    Emitter<AdditionalChargesState> emit,
  ) async {
    emit(const AdditionalChargesLoading());
    try {
      await _charges.deleteCharge(e.charge.id);
      emit(await _data(message: 'Additional charge deleted.'));
    } catch (error) {
      emit(AdditionalChargesError(_message(error)));
    }
  }

  Future<void> _generate(
    GenerateAdditionalCharge e,
    Emitter<AdditionalChargesState> emit,
  ) async {
    emit(const AdditionalChargesLoading());
    try {
      final result = await _generator.generate(e.charge);
      emit(
        await _data(
          message:
              '${result.generatedCount} student dues generated successfully.',
          result: result,
        ),
      );
    } catch (error) {
      emit(AdditionalChargesError(_message(error)));
    }
  }

  Future<void> _loadDues(
    LoadAdditionalChargeDues e,
    Emitter<AdditionalChargesState> emit,
  ) async {
    emit(const AdditionalChargesLoading());
    try {
      emit(await _data(viewing: e.charge));
    } catch (error) {
      emit(AdditionalChargesError(_message(error)));
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('StateError: ', '');
}
