import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/firebase_firestore_service.dart';
import '../models/grade_rule_model.dart';

abstract class GradingRuleRemoteDataSource {
  Future<List<GradeRuleModel>> getActiveRules();
}

class GradingRuleRemoteDataSourceImpl implements GradingRuleRemoteDataSource {
  GradingRuleRemoteDataSourceImpl({
    required FirebaseFirestoreService firestoreService,
  }) : _service = firestoreService;

  final FirebaseFirestoreService _service;

  @override
  Future<List<GradeRuleModel>> getActiveRules() async {
    final snapshot = await _service.collection(FirestorePaths.gradingRules).get();
    final rules = snapshot.docs
        .map(
          (document) => GradeRuleModel.fromMap({
            ...document.data(),
            'id': document.id,
          }),
        )
        .where((rule) => rule.isActive)
        .toList(growable: false);
    return snapshot.docs.isEmpty ? _defaultRules : rules;
  }

  static const List<GradeRuleModel> _defaultRules = [
    GradeRuleModel(id: 'a_plus', grade: 'A+', minimumPercentage: 90, maximumPercentage: 100, isPassing: true, isActive: true),
    GradeRuleModel(id: 'a', grade: 'A', minimumPercentage: 80, maximumPercentage: 89.999, isPassing: true, isActive: true),
    GradeRuleModel(id: 'b', grade: 'B', minimumPercentage: 70, maximumPercentage: 79.999, isPassing: true, isActive: true),
    GradeRuleModel(id: 'c', grade: 'C', minimumPercentage: 60, maximumPercentage: 69.999, isPassing: true, isActive: true),
    GradeRuleModel(id: 'd', grade: 'D', minimumPercentage: 50, maximumPercentage: 59.999, isPassing: true, isActive: true),
    GradeRuleModel(id: 'e', grade: 'E', minimumPercentage: 40, maximumPercentage: 49.999, isPassing: true, isActive: true),
    GradeRuleModel(id: 'f', grade: 'F', minimumPercentage: 0, maximumPercentage: 39.999, isPassing: false, isActive: true),
  ];
}
