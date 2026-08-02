import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/additional_charge_entity.dart';

class AdditionalChargeModel extends AdditionalChargeEntity {
  const AdditionalChargeModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.customCategoryName,
    required super.academicSession,
    required super.amount,
    required super.scope,
    required super.classId,
    required super.className,
    required super.sectionId,
    required super.sectionName,
    required super.selectedStudentIds,
    required super.excludedStudentIds,
    required super.dueDate,
    required super.frequency,
    required super.mandatory,
    required super.refundable,
    required super.isActive,
    required super.generated,
    required super.generatedStudentCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory AdditionalChargeModel.fromEntity(AdditionalChargeEntity e) =>
      AdditionalChargeModel(
        id: e.id,
        title: e.title,
        description: e.description,
        category: e.category,
        customCategoryName: e.customCategoryName,
        academicSession: e.academicSession,
        amount: e.amount,
        scope: e.scope,
        classId: e.classId,
        className: e.className,
        sectionId: e.sectionId,
        sectionName: e.sectionName,
        selectedStudentIds: e.selectedStudentIds,
        excludedStudentIds: e.excludedStudentIds,
        dueDate: e.dueDate,
        frequency: e.frequency,
        mandatory: e.mandatory,
        refundable: e.refundable,
        isActive: e.isActive,
        generated: e.generated,
        generatedStudentCount: e.generatedStudentCount,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  factory AdditionalChargeModel.fromMap(Map<String, dynamic> map) =>
      AdditionalChargeModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        category: _enum(
          AdditionalChargeCategory.values,
          map['category'],
          AdditionalChargeCategory.other,
        ),
        customCategoryName: map['customCategoryName'] as String? ?? '',
        academicSession: map['academicSession'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        scope: _enum(
          AdditionalChargeScope.values,
          map['scope'],
          AdditionalChargeScope.entireSchool,
        ),
        classId: map['classId'] as String? ?? '',
        className: map['className'] as String? ?? '',
        sectionId: map['sectionId'] as String? ?? '',
        sectionName: map['sectionName'] as String? ?? '',
        selectedStudentIds: List<String>.from(
          map['selectedStudentIds'] as List? ?? const [],
        ),
        excludedStudentIds: List<String>.from(
          map['excludedStudentIds'] as List? ?? const [],
        ),
        dueDate: _date(map['dueDate']),
        frequency: _enum(
          AdditionalChargeFrequency.values,
          map['frequency'],
          AdditionalChargeFrequency.oneTime,
        ),
        mandatory: map['mandatory'] as bool? ?? true,
        refundable: map['refundable'] as bool? ?? false,
        isActive: map['isActive'] as bool? ?? true,
        generated: map['generated'] as bool? ?? false,
        generatedStudentCount:
            (map['generatedStudentCount'] as num?)?.toInt() ?? 0,
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
      );

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'category': category.name,
    'customCategoryName': customCategoryName,
    'academicSession': academicSession,
    'amount': amount,
    'scope': scope.name,
    'classId': classId,
    'className': className,
    'sectionId': sectionId,
    'sectionName': sectionName,
    'selectedStudentIds': selectedStudentIds,
    'excludedStudentIds': excludedStudentIds,
    'dueDate': Timestamp.fromDate(dueDate),
    'frequency': frequency.name,
    'mandatory': mandatory,
    'refundable': refundable,
    'isActive': isActive,
    'generated': generated,
    'generatedStudentCount': generatedStudentCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static T _enum<T extends Enum>(List<T> values, dynamic raw, T fallback) =>
      values.where((e) => e.name == raw).firstOrNull ?? fallback;
  static DateTime _date(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : DateTime.now();
}
