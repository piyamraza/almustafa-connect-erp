import 'package:equatable/equatable.dart';

enum AppreciationCategory {
  academicExcellence,
  excellentProject,
  subjectAchievement,
  artCreativity,
  scienceExhibition,
  sportsAchievement,
  goodConduct,
  leadership,
  regularAttendance,
  communityService,
  specialAchievement,
  custom,
}

enum AppreciationTheme { blueGold, greenGold, maroonGold }

extension AppreciationEnumLabel on Enum {
  String get label => name
      .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class AppreciationCertificateEntity extends Equatable {
  const AppreciationCertificateEntity({
    required this.id,
    required this.serialNumber,
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.rollNumber,
    required this.className,
    required this.sectionName,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.description,
    required this.achievementDate,
    required this.issueDate,
    required this.teacherName,
    required this.principalName,
    required this.theme,
    required this.issuedAt,
  });
  final String id,
      serialNumber,
      studentId,
      studentName,
      admissionNumber,
      rollNumber,
      className,
      sectionName,
      categoryLabel,
      title,
      description,
      teacherName,
      principalName;
  final AppreciationCategory category;
  final AppreciationTheme theme;
  final DateTime achievementDate, issueDate, issuedAt;
  String get classSection =>
      [className, sectionName].where((e) => e.trim().isNotEmpty).join(' - ');
  @override
  List<Object> get props => [
    id,
    serialNumber,
    studentId,
    studentName,
    admissionNumber,
    rollNumber,
    className,
    sectionName,
    category,
    categoryLabel,
    title,
    description,
    achievementDate,
    issueDate,
    teacherName,
    principalName,
    theme,
    issuedAt,
  ];
}
