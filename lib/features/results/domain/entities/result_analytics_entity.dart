import 'package:equatable/equatable.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';
import '../../../exams/domain/entities/exam_subject_setup_entity.dart';

enum AnalyticsSort { marksDescending, marksAscending, nameAscending, passFirst }

class ResultAnalyticsData extends Equatable {
  const ResultAnalyticsData({
    required this.results,
    required this.subjectSetups,
  });

  final List<ExamResultEntity> results;
  final List<ExamSubjectSetupEntity> subjectSetups;

  @override
  List<Object?> get props => [results, subjectSetups];
}

class ResultAnalyticsFilter extends Equatable {
  const ResultAnalyticsFilter({
    this.academicSession,
    this.examId,
    this.classId,
    this.sectionId,
    this.subjectName,
    this.studentId,
    this.searchQuery = '',
    this.sort = AnalyticsSort.marksDescending,
    this.borderlineMargin = 5,
    this.lowPerformanceThreshold = 40,
  });

  final String? academicSession;
  final String? examId;
  final String? classId;
  final String? sectionId;
  final String? subjectName;
  final String? studentId;
  final String searchQuery;
  final AnalyticsSort sort;
  final double borderlineMargin;
  final double lowPerformanceThreshold;

  ResultAnalyticsFilter copyWith({
    String? academicSession,
    String? examId,
    String? classId,
    String? sectionId,
    String? subjectName,
    String? studentId,
    String? searchQuery,
    AnalyticsSort? sort,
    double? borderlineMargin,
    double? lowPerformanceThreshold,
    bool clearAcademicSession = false,
    bool clearExam = false,
    bool clearClass = false,
    bool clearSection = false,
    bool clearSubject = false,
    bool clearStudent = false,
  }) {
    return ResultAnalyticsFilter(
      academicSession: clearAcademicSession
          ? null
          : academicSession ?? this.academicSession,
      examId: clearExam ? null : examId ?? this.examId,
      classId: clearClass ? null : classId ?? this.classId,
      sectionId: clearSection ? null : sectionId ?? this.sectionId,
      subjectName: clearSubject ? null : subjectName ?? this.subjectName,
      studentId: clearStudent ? null : studentId ?? this.studentId,
      searchQuery: searchQuery ?? this.searchQuery,
      sort: sort ?? this.sort,
      borderlineMargin: borderlineMargin ?? this.borderlineMargin,
      lowPerformanceThreshold:
          lowPerformanceThreshold ?? this.lowPerformanceThreshold,
    );
  }

  @override
  List<Object?> get props => [
    academicSession,
    examId,
    classId,
    sectionId,
    subjectName,
    studentId,
    searchQuery,
    sort,
    borderlineMargin,
    lowPerformanceThreshold,
  ];
}

class ResultChartPoint extends Equatable {
  const ResultChartPoint({required this.label, required this.value});

  final String label;
  final double value;

  @override
  List<Object?> get props => [label, value];
}

class SubjectStudentAnalysisRow extends Equatable {
  const SubjectStudentAnalysisRow({
    required this.result,
    required this.subject,
    this.passingMarks,
  });

  final ExamResultEntity result;
  final SubjectResultEntity subject;
  final double? passingMarks;

  double get percentage => subject.totalMarks == 0
      ? 0
      : (subject.obtainedMarks / subject.totalMarks) * 100;

  @override
  List<Object?> get props => [result, subject, passingMarks];
}

class SubjectAnalyticsSummary extends Equatable {
  const SubjectAnalyticsSummary({
    required this.totalStudents,
    required this.appearedStudents,
    required this.absentStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.passPercentage,
    required this.failPercentage,
    required this.highestMarks,
    required this.lowestMarks,
    required this.averageMarks,
    required this.totalMarks,
    this.passingMarks,
  });

  final int totalStudents;
  final int appearedStudents;
  final int absentStudents;
  final int passedStudents;
  final int failedStudents;
  final double passPercentage;
  final double failPercentage;
  final double highestMarks;
  final double lowestMarks;
  final double averageMarks;
  final double totalMarks;
  final double? passingMarks;

  @override
  List<Object?> get props => [
    totalStudents,
    appearedStudents,
    absentStudents,
    passedStudents,
    failedStudents,
    passPercentage,
    failPercentage,
    highestMarks,
    lowestMarks,
    averageMarks,
    totalMarks,
    passingMarks,
  ];
}

