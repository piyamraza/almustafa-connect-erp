import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_preferences_entity.dart';

class UserPreferencesModel extends UserPreferencesEntity {
  const UserPreferencesModel({
    required super.id,
    required super.userId,
    required super.theme,
    required super.defaultLandingPage,
    required super.rememberLastScreen,
    required super.pushNotifications,
    required super.homeworkNotifications,
    required super.attendanceNotifications,
    required super.feeNotifications,
    required super.examNotifications,
    required super.paperSize,
    required super.receiptFormat,
    required super.resultCardFormat,
    required super.language,
    required super.updatedAt,
  });

  factory UserPreferencesModel.fromEntity(UserPreferencesEntity entity) {
    return UserPreferencesModel(
      id: entity.id,
      userId: entity.userId,
      theme: entity.theme,
      defaultLandingPage: entity.defaultLandingPage,
      rememberLastScreen: entity.rememberLastScreen,
      pushNotifications: entity.pushNotifications,
      homeworkNotifications: entity.homeworkNotifications,
      attendanceNotifications: entity.attendanceNotifications,
      feeNotifications: entity.feeNotifications,
      examNotifications: entity.examNotifications,
      paperSize: entity.paperSize,
      receiptFormat: entity.receiptFormat,
      resultCardFormat: entity.resultCardFormat,
      language: entity.language,
      updatedAt: entity.updatedAt,
    );
  }

  factory UserPreferencesModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return UserPreferencesModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      theme: AppThemePreference.values.firstWhere(
        (item) => item.name == map['theme'],
        orElse: () => AppThemePreference.system,
      ),
      defaultLandingPage: map['defaultLandingPage'] as String? ?? 'dashboard',
      rememberLastScreen: map['rememberLastScreen'] as bool? ?? true,
      pushNotifications: map['pushNotifications'] as bool? ?? true,
      homeworkNotifications: map['homeworkNotifications'] as bool? ?? true,
      attendanceNotifications: map['attendanceNotifications'] as bool? ?? true,
      feeNotifications: map['feeNotifications'] as bool? ?? true,
      examNotifications: map['examNotifications'] as bool? ?? true,
      paperSize: map['paperSize'] as String? ?? 'A4',
      receiptFormat: map['receiptFormat'] as String? ?? 'Standard',
      resultCardFormat: map['resultCardFormat'] as String? ?? 'Standard',
      language: map['language'] as String? ?? 'English',
      updatedAt: date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'theme': theme.name,
    'defaultLandingPage': defaultLandingPage,
    'rememberLastScreen': rememberLastScreen,
    'pushNotifications': pushNotifications,
    'homeworkNotifications': homeworkNotifications,
    'attendanceNotifications': attendanceNotifications,
    'feeNotifications': feeNotifications,
    'examNotifications': examNotifications,
    'paperSize': paperSize,
    'receiptFormat': receiptFormat,
    'resultCardFormat': resultCardFormat,
    'language': language,
    'updatedAt': updatedAt.toIso8601String(),
    'schemaVersion': 1,
  };
}
