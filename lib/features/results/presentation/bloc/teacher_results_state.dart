import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../teachers/domain/entities/teacher_assignment_entity.dart';
import '../../../teachers/domain/entities/teacher_entity.dart';
import '../../domain/entities/teacher_subject_result_summary.dart';

sealed class TeacherResultsState extends Equatable {
  const TeacherResultsState();

  @override
  List<Object?> get props => const [];
}

class TeacherResultsInitial extends TeacherResultsState {
  const TeacherResultsInitial();
}

class TeacherResultsLoading extends TeacherResultsState {
  const TeacherResultsLoading();
}

class TeacherResultsFailure extends TeacherResultsState {
  const TeacherResultsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class TeacherResultsLoaded extends TeacherResultsState {
  const TeacherResultsLoaded({
    required this.teachers,
    required this.assignments,
    required this.results,
    this.selectedTeacherId,
    this.selectedAcademicSession,
    this.selectedExamId,
    this.isLoading = false,
  });

  final List<TeacherEntity> teachers;
  final List<TeacherAssignmentEntity> assignments;
  final List<ExamResultEntity> results;
  final String? selectedTeacherId;
  final String? selectedAcademicSession;
  final String? selectedExamId;
  final bool isLoading;

  List<String> get availableSessions {
    final sessions = results
        .map((result) => result.academicSession.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    sessions.sort();
    return sessions.reversed.toList(growable: false);
  }

  List<ExamResultEntity> get availableExams {
    final byId = <String, ExamResultEntity>{};
    for (final result in results.where(
      (item) =>
          selectedAcademicSession == null ||
          item.academicSession == selectedAcademicSession,
    )) {
      byId.putIfAbsent(result.examId, () => result);
    }
    final exams = byId.values.toList(growable: false);
    exams.sort((first, second) => first.examName.compareTo(second.examName));
    return exams;
  }

  List<TeacherEntity> get availableTeachers {
    final assignedIds = assignments.map((item) => item.teacherId).toSet();
    final values = teachers
        .where((teacher) => teacher.isActive && assignedIds.contains(teacher.id))
        .toList(growable: false);
    values.sort((first, second) => first.fullName.compareTo(second.fullName));
    return values;
  }

  TeacherEntity? get selectedTeacher {
    for (final teacher in teachers) {
      if (teacher.id == selectedTeacherId) return teacher;
    }
    return null;
  }

  List<TeacherAssignmentEntity> get selectedAssignments => assignments
      .where(
        (assignment) =>
            assignment.teacherId == selectedTeacherId &&
            (selectedAcademicSession == null ||
                assignment.academicSession == selectedAcademicSession),
      )
      .toList(growable: false);

  List<ExamResultEntity> get filteredResults => results
      .where(
        (result) =>
            (selectedAcademicSession == null ||
                result.academicSession == selectedAcademicSession) &&
            (selectedExamId == null || result.examId == selectedExamId),
      )
      .toList(growable: false);

  TeacherResultsLoaded copyWith({
    List<TeacherEntity>? teachers,
    List<TeacherAssignmentEntity>? assignments,
    List<ExamResultEntity>? results,
    String? selectedTeacherId,
    String? selectedAcademicSession,
    String? selectedExamId,
    bool? isLoading,
    bool clearTeacher = false,
    bool clearSession = false,
    bool clearExam = false,
  }) {
    return TeacherResultsLoaded(
      teachers: teachers ?? this.teachers,
      assignments: assignments ?? this.assignments,
      results: results ?? this.results,
      selectedTeacherId:
          clearTeacher ? null : selectedTeacherId ?? this.selectedTeacherId,
      selectedAcademicSession: clearSession
          ? null
          : selectedAcademicSession ?? this.selectedAcademicSession,
      selectedExamId: clearExam ? null : selectedExamId ?? this.selectedExamId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        teachers,
        assignments,
        results,
        selectedTeacherId,
        selectedAcademicSession,
        selectedExamId,
        isLoading,
      ];
}
