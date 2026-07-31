import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/section_entity.dart';

class SectionModel extends SectionEntity {
  const SectionModel({
    required super.id,
    required super.classId,
    required super.name,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  String get classSectionKey => '${classId}_${name.trim().toLowerCase()}';

  factory SectionModel.fromEntity(SectionEntity value) => SectionModel(
        id: value.id,
        classId: value.classId,
        name: value.name,
        isActive: value.isActive,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
      );

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return SectionModel(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      name: map['name'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: _date(map['createdAt']) ?? now,
      updatedAt: _date(map['updatedAt']) ?? now,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'classId': classId,
        'name': name,
        'nameKey': name.trim().toLowerCase(),
        'classSectionKey': classSectionKey,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static DateTime? _date(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is String
          ? DateTime.tryParse(value)
          : value is DateTime
              ? value
              : null;
}
