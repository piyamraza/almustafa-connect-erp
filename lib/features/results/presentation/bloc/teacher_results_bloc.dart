import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:almustafa_connect_erp/features/academic_structure/domain/services/academic_class_order.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/services/result_subject_grouping_service.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../../teachers/domain/repositories/teacher_assignment_repository.dart';
import '../../../teachers/domain/repositories/teacher_repository.dart';
import '../../domain/entities/teacher_subject_result_summary.dart';
import '../../domain/usecases/get_published_results.dart';
import 'teacher_results_event.dart';
import 'teacher_results_state.dart';

class TeacherResultsBloc
    extends Bloc<TeacherResultsEvent, TeacherResultsState> {
  TeacherResultsBloc({
    required this._teacherRepository,
    required this._assignmentRepository,
    required this._getPublishedResults,
  }) : super(const TeacherResultsInitial()) {
    on<LoadTeacherResults>(_onLoad);
    on<RefreshTeacherResults>(_onRefresh);
    on<SelectTeacherForResults>(_onSelectTeacher);
    on<FilterTeacherResultsBySession>(_onSelectSession);
    on<FilterTeacherResultsByExam>(_onSelectExam);
  }

  final TeacherRepository _teacherRepository;
  final TeacherAssignmentRepository _assignmentRepository;
  final GetPublishedResults _getPublishedResults;

  Future<void> _onLoad(
    LoadTeacherResults event,
    Emitter<TeacherResultsState> emit,
  ) async {
    emit(const TeacherResultsLoading());
    try {
      final data = await _loadData();
      emit(data);
    } catch (error) {
      emit(TeacherResultsFailure(_message(error)));
    }
  }

  Future<void> _onRefresh(
    RefreshTeacherResults event,
    Emitter<TeacherResultsState> emit,
  ) async {
    final current = state;
    if (current is! TeacherResultsLoaded) {
      await _onLoad(const LoadTeacherResults(), emit);
      return;
    }
    emit(current.copyWith(isLoading: true));
    try {
      final data = await _loadData();
      final session =
          data.availableSessions.contains(current.selectedAcademicSession)
          ? current.selectedAcademicSession
          : null;
      final examId =
          data.results.any(
            (result) =>
                (session == null || result.academicSession == session) &&
                result.examId == current.selectedExamId,
          )
          ? current.selectedExamId
          : null;
      final teacherId =
          data.availableTeachers.any(
            (teacher) => teacher.id == current.selectedTeacherId,
          )
          ? current.selectedTeacherId
          : null;
      emit(
        data.copyWith(
          selectedAcademicSession: session,
          selectedExamId: examId,
          selectedTeacherId: teacherId,
        ),
      );
    } catch (error) {
      emit(TeacherResultsFailure(_message(error)));
    }
  }

  void _onSelectTeacher(
    SelectTeacherForResults event,
    Emitter<TeacherResultsState> emit,
  ) {
    final current = state;
    if (current is! TeacherResultsLoaded) return;
    emit(
      current.copyWith(
        selectedTeacherId: event.teacherId,
        clearTeacher: event.teacherId == null,
      ),
    );
  }

  void _onSelectSession(
    FilterTeacherResultsBySession event,
    Emitter<TeacherResultsState> emit,
  ) {
    final current = state;
    if (current is! TeacherResultsLoaded) return;
    emit(
      current.copyWith(
        selectedAcademicSession: event.academicSession,
        clearSession: event.academicSession == null,
        clearExam: true,
      ),
    );
  }

  void _onSelectExam(
    FilterTeacherResultsByExam event,
    Emitter<TeacherResultsState> emit,
  ) {
    final current = state;
    if (current is! TeacherResultsLoaded) return;
    emit(
      current.copyWith(
        selectedExamId: event.examId,
        clearExam: event.examId == null,
      ),
    );
  }

  Future<TeacherResultsLoaded> _loadData() async {
    final values = await Future.wait<Object>([
      _teacherRepository.getTeachers(),
      _assignmentRepository.getAssignments(),
      _getPublishedResults(),
    ]);
    return TeacherResultsLoaded(
      teachers: values[0] as List<TeacherEntity>,
      assignments: values[1] as List<TeacherAssignmentEntity>,
      results: values[2] as List<ExamResultEntity>,
    );
  }

  String _message(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '');
}

