import 'package:equatable/equatable.dart';

class ParentAccountEntity extends Equatable {
  ParentAccountEntity({
    required this.id,
    this.userId = '',
    required this.fullName,
    required this.mobileNumber,
    this.whatsappNumber = '',
    required this.email,
    required this.relationship,
    required List<String> studentIds,
    this.branchId = 'main',
    this.accountStatus = accountStatusActive,
    this.isPrimaryContact = false,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelationship = '',
    bool isActive = true,
    required this.createdAt,
    required this.updatedAt,
  }) : studentIds = List<String>.unmodifiable(
         studentIds
             .map((value) => value.trim())
             .where((value) => value.isNotEmpty)
             .toSet()
             .toList(growable: false),
       ),
       isActive = _resolveIsActive(
         accountStatus: accountStatus,
         isActive: isActive,
       );

  static const String accountStatusActive = 'active';
  static const String accountStatusInactive = 'inactive';
  static const String accountStatusBlocked = 'blocked';

  final String id;

  /// Firebase Authentication UID linked with this parent account.
  final String userId;

  final String fullName;
  final String mobileNumber;
  final String whatsappNumber;
  final String email;
  final String relationship;

  final List<String> studentIds;

  final String branchId;

  /// Supported values:
  /// - active
  /// - inactive
  /// - blocked
  final String accountStatus;

  final bool isPrimaryContact;

  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelationship;

  /// Kept for backward compatibility with existing screens and Firestore data.
  final bool isActive;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isBlocked => normalizedAccountStatus == accountStatusBlocked;

  bool get isInactive => normalizedAccountStatus == accountStatusInactive;

  bool get canAccessParentPortal =>
      normalizedAccountStatus == accountStatusActive && isActive;

  String get normalizedAccountStatus {
    return normalizeAccountStatus(
      accountStatus: accountStatus,
      isActive: isActive,
    );
  }

  ParentAccountEntity copyWith({
    String? userId,
    String? fullName,
    String? mobileNumber,
    String? whatsappNumber,
    String? email,
    String? relationship,
    List<String>? studentIds,
    String? branchId,
    String? accountStatus,
    bool? isPrimaryContact,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final resolvedStatus =
        accountStatus ??
        (isActive == null
            ? normalizedAccountStatus
            : isActive
            ? accountStatusActive
            : accountStatusInactive);

    final resolvedIsActive =
        isActive ??
        (accountStatus == null
            ? this.isActive
            : normalizeAccountStatus(
                    accountStatus: accountStatus,
                    isActive: this.isActive,
                  ) ==
                  accountStatusActive);

    return ParentAccountEntity(
      id: id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      studentIds: studentIds ?? this.studentIds,
      branchId: branchId ?? this.branchId,
      accountStatus: resolvedStatus,
      isPrimaryContact: isPrimaryContact ?? this.isPrimaryContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      isActive: resolvedIsActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String normalizeAccountStatus({
    required String accountStatus,
    required bool isActive,
  }) {
    final value = accountStatus.trim().toLowerCase();

    if (value == accountStatusBlocked) {
      return accountStatusBlocked;
    }

    if (value == accountStatusInactive) {
      return accountStatusInactive;
    }

    if (value == accountStatusActive) {
      return isActive ? accountStatusActive : accountStatusInactive;
    }

    return isActive ? accountStatusActive : accountStatusInactive;
  }

  static bool _resolveIsActive({
    required String accountStatus,
    required bool isActive,
  }) {
    return normalizeAccountStatus(
          accountStatus: accountStatus,
          isActive: isActive,
        ) ==
        accountStatusActive;
  }

  @override
  List<Object> get props => [
    id,
    userId,
    fullName,
    mobileNumber,
    whatsappNumber,
    email,
    relationship,
    studentIds,
    branchId,
    normalizedAccountStatus,
    isPrimaryContact,
    emergencyContactName,
    emergencyContactPhone,
    emergencyContactRelationship,
    isActive,
    createdAt,
    updatedAt,
  ];
}