class StudentExamPerformance extends Equatable {
  const StudentExamPerformance({
    required this.examId,
    required this.examName,
    required this.percentage,
    required this.grade,
    required this.position,
    required this.isPassed,
  });

  final String examId;
  final String examName;
  final double percentage;
  final String grade;
  final int position;
  final bool isPassed;

  @override
  List<Object?> get props => [
    examId,
    examName,
    percentage,
    grade,
    position,
    isPassed,
  ];
}

class SubjectPerformanceSummary extends Equatable {
  const SubjectPerformanceSummary({
    required this.subjectName,
    required this.averagePercentage,
    required this.examCount,
  });

  final String subjectName;
  final double averagePercentage;
  final int examCount;

  @override
  List<Object?> get props => [subjectName, averagePercentage, examCount];
}

class StudentPerformanceSummary extends Equatable {
  const StudentPerformanceSummary({
    required this.studentName,
    required this.rollNumber,
    required this.admissionNo,
    required this.examPerformances,
    required this.subjectPerformances,
    required this.averagePercentage,
    required this.passedExams,
    required this.failedExams,
  });

  final String studentName;
  final String rollNumber;
  final String admissionNo;
  final List<StudentExamPerformance> examPerformances;
  final List<SubjectPerformanceSummary> subjectPerformances;
  final double averagePercentage;
  final int passedExams;
  final int failedExams;

  SubjectPerformanceSummary? get strongestSubject =>
      subjectPerformances.isEmpty ? null : subjectPerformances.first;

  SubjectPerformanceSummary? get weakestSubject =>
      subjectPerformances.isEmpty ? null : subjectPerformances.last;

  @override
  List<Object?> get props => [
    studentName,
    rollNumber,
    admissionNo,
    examPerformances,
    subjectPerformances,
    averagePercentage,
    passedExams,
    failedExams,
  ];
}

class PerformanceGroupSummary extends Equatable {
  const PerformanceGroupSummary({
    required this.id,
    required this.name,
    required this.totalStudents,
    required this.passedStudents,
    required this.failedStudents,
    required this.passPercentage,
    required this.averagePercentage,
    required this.highestPercentage,
    required this.lowestPercentage,
    this.topPerformer,
    this.weakestPerformer,
  });

  final String id;
  final String name;
  final int totalStudents;
  final int passedStudents;
  final int failedStudents;
  final double passPercentage;
  final double averagePercentage;
  final double highestPercentage;
  final double lowestPercentage;
  final ExamResultEntity? topPerformer;
  final ExamResultEntity? weakestPerformer;

  @override
  List<Object?> get props => [
    id,
    name,
    totalStudents,
    passedStudents,
    failedStudents,
    passPercentage,
    averagePercentage,
    highestPercentage,
    lowestPercentage,
    topPerformer,
    weakestPerformer,
  ];
}

class StudentRiskSummary extends Equatable {
  const StudentRiskSummary({
    required this.result,
    required this.failedSubjects,
    required this.absentSubjects,
  });

  final ExamResultEntity result;
  final int failedSubjects;
  final int absentSubjects;

  @override
  List<Object?> get props => [result, failedSubjects, absentSubjects];
}

class ResultAnalyticsOverview extends Equatable {
  const ResultAnalyticsOverview({
    required this.totalPublishedResults,
    required this.totalStudentsEvaluated,
    required this.passedResults,
    required this.failedResults,
    required this.passPercentage,
    required this.failPercentage,
    required this.averagePercentage,
    required this.highestPercentage,
    required this.lowestPercentage,
    this.bestClass,
    this.weakestClass,
    this.bestSubject,
    this.weakestSubject,
  });

  final int totalPublishedResults;
  final int totalStudentsEvaluated;
  final int passedResults;
  final int failedResults;
  final double passPercentage;
  final double failPercentage;
  final double averagePercentage;
  final double highestPercentage;
  final double lowestPercentage;
  final PerformanceGroupSummary? bestClass;
  final PerformanceGroupSummary? weakestClass;
  final SubjectPerformanceSummary? bestSubject;
  final SubjectPerformanceSummary? weakestSubject;

  @override
  List<Object?> get props => [
    totalPublishedResults,
    totalStudentsEvaluated,
    passedResults,
    failedResults,
    passPercentage,
    failPercentage,
    averagePercentage,
    highestPercentage,
    lowestPercentage,
    bestClass,
    weakestClass,
    bestSubject,
    weakestSubject,
  ];
}
