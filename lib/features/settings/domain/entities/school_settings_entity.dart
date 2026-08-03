import 'package:equatable/equatable.dart';

class SchoolSettingsEntity extends Equatable {
  const SchoolSettingsEntity({
    required this.id,
    required this.schoolName,
    required this.schoolCode,
    required this.currentSession,
    required this.sessionStartDate,
    required this.sessionEndDate,
    required this.currency,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timeFormat,
    required this.admissionPrefix,
    required this.rollNumberPrefix,
    required this.receiptPrefix,
    required this.updatedAt,
    this.tagLine = '',
    this.address = '',
    this.city = '',
    this.country = 'Pakistan',
    this.phone = '',
    this.whatsApp = '',
    this.email = '',
    this.website = '',
    this.logoUrl = '',
    this.reportHeaderUrl = '',
    this.reportFooterUrl = '',
  });

  final String id;
  final String schoolName;
  final String schoolCode;
  final String currentSession;
  final DateTime sessionStartDate;
  final DateTime sessionEndDate;
  final String currency;
  final String currencySymbol;
  final String dateFormat;
  final String timeFormat;
  final String admissionPrefix;
  final String rollNumberPrefix;
  final String receiptPrefix;
  final DateTime updatedAt;
  final String tagLine;
  final String address;
  final String city;
  final String country;
  final String phone;
  final String whatsApp;
  final String email;
  final String website;
  final String logoUrl;
  final String reportHeaderUrl;
  final String reportFooterUrl;

  @override
  List<Object?> get props => [
    id,
    schoolName,
    schoolCode,
    currentSession,
    sessionStartDate,
    sessionEndDate,
    currency,
    currencySymbol,
    dateFormat,
    timeFormat,
    admissionPrefix,
    rollNumberPrefix,
    receiptPrefix,
    updatedAt,
    tagLine,
    address,
    city,
    country,
    phone,
    whatsApp,
    email,
    website,
    logoUrl,
    reportHeaderUrl,
    reportFooterUrl,
  ];
}
