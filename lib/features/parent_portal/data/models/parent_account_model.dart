import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/parent_account_entity.dart';

class ParentAccountModel extends ParentAccountEntity {
  ParentAccountModel({
    required super.id,
    required super.fullName,
    required super.mobileNumber,
    required super.email,
    required super.relationship,
    required super.studentIds,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ParentAccountModel.fromEntity(ParentAccountEntity value) {
    return ParentAccountModel(
      id: value.id,
      fullName: value.fullName,
      mobileNumber: value.mobileNumber,
      email: value.email,
      relationship: value.relationship,
      studentIds: value.studentIds,
      isActive: value.isActive,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory ParentAccountModel.fromMap(Map<String, dynamic> map) {
    return ParentAccountModel(
      id: map['id'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Guardian',
      studentIds: (map['studentIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(growable: false),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'mobileNumber': mobileNumber,
    'email': email,
    'relationship': relationship,
    'studentIds': studentIds,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
