import '../../domain/entities/grade_rule_entity.dart';

class GradeRuleModel extends GradeRuleEntity {
  const GradeRuleModel({
    required super.id,
    required super.grade,
    required super.minimumPercentage,
    required super.maximumPercentage,
    required super.isPassing,
    required super.isActive,
  });

  factory GradeRuleModel.fromMap(Map<String, dynamic> map) {
    return GradeRuleModel(
      id: map['id'] as String? ?? '',
      grade: map['grade'] as String? ?? '',
      minimumPercentage: _number(map['minimumPercentage']),
      maximumPercentage: _number(map['maximumPercentage']),
      isPassing: map['isPassing'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  factory GradeRuleModel.fromEntity(GradeRuleEntity value) {
    return GradeRuleModel(
      id: value.id,
      grade: value.grade,
      minimumPercentage: value.minimumPercentage,
      maximumPercentage: value.maximumPercentage,
      isPassing: value.isPassing,
      isActive: value.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grade': grade,
      'minimumPercentage': minimumPercentage,
      'maximumPercentage': maximumPercentage,
      'isPassing': isPassing,
      'isActive': isActive,
    };
  }

  static double _number(dynamic value) {
    return value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  }
}
