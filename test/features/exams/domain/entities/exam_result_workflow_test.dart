import 'package:almustafa_connect_erp/features/exams/domain/entities/exam_result_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExamResultEntity workflow', () {
    test('allows the complete forward approval workflow', () {
      expect(
        ExamResultEntity.canTransition(
          current: ResultStatus.generated,
          next: ResultStatus.verified,
        ),
        isTrue,
      );
      expect(
        ExamResultEntity.canTransition(
          current: ResultStatus.verified,
          next: ResultStatus.approved,
        ),
        isTrue,
      );
      expect(
        ExamResultEntity.canTransition(
          current: ResultStatus.approved,
          next: ResultStatus.published,
        ),
        isTrue,
      );
      expect(
        ExamResultEntity.canTransition(
          current: ResultStatus.published,
          next: ResultStatus.locked,
        ),
        isTrue,
      );
    });

    test('allows controlled backward workflow transitions', () {
      const transitions = [
        (ResultStatus.verified, ResultStatus.generated),
        (ResultStatus.approved, ResultStatus.verified),
        (ResultStatus.published, ResultStatus.approved),
        (ResultStatus.published, ResultStatus.unpublished),
        (ResultStatus.locked, ResultStatus.published),
        (ResultStatus.unpublished, ResultStatus.approved),
        (ResultStatus.unpublished, ResultStatus.published),
      ];

      for (final transition in transitions) {
        expect(
          ExamResultEntity.canTransition(
            current: transition.$1,
            next: transition.$2,
          ),
          isTrue,
          reason: '${transition.$1.name} to ${transition.$2.name}',
        );
      }
    });

    test('does not allow locked results to skip controlled unlock', () {
      for (final target in ResultStatus.values) {
        if (target == ResultStatus.locked || target == ResultStatus.published) {
          continue;
        }
        expect(
          ExamResultEntity.canTransition(
            current: ResultStatus.locked,
            next: target,
          ),
          isFalse,
          reason: 'locked to ${target.name}',
        );
      }
    });
  });
}
