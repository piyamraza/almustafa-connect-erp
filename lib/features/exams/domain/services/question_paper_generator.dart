import 'dart:math';

import '../entities/exam_question_entity.dart';

class QuestionPaperRequest {
  const QuestionPaperRequest({
    this.multipleChoice = 0,
    this.trueFalse = 0,
    this.shortAnswer = 0,
    this.longAnswer = 0,
  });
  final int multipleChoice, trueFalse, shortAnswer, longAnswer;
  int countFor(ExamQuestionType type) => switch (type) {
    ExamQuestionType.multipleChoice => multipleChoice,
    ExamQuestionType.trueFalse => trueFalse,
    ExamQuestionType.shortAnswer => shortAnswer,
    ExamQuestionType.longAnswer => longAnswer,
    _ => 0,
  };
}

class QuestionPaperGenerator {
  List<ExamQuestionEntity> generate({
    required List<ExamQuestionEntity> bank,
    required QuestionPaperRequest request,
    Random? random,
  }) {
    final result = <ExamQuestionEntity>[];
    final source = random ?? Random();
    for (final type in ExamQuestionType.values) {
      final available = bank.where((question) => question.type == type).toList()
        ..shuffle(source);
      final requested = request.countFor(type);
      if (available.length < requested) {
        throw StateError(
          'Only ${available.length} ${type.label} questions are available; $requested requested.',
        );
      }
      result.addAll(available.take(requested));
    }
    return result;
  }
}
