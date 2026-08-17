import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_date_sheet_entity.dart';
import '../../../exams/domain/entities/exam_entity.dart';
import '../../domain/entities/exam_seating_entities.dart';

sealed class ExamSeatingState extends Equatable {
  const ExamSeatingState();
  @override
  List<Object?> get props => [];
}

class ExamSeatingInitial extends ExamSeatingState {
  const ExamSeatingInitial();
}

class ExamSeatingLoading extends ExamSeatingState {
  const ExamSeatingLoading();
}

class ExamSeatingError extends ExamSeatingState {
  const ExamSeatingError(this.message);
  final String message;
  @override
  List<Object> get props => [message];
}

class ExamSeatingLoaded extends ExamSeatingState {
  const ExamSeatingLoaded({
    required this.exams,
    required this.dateSheets,
    required this.plans,
    this.selectedExamId,
    this.roomSetup,
    this.preview,
    this.message,
  });
  final List<ExamEntity> exams;
  final List<ExamDateSheetEntity> dateSheets;
  final List<DailyExamPlanEntity> plans;
  final String? selectedExamId;
  final ExamRoomSetupEntity? roomSetup;
  final DailyExamPlanEntity? preview;
  final String? message;
  ExamSeatingLoaded copyWith({
    List<ExamEntity>? exams,
    List<ExamDateSheetEntity>? dateSheets,
    List<DailyExamPlanEntity>? plans,
    String? selectedExamId,
    ExamRoomSetupEntity? roomSetup,
    DailyExamPlanEntity? preview,
    String? message,
    bool clearPreview = false,
  }) => ExamSeatingLoaded(
    exams: exams ?? this.exams,
    dateSheets: dateSheets ?? this.dateSheets,
    plans: plans ?? this.plans,
    selectedExamId: selectedExamId ?? this.selectedExamId,
    roomSetup: roomSetup ?? this.roomSetup,
    preview: clearPreview ? null : preview ?? this.preview,
    message: message,
  );
  @override
  List<Object?> get props => [
    exams,
    dateSheets,
    plans,
    selectedExamId,
    roomSetup,
    preview,
    message,
  ];
}
