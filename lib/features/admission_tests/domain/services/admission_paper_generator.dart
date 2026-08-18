import 'dart:math';
import '../entities/admission_test_entities.dart';

class AdmissionPaperGenerationException implements Exception {
  const AdmissionPaperGenerationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AdmissionPaperGenerator {
  const AdmissionPaperGenerator();
  AdmissionPaperEntity generate({
    required String id,
    required AdmissionPaperTemplateEntity template,
    required List<AdmissionQuestionEntity> bank,
    required String title,
    String variant = 'A',
    Random? random,
  }) {
    final selected = <AdmissionQuestionEntity>[];
    final source = random ?? Random();
    for (final section in template.sections) {
      final available = bank
          .where(
            (q) =>
                q.classLevel == template.classLevel &&
                q.subject.toLowerCase() == section.subject.toLowerCase(),
          )
          .toList();
      if (available.length < section.questionCount) {
        throw AdmissionPaperGenerationException(
          '${section.subject}: ${section.questionCount} questions required, but only ${available.length} are available.',
        );
      }
      final easyTarget = (section.questionCount * template.easyPercent / 100)
          .round();
      final difficultTarget =
          (section.questionCount * template.difficultPercent / 100).floor();
      final mediumTarget = section.questionCount - easyTarget - difficultTarget;
      final sectionResult = <AdmissionQuestionEntity>[];
      for (final entry in {
        AdmissionQuestionDifficulty.easy: easyTarget,
        AdmissionQuestionDifficulty.medium: mediumTarget,
        AdmissionQuestionDifficulty.difficult: difficultTarget,
      }.entries) {
        final pool =
            available
                .where(
                  (q) =>
                      q.difficulty == entry.key && !sectionResult.contains(q),
                )
                .toList()
              ..shuffle(source);
        sectionResult.addAll(pool.take(entry.value));
      }
      if (sectionResult.length < section.questionCount) {
        final remaining =
            available.where((q) => !sectionResult.contains(q)).toList()
              ..shuffle(source);
        sectionResult.addAll(
          remaining.take(section.questionCount - sectionResult.length),
        );
      }
      selected.addAll(sectionResult);
    }
    return AdmissionPaperEntity(
      id: id,
      title: title,
      classLevel: template.classLevel,
      mode: template.mode,
      durationMinutes: template.durationMinutes,
      passingPercentage: template.passingPercentage,
      questions: List.unmodifiable(selected),
      createdAt: DateTime.now(),
      variant: variant,
    );
  }
}
