import 'package:equatable/equatable.dart';

enum AppThemePreference { system, light, dark }

class UserPreferencesEntity extends Equatable {
  const UserPreferencesEntity({
    required this.id,
    required this.userId,
    required this.theme,
    required this.defaultLandingPage,
    required this.rememberLastScreen,
    required this.pushNotifications,
    required this.homeworkNotifications,
    required this.attendanceNotifications,
    required this.feeNotifications,
    required this.examNotifications,
    required this.paperSize,
    required this.receiptFormat,
    required this.resultCardFormat,
    required this.language,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final AppThemePreference theme;
  final String defaultLandingPage;
  final bool rememberLastScreen;
  final bool pushNotifications;
  final bool homeworkNotifications;
  final bool attendanceNotifications;
  final bool feeNotifications;
  final bool examNotifications;
  final String paperSize;
  final String receiptFormat;
  final String resultCardFormat;
  final String language;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    theme,
    defaultLandingPage,
    rememberLastScreen,
    pushNotifications,
    homeworkNotifications,
    attendanceNotifications,
    feeNotifications,
    examNotifications,
    paperSize,
    receiptFormat,
    resultCardFormat,
    language,
    updatedAt,
  ];
}
