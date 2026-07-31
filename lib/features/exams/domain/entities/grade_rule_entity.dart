import 'package:equatable/equatable.dart';

class GradeRuleEntity extends Equatable {
  const GradeRuleEntity({
    required this.id,
    required this.grade,
    required this.minimumPercentage,
    required this.maximumPercentage,
    required this.isPassing,
    required this.isActive,
  });

  final String id;
  final String grade;
  final double minimumPercentage;
  final double maximumPercentage;
  final bool isPassing;
  final bool isActive;

  bool includes(double percentage) {
    return percentage >= minimumPercentage && percentage <= maximumPercentage;
  }

  @override
  List<Object?> get props => [
        id,
        grade,
        minimumPercentage,
        maximumPercentage,
        isPassing,
        isActive,
      ];
}
