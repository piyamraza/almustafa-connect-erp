import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/parent_account_entity.dart';

class ParentAccountModel extends ParentAccountEntity {
  ParentAccountModel({
    required super.id,
    super.userId,
    required super.fullName,
    required super.mobileNumber,
    super.whatsappNumber,
    required super.email,
    required super.relationship,
    required super.studentIds,
    super.branchId,
    super.accountStatus,
    super.isPrimaryContact,
    super.emergencyContactName,
    super.emergencyContactPhone,
    super.emergencyContactRelationship,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ParentAccountModel.fromEntity(ParentAccountEntity value) {
    return ParentAccountModel(
      id: value.id,
      userId: value.userId,
      fullName: value.fullName,
      mobileNumber: value.mobileNumber,
      whatsappNumber: value.whatsappNumber,
      email: value.email,
      relationship: value.relationship,
      studentIds: value.studentIds,
      branchId: value.branchId,
      accountStatus: value.normalizedAccountStatus,
      isPrimaryContact: value.isPrimaryContact,
      emergencyContactName: value.emergencyContactName,
      emergencyContactPhone: value.emergencyContactPhone,
      emergencyContactRelationship: value.emergencyContactRelationship,
      isActive: value.isActive,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
    );
  }

  factory ParentAccountModel.fromMap(Map<String, dynamic> map) {
    final isActive = map['isActive'] as bool? ?? true;

    final accountStatus =
        map['accountStatus'] as String? ??
        (isActive
            ? ParentAccountEntity.accountStatusActive
            : ParentAccountEntity.accountStatusInactive);

    final mobileNumber =
        map['mobileNumber'] as String? ??
        map['phoneNumber'] as String? ??
        map['mobile'] as String? ??
        '';

    return ParentAccountModel(
      id: map['id'] as String? ?? '',
      userId:
          map['userId'] as String? ?? map['firebaseUserId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      mobileNumber: mobileNumber,
      whatsappNumber:
          map['whatsappNumber'] as String? ??
          map['whatsapp'] as String? ??
          mobileNumber,
      email: map['email'] as String? ?? '',
      relationship: map['relationship'] as String? ?? 'Guardian',
      studentIds: (map['studentIds'] as List<dynamic>? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      branchId: map['branchId'] as String? ?? 'main',
      accountStatus: accountStatus,
      isPrimaryContact: map['isPrimaryContact'] as bool? ?? false,
      emergencyContactName: map['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: map['emergencyContactPhone'] as String? ?? '',
      emergencyContactRelationship:
          map['emergencyContactRelationship'] as String? ?? '',
      isActive: isActive,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId.trim(),
      'fullName': fullName.trim(),
      'mobileNumber': mobileNumber.trim(),
      'whatsappNumber': whatsappNumber.trim().isEmpty
          ? mobileNumber.trim()
          : whatsappNumber.trim(),
      'email': email.trim(),
      'relationship': relationship.trim(),
      'studentIds': studentIds,
      'branchId': branchId.trim().isEmpty ? 'main' : branchId.trim(),
      'accountStatus': normalizedAccountStatus,
      'isPrimaryContact': isPrimaryContact,
      'emergencyContactName': emergencyContactName.trim(),
      'emergencyContactPhone': emergencyContactPhone.trim(),
      'emergencyContactRelationship': emergencyContactRelationship.trim(),
      'isActive': canAccessParentPortal,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
