import 'package:equatable/equatable.dart';

enum ExamQuestionType {
  fillInTheBlanks,
  multipleChoice,
  matchColumns,
  trueFalse,
  completeSpelling,
  arrangeCorrectOrder,
  labelDiagram,
  oddOneOut,
  missingLetter,
  shortAnswer,
  longAnswer,
}

extension ExamQuestionTypeInfo on ExamQuestionType {
  String get label => switch (this) {
    ExamQuestionType.fillInTheBlanks => 'Fill in the Blanks',
    ExamQuestionType.multipleChoice => 'Multiple Choice',
    ExamQuestionType.matchColumns => 'Match Columns',
    ExamQuestionType.trueFalse => 'Right / Wrong',
    ExamQuestionType.completeSpelling => 'Complete Spelling',
    ExamQuestionType.arrangeCorrectOrder => 'Arrange in Correct Order',
    ExamQuestionType.labelDiagram => 'Label Diagram / Image',
    ExamQuestionType.oddOneOut => 'Odd One Out',
    ExamQuestionType.missingLetter => 'Missing Letter',
    ExamQuestionType.shortAnswer => 'Short Questions',
    ExamQuestionType.longAnswer => 'Long Questions',
  };

  bool get isObjective => index <= ExamQuestionType.missingLetter.index;

  String get promptLabel => switch (this) {
    ExamQuestionType.fillInTheBlanks => 'Sentence with blank',
    ExamQuestionType.multipleChoice => 'Question',
    ExamQuestionType.matchColumns => 'Column A',
    ExamQuestionType.trueFalse => 'Statement',
    ExamQuestionType.completeSpelling => 'Incomplete word',
    ExamQuestionType.arrangeCorrectOrder => 'Shuffled words / items',
    ExamQuestionType.labelDiagram => 'Diagram instruction',
    ExamQuestionType.oddOneOut => 'Question / instruction',
    ExamQuestionType.missingLetter => 'Incomplete word',
    ExamQuestionType.shortAnswer || ExamQuestionType.longAnswer => 'Question',
  };
}

enum PaperSectionStatus { pending, draft, complete }

extension PaperSectionStatusInfo on PaperSectionStatus {
  String get label => switch (this) {
    PaperSectionStatus.pending => 'Pending',
    PaperSectionStatus.draft => 'Draft',
    PaperSectionStatus.complete => 'Complete',
  };
}

class SubjectPaperProgress extends Equatable {
  const SubjectPaperProgress({
    required this.classId,
    required this.subjectId,
    this.componentId = '',
    this.objectiveStatus = PaperSectionStatus.pending,
    this.subjectiveStatus = PaperSectionStatus.pending,
    this.objectiveCount = 0,
    this.subjectiveCount = 0,
    this.objectiveMarks = 0,
    this.subjectiveMarks = 0,
  });

  final String classId, subjectId, componentId;
  final PaperSectionStatus objectiveStatus, subjectiveStatus;
  final int objectiveCount, subjectiveCount;
  final double objectiveMarks, subjectiveMarks;
  String get key => componentId.isEmpty
      ? '${classId}_$subjectId'
      : '${classId}_${subjectId}_$componentId';
  bool get isComplete =>
      objectiveStatus == PaperSectionStatus.complete &&
      subjectiveStatus == PaperSectionStatus.complete;

  @override
  List<Object?> get props => [
    classId,
    subjectId,
    componentId,
    objectiveStatus,
    subjectiveStatus,
    objectiveCount,
    subjectiveCount,
    objectiveMarks,
    subjectiveMarks,
  ];
}

class ExamQuestionEntity extends Equatable {
  const ExamQuestionEntity({
    required this.id,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.type,
    required this.text,
    required this.marks,
    required this.createdAt,
    this.cells = const [],
    this.chapter = '',
    this.imageUrl = '',
    this.answerLines = 0,
    this.componentId = '',
    this.componentName = '',
  });

  final String id,
      classId,
      className,
      subjectId,
      subjectName,
      componentId,
      componentName,
      text,
      chapter,
      imageUrl;
  final ExamQuestionType type;
  final double marks;
  final List<String> cells;
  final int answerLines;
  final DateTime createdAt;
  bool get isObjective => type.isObjective;

  @override
  List<Object?> get props => [
    id,
    classId,
    subjectId,
    componentId,
    type,
    text,
    marks,
    cells,
    chapter,
    imageUrl,
    answerLines,
    createdAt,
  ];
}

class ExamQuestionPaperEntity extends Equatable {
  const ExamQuestionPaperEntity({
    required this.id,
    required this.title,
    required this.schoolName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.durationMinutes,
    required this.questions,
    required this.createdAt,
    this.instructions = '',
    this.componentId = '',
    this.componentName = '',
    this.logoUrl = '',
    this.passingMarks = 0,
  });
  final String id,
      title,
      schoolName,
      classId,
      className,
      subjectId,
      subjectName,
      componentId,
      componentName,
      logoUrl,
      instructions;
  final int durationMinutes;
  final double passingMarks;
  final List<ExamQuestionEntity> questions;
  final DateTime createdAt;
  double get totalMarks =>
      questions.fold(0, (sum, question) => sum + question.marks);
  @override
  List<Object?> get props => [
    id,
    title,
    classId,
    subjectId,
    componentId,
    passingMarks,
    durationMinutes,
    questions,
    createdAt,
  ];
}
