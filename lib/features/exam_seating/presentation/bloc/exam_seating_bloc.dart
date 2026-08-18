import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../exams/domain/repositories/exam_date_sheet_repository.dart';
import '../../../exams/domain/repositories/exam_repository.dart';
import '../../../students/domain/repositories/student_repository.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/exam_seating_entities.dart';
import '../../domain/repositories/exam_seating_repository.dart';
import '../../domain/services/exam_plan_generator.dart';
import 'exam_seating_event.dart';
import 'exam_seating_state.dart';

class ExamSeatingBloc extends Bloc<ExamSeatingEvent, ExamSeatingState> {
  ExamSeatingBloc({
    required this._repository,
    required this._examRepository,
    required this._dateSheetRepository,
    required this._studentRepository,
    required this._teacherRepository,
    required this._generator,
  }) : super(const ExamSeatingInitial()) {
    on<LoadExamSeating>(_load);
    on<SelectSeatingExam>(_select);
    on<SaveExamRoomSetup>(_saveRooms);
    on<GenerateDailyExamPlan>(_generate);
    on<FinalizeDailyExamPlan>(_finalize);
  }
  final ExamSeatingRepository _repository;
  final ExamRepository _examRepository;
  final ExamDateSheetRepository _dateSheetRepository;
  final StudentRepository _studentRepository;
  final TeacherRepository _teacherRepository;
  final ExamPlanGenerator _generator;

  Future<void> _load(
    LoadExamSeating event,
    Emitter<ExamSeatingState> emit,
  ) async {
    emit(const ExamSeatingLoading());
    try {
      final exams = await _examRepository.getExams();
      final sheets = await _dateSheetRepository.getDateSheets();
      final plans = await _repository.getPlans();
      emit(ExamSeatingLoaded(exams: exams, dateSheets: sheets, plans: plans));
    } catch (error) {
      emit(ExamSeatingError('Could not load seating plans: $error'));
    }
  }

  Future<void> _select(
    SelectSeatingExam event,
    Emitter<ExamSeatingState> emit,
  ) async {
    final current = state;
    if (current is! ExamSeatingLoaded) return;
    try {
      final setup = await _repository.getRoomSetup(event.examId);
      emit(
        ExamSeatingLoaded(
          exams: current.exams,
          dateSheets: current.dateSheets,
          plans: current.plans,
          selectedExamId: event.examId,
          roomSetup: setup,
        ),
      );
    } catch (error) {
      emit(ExamSeatingError('Could not load room setup: $error'));
    }
  }

  Future<void> _saveRooms(
    SaveExamRoomSetup event,
    Emitter<ExamSeatingState> emit,
  ) async {
    final current = state;
    if (current is! ExamSeatingLoaded || current.selectedExamId == null) return;
    final exam = current.exams
        .where((value) => value.id == current.selectedExamId)
        .firstOrNull;
    if (exam == null) return;
    try {
      final setup = ExamRoomSetupEntity(
        examId: exam.id,
        examName: exam.name,
        rooms: List.unmodifiable(event.rooms),
        updatedAt: DateTime.now(),
      );
      await _repository.saveRoomSetup(setup);
      emit(
        current.copyWith(
          roomSetup: setup,
          message: 'Exam room setup saved.',
          clearPreview: true,
        ),
      );
    } catch (error) {
      emit(ExamSeatingError('Could not save room setup: $error'));
    }
  }

  Future<void> _generate(
    GenerateDailyExamPlan event,
    Emitter<ExamSeatingState> emit,
  ) async {
    final current = state;
    if (current is! ExamSeatingLoaded ||
        current.selectedExamId == null ||
        current.roomSetup == null) {
      return;
    }
    try {
      final exam = current.exams.firstWhere(
        (value) => value.id == current.selectedExamId,
      );
      final sheet = current.dateSheets.firstWhere(
        (value) => value.id == event.dateSheetId,
      );
      final papers = sheet.papers
          .where(
            (paper) =>
                _sameDay(paper.examDate, event.examDate) &&
                paper.startMinutes == event.startMinutes &&
                paper.endMinutes == event.endMinutes,
          )
          .toList();
      final students = (await _studentRepository.getStudents())
          .where(
            (student) =>
                student.isActive &&
                papers.any(
                  (paper) =>
                      _academicReferenceMatches(
                        student.classId,
                        paper.classId,
                        paper.className,
                        prefix: 'class',
                      ) &&
                      _academicReferenceMatches(
                        student.sectionId,
                        paper.sectionId,
                        paper.sectionName,
                        prefix: 'section',
                      ),
                ),
          )
          .toList();
      final teachers = await _teacherRepository.getTeachers();
      final plan = _generator.generate(
        planId: _repository.generatePlanId(),
        examId: exam.id,
        examName: exam.name,
        dateSheetId: sheet.id,
        examDate: event.examDate,
        startMinutes: event.startMinutes,
        endMinutes: event.endMinutes,
        sessionPapers: papers,
        examDates: sheet.papers.map((paper) => paper.examDate).toList(),
        rooms: current.roomSetup!.rooms,
        students: students,
        teachers: teachers,
        history: current.plans.where((plan) => plan.examId == exam.id).toList(),
        paperSupportEnabled: event.paperSupportEnabled,
      );
      emit(
        current.copyWith(
          preview: plan,
          message: 'Draft plan generated. Review it before finalizing.',
        ),
      );
    } on ExamPlanGenerationException catch (error) {
      emit(current.copyWith(message: error.message));
    } catch (error) {
      emit(ExamSeatingError('Could not generate plan: $error'));
    }
  }

  Future<void> _finalize(
    FinalizeDailyExamPlan event,
    Emitter<ExamSeatingState> emit,
  ) async {
    final current = state;
    if (current is! ExamSeatingLoaded) return;
    try {
      final value = DailyExamPlanEntity(
        id: event.plan.id,
        examId: event.plan.examId,
        examName: event.plan.examName,
        dateSheetId: event.plan.dateSheetId,
        examDate: event.plan.examDate,
        startMinutes: event.plan.startMinutes,
        endMinutes: event.plan.endMinutes,
        rooms: event.plan.rooms,
        studentAssignments: event.plan.studentAssignments,
        teacherAssignments: event.plan.teacherAssignments,
        status: ExamPlanStatus.finalized,
        paperSupportEnabled: event.plan.paperSupportEnabled,
        createdAt: event.plan.createdAt,
        updatedAt: DateTime.now(),
      );
      await _repository.savePlan(value);
      final plans = [
        value,
        ...current.plans.where((plan) => plan.id != value.id),
      ];
      emit(
        current.copyWith(
          plans: plans,
          preview: value,
          message: 'Seating and teacher duty plan finalized.',
        ),
      );
    } catch (error) {
      emit(ExamSeatingError('Could not finalize plan: $error'));
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _academicReferenceMatches(
    String studentReference,
    String paperId,
    String paperName, {
    required String prefix,
  }) {
    final studentValue = _academicToken(studentReference, prefix);
    return studentValue == _academicToken(paperId, prefix) ||
        studentValue == _academicToken(paperName, prefix);
  }

  String _academicToken(String value, String prefix) {
    var token = value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    final label = '$prefix ';
    if (token.startsWith(label)) token = token.substring(label.length).trim();
    return token;
  }
}
