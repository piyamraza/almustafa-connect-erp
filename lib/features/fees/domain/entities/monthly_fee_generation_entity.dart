import 'package:equatable/equatable.dart';

import 'monthly_fee_due_entity.dart';

enum FeeGenerationScope {
  entireSchool,
  classWise,
  sectionWise,
  selectedStudents,
}

class MonthlyFeeGenerationRequest extends Equatable {
  MonthlyFeeGenerationRequest({
    required this.academicSession,
    required this.month,
    required this.year,
    required this.dueDay,
    required this.scope,
    required List<String> selectedAssignmentIds,
    this.classId,
    this.sectionId,
  }) : selectedAssignmentIds = List<String>.unmodifiable(selectedAssignmentIds);

  final String academicSession;
  final int month;
  final int year;
  final int dueDay;
  final FeeGenerationScope scope;
  final String? classId;
  final String? sectionId;
  final List<String> selectedAssignmentIds;

  @override
  List<Object?> get props => [
    academicSession,
    month,
    year,
    dueDay,
    scope,
    classId,
    sectionId,
    selectedAssignmentIds,
  ];
}

class MonthlyFeeGenerationResult extends Equatable {
  MonthlyFeeGenerationResult({
    required List<MonthlyFeeDueEntity> generatedDues,
    required List<String> skippedStudents,
    required this.totalGross,
    required this.totalDiscounts,
    required this.totalArrears,
    required this.totalAdvanceAdjustment,
    required this.netReceivable,
  }) : generatedDues = List<MonthlyFeeDueEntity>.unmodifiable(generatedDues),
       skippedStudents = List<String>.unmodifiable(skippedStudents);

  final List<MonthlyFeeDueEntity> generatedDues;
  final List<String> skippedStudents;
  final double totalGross;
  final double totalDiscounts;
  final double totalArrears;
  final double totalAdvanceAdjustment;
  final double netReceivable;

  int get generatedCount => generatedDues.length;
  int get skippedCount => skippedStudents.length;

  @override
  List<Object> get props => [
    generatedDues,
    skippedStudents,
    totalGross,
    totalDiscounts,
    totalArrears,
    totalAdvanceAdjustment,
    netReceivable,
  ];
}
