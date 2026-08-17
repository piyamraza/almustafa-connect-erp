import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/exam_date_sheet_entity.dart';
import '../../domain/entities/exam_date_sheet_generation_entity.dart';
import '../../domain/entities/exam_entity.dart';
import '../../domain/repositories/exam_date_sheet_repository.dart';
import '../../domain/usecases/generate_exam_date_sheet_options.dart';

sealed class ExamDateSheetGeneratorEvent {
  const ExamDateSheetGeneratorEvent();
}

class GenerateExamDateSheetOptionsEvent extends ExamDateSheetGeneratorEvent {
  const GenerateExamDateSheetOptionsEvent({
    required this.exam,
    required this.request,
  });

  final ExamEntity exam;
  final ExamDateSheetGenerationRequest request;
}

class SaveGeneratedDateSheetOption extends ExamDateSheetGeneratorEvent {
  const SaveGeneratedDateSheetOption({
    required this.exam,
    required this.option,
  });

  final ExamEntity exam;
  final ExamDateSheetGeneratedOption option;
}

sealed class ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorState();
}

class ExamDateSheetGeneratorInitial extends ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorInitial();
}

class ExamDateSheetGeneratorLoading extends ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorLoading();
}

class ExamDateSheetGeneratorLoaded extends ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorLoaded(this.options);

  final List<ExamDateSheetGeneratedOption> options;
}

class ExamDateSheetGeneratorSaved extends ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorSaved(this.dateSheet);

  final ExamDateSheetEntity dateSheet;
}

class ExamDateSheetGeneratorError extends ExamDateSheetGeneratorState {
  const ExamDateSheetGeneratorError(this.message);

  final String message;
}

class ExamDateSheetGeneratorBloc
    extends Bloc<ExamDateSheetGeneratorEvent, ExamDateSheetGeneratorState> {
  ExamDateSheetGeneratorBloc(this._generator, this._repository)
    : super(const ExamDateSheetGeneratorInitial()) {
    on<GenerateExamDateSheetOptionsEvent>(_generate);
    on<SaveGeneratedDateSheetOption>(_save);
  }

  final GenerateExamDateSheetOptions _generator;
  final ExamDateSheetRepository _repository;

  Future<void> _generate(
    GenerateExamDateSheetOptionsEvent event,
    Emitter<ExamDateSheetGeneratorState> emit,
  ) async {
    emit(const ExamDateSheetGeneratorLoading());
    try {
      final options = await _generator(
        exam: event.exam,
        request: event.request,
      );
      emit(ExamDateSheetGeneratorLoaded(options));
    } catch (error) {
      emit(ExamDateSheetGeneratorError(_message(error)));
    }
  }

  Future<void> _save(
    SaveGeneratedDateSheetOption event,
    Emitter<ExamDateSheetGeneratorState> emit,
  ) async {
    emit(const ExamDateSheetGeneratorLoading());
    try {
      final now = DateTime.now();
      final option = event.option;
      final dateSheet = ExamDateSheetEntity(
        id: _repository.generateDateSheetId(),
        examId: event.exam.id,
        examName: event.exam.name,
        academicSession: event.exam.academicSession,
        title: '${event.exam.name} Date Sheet',
        creationMode: ExamDateSheetCreationMode.automatic,
        status: ExamDateSheetStatus.draft,
        papers: option.papers,
        createdAt: now,
        updatedAt: now,
        generatorOptionLabel: option.label,
      );

      await _repository.saveDateSheet(dateSheet);
      emit(ExamDateSheetGeneratorSaved(dateSheet));
    } catch (error) {
      emit(ExamDateSheetGeneratorError(_message(error)));
    }
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('StateError: ', '')
      .replaceFirst('Invalid argument(s): ', '');
}
