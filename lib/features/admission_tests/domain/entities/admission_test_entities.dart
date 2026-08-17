import 'package:equatable/equatable.dart';

enum AdmissionQuestionDifficulty { easy, medium, difficult }

enum AdmissionQuestionType {
  multipleChoice,
  fillBlank,
  trueFalse,
  shortAnswer,
  oral,
  observation,
}

enum AdmissionAssessmentMode { written, earlyYears }

enum AdmissionRecommendation {
  pending,
  recommended,
  recommendedWithSupport,
  retestRequired,
  notRecommended,
  pendingInterview,
}

extension AdmissionLabel on Enum {
  String get label => name
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class AdmissionQuestionEntity extends Equatable {
  const AdmissionQuestionEntity({
    required this.id,
    required this.classLevel,
    required this.subject,
    required this.type,
    required this.difficulty,
    required this.prompt,
    required this.marks,
    required this.correctAnswer,
    required this.createdAt,
    this.options = const [],
    this.isDefault = false,
  });
  final String id, classLevel, subject, prompt, correctAnswer;
  final AdmissionQuestionType type;
  final AdmissionQuestionDifficulty difficulty;
  final double marks;
  final List<String> options;
  final DateTime createdAt;
  final bool isDefault;
  @override
  List<Object> get props => [
    id,
    classLevel,
    subject,
    type,
    difficulty,
    prompt,
    marks,
    correctAnswer,
    options,
    createdAt,
    isDefault,
  ];
}

class AdmissionTemplateSection extends Equatable {
  const AdmissionTemplateSection({
    required this.subject,
    required this.questionCount,
  });
  final String subject;
  final int questionCount;
  @override
  List<Object> get props => [subject, questionCount];
}

class AdmissionPaperTemplateEntity extends Equatable {
  const AdmissionPaperTemplateEntity({
    required this.id,
    required this.classLevel,
    required this.mode,
    required this.durationMinutes,
    required this.passingPercentage,
    required this.sections,
    required this.updatedAt,
    this.easyPercent = 40,
    this.mediumPercent = 40,
    this.difficultPercent = 20,
  });
  final String id, classLevel;
  final AdmissionAssessmentMode mode;
  final int durationMinutes;
  final double passingPercentage;
  final List<AdmissionTemplateSection> sections;
  final int easyPercent, mediumPercent, difficultPercent;
  final DateTime updatedAt;
  @override
  List<Object> get props => [
    id,
    classLevel,
    mode,
    durationMinutes,
    passingPercentage,
    sections,
    easyPercent,
    mediumPercent,
    difficultPercent,
    updatedAt,
  ];
}

class AdmissionPaperEntity extends Equatable {
  const AdmissionPaperEntity({
    required this.id,
    required this.title,
    required this.classLevel,
    required this.mode,
    required this.durationMinutes,
    required this.passingPercentage,
    required this.questions,
    required this.createdAt,
    this.variant = 'A',
  });
  final String id, title, classLevel, variant;
  final AdmissionAssessmentMode mode;
  final int durationMinutes;
  final double passingPercentage;
  final List<AdmissionQuestionEntity> questions;
  final DateTime createdAt;
  double get totalMarks => questions.fold(0, (sum, item) => sum + item.marks);
  @override
  List<Object> get props => [
    id,
    title,
    classLevel,
    variant,
    mode,
    durationMinutes,
    passingPercentage,
    questions,
    createdAt,
  ];
}

class AdmissionCandidateEntity extends Equatable {
  const AdmissionCandidateEntity({
    required this.id,
    required this.applicantNumber,
    required this.studentName,
    required this.guardianName,
    required this.guardianPhone,
    required this.applyingClass,
    required this.testDate,
    required this.paperId,
    required this.paperTitle,
    required this.obtainedMarks,
    required this.totalMarks,
    required this.observations,
    required this.recommendation,
    required this.remarks,
    required this.updatedAt,
  });
  final String id,
      applicantNumber,
      studentName,
      guardianName,
      guardianPhone,
      applyingClass,
      paperId,
      paperTitle,
      remarks;
  final DateTime testDate, updatedAt;
  final double obtainedMarks, totalMarks;
  final Map<String, String> observations;
  final AdmissionRecommendation recommendation;
  double get percentage =>
      totalMarks <= 0 ? 0 : obtainedMarks / totalMarks * 100;
  @override
  List<Object> get props => [
    id,
    applicantNumber,
    studentName,
    guardianName,
    guardianPhone,
    applyingClass,
    testDate,
    paperId,
    paperTitle,
    obtainedMarks,
    totalMarks,
    observations,
    recommendation,
    remarks,
    updatedAt,
  ];
}
