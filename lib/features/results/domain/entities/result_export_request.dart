import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../students/domain/entities/student_entity.dart';

enum ResultExportType {
  reportCard,
  bulkReportCards,
  classSheet,
  sectionSheet,
  meritList,
  gazette,
  subjectAnalysis,
  studentPerformance,
  classPerformance,
  passFail,
  failedStudents,
  topStudents,
  overallStatistics,
}

class ResultExportMetric extends Equatable {
  const ResultExportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  List<Object?> get props => [label, value];
}

/// Immutable view data for a generated file. It contains published results only
/// and is deliberately independent from Firestore write operations.
class ResultExportRequest extends Equatable {
  const ResultExportRequest({
    required this.type,
    required this.title,
    required this.results,
    this.filters = const {},
    this.metrics = const [],
    this.student,
    this.attendancePercentage,
    this.subjectName,
  });

  final ResultExportType type;
  final String title;
  final List<ExamResultEntity> results;
  final Map<String, String> filters;
  final List<ResultExportMetric> metrics;
  final StudentEntity? student;
  final double? attendancePercentage;
  final String? subjectName;

  bool get isIndividualReportCard => type == ResultExportType.reportCard;

  bool get isBulkReportCard => type == ResultExportType.bulkReportCards;

  bool get isPortrait =>
      type == ResultExportType.reportCard ||
      type == ResultExportType.bulkReportCards ||
      type == ResultExportType.studentPerformance;

  @override
  List<Object?> get props => [
    type,
    title,
    results,
    filters,
    metrics,
    student,
    attendancePercentage,
    subjectName,
  ];
}
