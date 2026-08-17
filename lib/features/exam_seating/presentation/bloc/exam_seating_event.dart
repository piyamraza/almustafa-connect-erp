import 'package:equatable/equatable.dart';

import '../../domain/entities/exam_seating_entities.dart';

sealed class ExamSeatingEvent extends Equatable {
  const ExamSeatingEvent();
  @override
  List<Object?> get props => [];
}

class LoadExamSeating extends ExamSeatingEvent {
  const LoadExamSeating();
}

class SelectSeatingExam extends ExamSeatingEvent {
  const SelectSeatingExam(this.examId);
  final String examId;
  @override
  List<Object> get props => [examId];
}

class SaveExamRoomSetup extends ExamSeatingEvent {
  const SaveExamRoomSetup(this.rooms);
  final List<ExamRoomEntity> rooms;
  @override
  List<Object> get props => [rooms];
}

class GenerateDailyExamPlan extends ExamSeatingEvent {
  const GenerateDailyExamPlan({
    required this.dateSheetId,
    required this.examDate,
    required this.startMinutes,
    required this.endMinutes,
    required this.paperSupportEnabled,
  });
  final String dateSheetId;
  final DateTime examDate;
  final int startMinutes;
  final int endMinutes;
  final bool paperSupportEnabled;
  @override
  List<Object> get props => [
    dateSheetId,
    examDate,
    startMinutes,
    endMinutes,
    paperSupportEnabled,
  ];
}

class FinalizeDailyExamPlan extends ExamSeatingEvent {
  const FinalizeDailyExamPlan(this.plan);
  final DailyExamPlanEntity plan;
  @override
  List<Object> get props => [plan];
}
