import 'package:equatable/equatable.dart';

enum AcademicCalendarConflictSeverity { error, warning, info }

enum AcademicCalendarConflictModule {
  calendar,
  exams,
  timetable,
  homework,
  fees,
  notices,
}

class AcademicCalendarConflictEntity extends Equatable {
  const AcademicCalendarConflictEntity({
    required this.id,
    required this.severity,
    required this.module,
    required this.title,
    required this.description,
    required this.suggestedResolution,
    required this.affectedRecordId,
    required this.affectedDate,
  });

  final String id;
  final AcademicCalendarConflictSeverity severity;
  final AcademicCalendarConflictModule module;
  final String title;
  final String description;
  final String suggestedResolution;
  final String? affectedRecordId;
  final DateTime? affectedDate;

  @override
  List<Object?> get props => [
    id,
    severity,
    module,
    title,
    description,
    suggestedResolution,
    affectedRecordId,
    affectedDate,
  ];
}

class AcademicCalendarValidationResult extends Equatable {
  AcademicCalendarValidationResult({
    required List<AcademicCalendarConflictEntity> conflicts,
    required this.totalChecks,
  }) : conflicts = List<AcademicCalendarConflictEntity>.unmodifiable(conflicts);

  final List<AcademicCalendarConflictEntity> conflicts;
  final int totalChecks;

  int get errorCount => conflicts
      .where((item) => item.severity == AcademicCalendarConflictSeverity.error)
      .length;

  int get warningCount => conflicts
      .where(
        (item) => item.severity == AcademicCalendarConflictSeverity.warning,
      )
      .length;

  int get infoCount => conflicts
      .where((item) => item.severity == AcademicCalendarConflictSeverity.info)
      .length;

  int get healthScore {
    if (totalChecks <= 0) return 100;
    final penalty = (errorCount * 12) + (warningCount * 5) + infoCount;
    final score = 100 - penalty;
    return score.clamp(0, 100);
  }

  bool get hasBlockingErrors => errorCount > 0;

  @override
  List<Object> get props => [conflicts, totalChecks];
}
