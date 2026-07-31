import '../../domain/entities/grade_rule_entity.dart';
import '../../domain/repositories/grading_rule_repository.dart';
import '../datasources/grading_rule_remote_datasource.dart';

class GradingRuleRepositoryImpl implements GradingRuleRepository {
  GradingRuleRepositoryImpl({required GradingRuleRemoteDataSource source})
      : _source = source;

  final GradingRuleRemoteDataSource _source;

  @override
  Future<List<GradeRuleEntity>> getActiveRules() => _source.getActiveRules();
}
