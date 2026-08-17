import 'dart:math';

import 'package:almustafa_connect_erp/features/admission_tests/domain/entities/admission_test_entities.dart';
import 'package:almustafa_connect_erp/features/admission_tests/domain/data/default_admission_question_bank.dart';
import 'package:almustafa_connect_erp/features/admission_tests/domain/services/admission_paper_generator.dart';
import 'package:almustafa_connect_erp/features/admission_tests/presentation/bloc/admission_test_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const generator = AdmissionPaperGenerator();
  final template = AdmissionPaperTemplateEntity(
    id: 'class_1',
    classLevel: 'Class 1',
    mode: AdmissionAssessmentMode.written,
    durationMinutes: 60,
    passingPercentage: 50,
    sections: const [
      AdmissionTemplateSection(subject: 'English', questionCount: 5),
    ],
    updatedAt: DateTime(2026),
  );

  test('generates requested class and subject paper', () {
    final paper = generator.generate(
      id: 'paper',
      template: template,
      bank: [
        for (var i = 0; i < 8; i++)
          _question(i, difficulty: AdmissionQuestionDifficulty.values[i % 3]),
        _question(20, classLevel: 'Class 2'),
      ],
      title: 'Admission Test',
      random: Random(1),
    );
    expect(paper.questions, hasLength(5));
    expect(paper.questions.every((q) => q.classLevel == 'Class 1'), isTrue);
    expect(paper.questions.every((q) => q.subject == 'English'), isTrue);
    expect(paper.totalMarks, 5);
  });

  test('reports a clear shortage instead of creating an incomplete paper', () {
    expect(
      () => generator.generate(
        id: 'paper',
        template: template,
        bank: [_question(1)],
        title: 'Admission Test',
      ),
      throwsA(isA<AdmissionPaperGenerationException>()),
    );
  });

  test('default bank covers every Nursery to Class 8 paper template', () {
    final bank = defaultAdmissionQuestionBank();
    expect(bank.length, greaterThanOrEqualTo(300));
    expect(bank.every((question) => question.isDefault), isTrue);
    for (final template in defaultAdmissionTemplates()) {
      final paper = generator.generate(
        id: 'paper_${template.id}',
        template: template,
        bank: bank,
        title: '${template.classLevel} Admission Test',
        random: Random(1),
      );
      final required = template.sections.fold<int>(
        0,
        (sum, section) => sum + section.questionCount,
      );
      expect(
        paper.questions.length,
        required,
        reason: '${template.classLevel} should have a complete default paper',
      );
    }
  });
}

AdmissionQuestionEntity _question(
  int index, {
  String classLevel = 'Class 1',
  AdmissionQuestionDifficulty difficulty = AdmissionQuestionDifficulty.easy,
}) => AdmissionQuestionEntity(
  id: 'q$index',
  classLevel: classLevel,
  subject: 'English',
  type: AdmissionQuestionType.multipleChoice,
  difficulty: difficulty,
  prompt: 'Question $index',
  marks: 1,
  correctAnswer: 'A',
  createdAt: DateTime(2026),
);
