import 'package:equatable/equatable.dart';

import 'timetable_configuration_entity.dart';

enum TeacherWorkloadLevel { unassigned, low, balanced, high }

class TeacherWorkloadEntity extends Equatable {
  TeacherWorkloadEntity({
    required this.teacherId,
    required this.employeeId,
    required this.teacherName,
    required this.designation,
    required this.assignedPeriods,
    required this.maxWeeklyPeriods,
    required this.teachingDays,
    required List<String> classSections,
    required List<String> subjects,
    required Map<int, int> assignedPeriodsByDay,
  }) : classSections = List<String>.unmodifiable(classSections),
       subjects = List<String>.unmodifiable(subjects),
       assignedPeriodsByDay = Map<int, int>.unmodifiable(assignedPeriodsByDay);

  final String teacherId;
  final String employeeId;
  final String teacherName;
  final String designation;
  final int assignedPeriods;
  final int maxWeeklyPeriods;
  final int teachingDays;
  final List<String> classSections;
  final List<String> subjects;
  final Map<int, int> assignedPeriodsByDay;

  int get freePeriods {
    final value = maxWeeklyPeriods - assignedPeriods;
    return value < 0 ? 0 : value;
  }

  double get utilization {
    if (maxWeeklyPeriods <= 0) {
      return 0;
    }
    return assignedPeriods / maxWeeklyPeriods;
  }

  TeacherWorkloadLevel get level {
    if (assignedPeriods == 0) {
      return TeacherWorkloadLevel.unassigned;
    }
    if (utilization < 0.45) {
      return TeacherWorkloadLevel.low;
    }
    if (utilization <= 0.80) {
      return TeacherWorkloadLevel.balanced;
    }
    return TeacherWorkloadLevel.high;
  }

  @override
  List<Object> get props => [
    teacherId,
    employeeId,
    teacherName,
    designation,
    assignedPeriods,
    maxWeeklyPeriods,
    teachingDays,
    classSections,
    subjects,
    assignedPeriodsByDay,
  ];
}

class TeacherWorkloadReportEntity extends Equatable {
  TeacherWorkloadReportEntity({
    required this.branchId,
    required this.academicSession,
    required this.configuration,
    required List<TeacherWorkloadEntity> workloads,
  }) : workloads = List<TeacherWorkloadEntity>.unmodifiable(workloads);

  final String branchId;
  final String academicSession;
  final TimetableConfigurationEntity? configuration;
  final List<TeacherWorkloadEntity> workloads;

  int get activeTeacherCount => workloads.length;

  int get totalAssignedPeriods => workloads.fold<int>(
    0,
    (total, workload) => total + workload.assignedPeriods,
  );

  int get highWorkloadCount => workloads
      .where((workload) => workload.level == TeacherWorkloadLevel.high)
      .length;

  int get unassignedTeacherCount => workloads
      .where((workload) => workload.level == TeacherWorkloadLevel.unassigned)
      .length;

  double get averageAssignedPeriods {
    if (workloads.isEmpty) {
      return 0;
    }
    return totalAssignedPeriods / workloads.length;
  }

  @override
  List<Object?> get props => [
    branchId,
    academicSession,
    configuration,
    workloads,
  ];
}
