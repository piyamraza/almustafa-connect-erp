import 'dart:math';

import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_question_entity.dart';
import 'package:almustafa_connect_erp/features/exams/domain/services/question_paper_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExamQuestionEntity question(String id, ExamQuestionType type) =>
      ExamQuestionEntity(
        id: id,
        classId: 'c1',
        className: 'Class 1',
        subjectId: 's1',
        subjectName: 'Science',
        type: type,
        text: 'Question $id',
        marks: 1,
        createdAt: DateTime(2026),
      );

  test(
    'generates requested objective and subjective mix without duplicates',
    () {
      final bank = [
        question('m1', ExamQuestionType.multipleChoice),
        question('m2', ExamQuestionType.multipleChoice),
        question('t1', ExamQuestionType.trueFalse),
        question('s1', ExamQuestionType.shortAnswer),
        question('s2', ExamQuestionType.shortAnswer),
        question('l1', ExamQuestionType.longAnswer),
      ];
      final result = QuestionPaperGenerator().generate(
        bank: bank,
        request: const QuestionPaperRequest(
          multipleChoice: 2,
          trueFalse: 1,
          shortAnswer: 1,
          longAnswer: 1,
        ),
        random: Random(1),
      );
      expect(result, hasLength(5));
      expect(result.map((e) => e.id).toSet(), hasLength(5));
      expect(result.where((e) => e.isObjective), hasLength(3));
    },
  );

  test('reports an insufficient question bank', () {
    expect(
      () => QuestionPaperGenerator().generate(
        bank: [question('m1', ExamQuestionType.multipleChoice)],
        request: const QuestionPaperRequest(multipleChoice: 2),
      ),
      throwsStateError,
    );
  });
}
