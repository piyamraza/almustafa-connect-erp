import 'package:almustafa_connect_erp/features/results/domain/services/result_card_insight_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ResultCardInsightService();

  group('ResultCardInsightService', () {
    test('maps punctuality percentage to a five-star rating', () {
      expect(service.punctualityRating(null), 0);
      expect(service.punctualityRating(96), 5);
      expect(service.punctualityRating(92), 4);
      expect(service.punctualityRating(84), 3);
      expect(service.punctualityRating(72), 2);
      expect(service.punctualityRating(60), 1);
    });

    test('generates grade and remark from subject percentage', () {
      expect(service.subjectGrade(95), 'A+');
      expect(service.subjectRemark(95), 'Outstanding');
      expect(service.subjectGrade(84), 'A');
      expect(service.subjectRemark(45), 'Needs Improvement');
    });
  });
}
