import 'package:equatable/equatable.dart';

enum AdditionalChargeCategory {
  paperMoney,
  trip,
  exam,
  annualFunction,
  sportsDay,
  diary,
  idCard,
  uniform,
  penalty,
  other,
}

enum AdditionalChargeScope {
  entireSchool,
  classWise,
  sectionWise,
  selectedStudents,
}

enum AdditionalChargeFrequency { oneTime, monthly, quarterly, annual, custom }

class AdditionalChargeEntity extends Equatable {
  const AdditionalChargeEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.customCategoryName,
    required this.academicSession,
    required this.amount,
    required this.scope,
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.selectedStudentIds,
    required this.excludedStudentIds,
    required this.dueDate,
    required this.frequency,
    required this.mandatory,
    required this.refundable,
    required this.isActive,
    required this.generated,
    required this.generatedStudentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id, title, description, customCategoryName, academicSession;
  final String classId, className, sectionId, sectionName;
  final AdditionalChargeCategory category;
  final AdditionalChargeScope scope;
  final AdditionalChargeFrequency frequency;
  final double amount;
  final List<String> selectedStudentIds, excludedStudentIds;
  final DateTime dueDate, createdAt, updatedAt;
  final bool mandatory, refundable, isActive, generated;
  final int generatedStudentCount;

  String get categoryLabel =>
      category == AdditionalChargeCategory.other &&
          customCategoryName.trim().isNotEmpty
      ? customCategoryName.trim()
      : _words(category.name);
  String get scopeLabel => _words(scope.name);

  static String _words(String value) => value
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .trim()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  @override
  List<Object> get props => [
    id,
    title,
    description,
    category,
    customCategoryName,
    academicSession,
    amount,
    scope,
    classId,
    className,
    sectionId,
    sectionName,
    selectedStudentIds,
    excludedStudentIds,
    dueDate,
    frequency,
    mandatory,
    refundable,
    isActive,
    generated,
    generatedStudentCount,
    createdAt,
    updatedAt,
  ];
}
