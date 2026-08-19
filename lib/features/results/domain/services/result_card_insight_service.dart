import '../../../exams/domain/entities/exam_result_entity.dart';

class ResultCardInsightService {
  const ResultCardInsightService();

  int punctualityRating(double? attendancePercentage) {
    final value = attendancePercentage;
    if (value == null) return 0;
    if (value >= 95) return 5;
    if (value >= 90) return 4;
    if (value >= 80) return 3;
    if (value >= 70) return 2;
    return 1;
  }

  String subjectGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  String subjectRemark(double percentage) {
    if (percentage >= 90) return 'Outstanding';
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 70) return 'Very Good';
    if (percentage >= 60) return 'Good';
    if (percentage >= 50) return 'Satisfactory';
    return 'Needs Improvement';
  }

  String teacherRemark(ExamResultEntity result) {
    final manual = result.teacherRemarks.trim();
    if (manual.isNotEmpty) return manual;
    if (result.subjectResults.isEmpty) {
      return result.isPassed
          ? '${result.studentName} has made satisfactory progress this term.'
          : '${result.studentName} needs focused support and regular practice.';
    }
    final ordered = [...result.subjectResults]
      ..sort((a, b) {
        final ap = a.totalMarks <= 0 ? 0 : a.obtainedMarks / a.totalMarks;
        final bp = b.totalMarks <= 0 ? 0 : b.obtainedMarks / b.totalMarks;
        return bp.compareTo(ap);
      });
    final strongest = ordered.first.subjectName;
    final weakest = ordered.last.subjectName;
    if (result.percentage >= 90) {
      return '${result.studentName} has demonstrated outstanding progress, with particularly strong performance in $strongest. Keep up the excellent work.';
    }
    if (result.percentage >= 70) {
      return '${result.studentName} has shown very good overall progress. Performance in $strongest is commendable; continued attention to $weakest will support further improvement.';
    }
    if (result.percentage >= 50) {
      return '${result.studentName} has made satisfactory progress. Regular practice, especially in $weakest, is encouraged.';
    }
    return '${result.studentName} needs focused support and consistent practice, particularly in $weakest. With regular effort, improvement is achievable.';
  }
}
