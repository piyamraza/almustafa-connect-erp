import 'package:equatable/equatable.dart';

class TeacherPerformanceBand extends Equatable {
  const TeacherPerformanceBand({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}

class TeacherSubjectResultSummary extends Equatable {
  const TeacherSubjectResultSummary({
    required this.subjectName,
    required this.className,
    required this.sectionName,
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.passPercentage,
    required this.performanceBands,
  });

  final String subjectName;
  final String className;
  final String sectionName;
  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final double passPercentage;
  final List<TeacherPerformanceBand> performanceBands;

  double get failPercentage =>
      totalStudents == 0 ? 0 : (failedStudents / totalStudents) * 100;

  @override
  List<Object?> get props => [
        subjectName,
        className,
        sectionName,
        totalStudents,
        passedStudents,
        failedStudents,
        passPercentage,
        performanceBands,
      ];
}