List<TeacherSubjectResultSummary> buildTeacherSubjectSummaries(
  TeacherResultsLoaded state,
) {
  final summaries = <TeacherSubjectResultSummary>[];
  final processedAssignments = <String>{};
  for (final assignment in state.selectedAssignments) {
    final subjectName = assignment.subject.trim();
    if (subjectName.isEmpty) continue;
    final assignmentKey = [
      assignment.classId.trim().toLowerCase(),
      assignment.sectionId.trim().toLowerCase(),
      subjectName.toLowerCase(),
    ].join('|');
    if (!processedAssignments.add(assignmentKey)) continue;

    final subjectResults = <_TeacherSubjectMark>[];
    final studentSubjectKeys = <String>{};
    for (final result in state.filteredResults.where(
      (item) => _sameClass(item, assignment) && _sameSection(item, assignment),
    )) {
      for (final subject in ResultSubjectGroupingService.group(
        result.subjectResults,
      ).where((item) => _sameText(item.subjectName, subjectName))) {
        if (!studentSubjectKeys.add('${result.id}|${subject.subjectId}')) {
          continue;
        }
        subjectResults.add(
          _TeacherSubjectMark(
            percentage: subject.totalMarks == 0
                ? 0
                : (subject.obtainedMarks / subject.totalMarks) * 100,
            isPassed: subject.isPassed,
          ),
        );
      }
    }
    if (subjectResults.isEmpty) continue;
    final passed = subjectResults.where((item) => item.isPassed).length;
    final representative = state.filteredResults.firstWhere(
      (item) => _sameClass(item, assignment) && _sameSection(item, assignment),
    );
    summaries.add(
      TeacherSubjectResultSummary(
        subjectName: subjectName,
        className: representative.className,
        sectionName: representative.sectionName,
        totalStudents: subjectResults.length,
        passedStudents: passed,
        failedStudents: subjectResults.length - passed,
        passPercentage: (passed / subjectResults.length) * 100,
        performanceBands: _performanceBands(subjectResults),
      ),
    );
  }
  summaries.sort((first, second) {
    final subject = first.subjectName.compareTo(second.subjectName);
    if (subject != 0) return subject;
    final className = compareAcademicClassNames(
      first.className,
      second.className,
    );
    if (className != 0) return className;
    return first.sectionName.compareTo(second.sectionName);
  });
  return summaries;
}

bool _sameClass(ExamResultEntity result, TeacherAssignmentEntity assignment) =>
    _sameText(result.classId, assignment.classId) ||
    _sameText(result.className, assignment.classId);

bool _sameSection(
  ExamResultEntity result,
  TeacherAssignmentEntity assignment,
) =>
    _sameText(result.sectionId, assignment.sectionId) ||
    _sameText(result.sectionName, assignment.sectionId);

bool _sameText(String first, String second) =>
    first.trim().toLowerCase() == second.trim().toLowerCase();

List<TeacherPerformanceBand> _performanceBands(
  List<_TeacherSubjectMark> marks,
) {
  const ranges = [
    ('90–100%', 90.0, 100.0001),
    ('80–89%', 80.0, 90.0),
    ('70–79%', 70.0, 80.0),
    ('60–69%', 60.0, 70.0),
    ('50–59%', 50.0, 60.0),
    ('40–49%', 40.0, 50.0),
    ('Below 40%', 0.0, 40.0),
  ];
  return ranges
      .map(
        (range) => TeacherPerformanceBand(
          label: range.$1,
          count: marks
              .where(
                (mark) =>
                    mark.percentage >= range.$2 && mark.percentage < range.$3,
              )
              .length,
        ),
      )
      .toList(growable: false);
}

class _TeacherSubjectMark {
  const _TeacherSubjectMark({required this.percentage, required this.isPassed});

  final double percentage;
  final bool isPassed;
}
