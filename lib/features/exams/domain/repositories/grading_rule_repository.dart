import '../entities/grade_rule_entity.dart';

abstract class GradingRuleRepository {
  Future<List<GradeRuleEntity>> getActiveRules();
}
