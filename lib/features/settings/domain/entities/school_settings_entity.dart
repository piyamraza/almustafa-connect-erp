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
    this.principalName = '',
    this.principalDesignation = 'Principal',
    this.principalSignatureUrl = '',
    this.schoolStampUrl = '',
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

  final String principalName;
  final String principalDesignation;
  final String principalSignatureUrl;
  final String schoolStampUrl;

  SchoolSettingsEntity copyWith({
    String? id,
    String? schoolName,
    String? schoolCode,
    String? currentSession,
    DateTime? sessionStartDate,
    DateTime? sessionEndDate,
    String? currency,
    String? currencySymbol,
    String? dateFormat,
    String? timeFormat,
    String? admissionPrefix,
    String? rollNumberPrefix,
    String? receiptPrefix,
    DateTime? updatedAt,
    String? tagLine,
    String? address,
    String? city,
    String? country,
    String? phone,
    String? whatsApp,
    String? email,
    String? website,
    String? logoUrl,
    String? reportHeaderUrl,
    String? reportFooterUrl,
    String? principalName,
    String? principalDesignation,
    String? principalSignatureUrl,
    String? schoolStampUrl,
  }) {
    return SchoolSettingsEntity(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      schoolCode: schoolCode ?? this.schoolCode,
      currentSession: currentSession ?? this.currentSession,
      sessionStartDate:
          sessionStartDate ?? this.sessionStartDate,
      sessionEndDate:
          sessionEndDate ?? this.sessionEndDate,
      currency: currency ?? this.currency,
      currencySymbol:
          currencySymbol ?? this.currencySymbol,
      dateFormat: dateFormat ?? this.dateFormat,
      timeFormat: timeFormat ?? this.timeFormat,
      admissionPrefix:
          admissionPrefix ?? this.admissionPrefix,
      rollNumberPrefix:
          rollNumberPrefix ?? this.rollNumberPrefix,
      receiptPrefix:
          receiptPrefix ?? this.receiptPrefix,
      updatedAt: updatedAt ?? this.updatedAt,
      tagLine: tagLine ?? this.tagLine,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      whatsApp: whatsApp ?? this.whatsApp,
      email: email ?? this.email,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      reportHeaderUrl:
          reportHeaderUrl ?? this.reportHeaderUrl,
      reportFooterUrl:
          reportFooterUrl ?? this.reportFooterUrl,
      principalName:
          principalName ?? this.principalName,
      principalDesignation:
          principalDesignation ??
          this.principalDesignation,
      principalSignatureUrl:
          principalSignatureUrl ??
          this.principalSignatureUrl,
      schoolStampUrl:
          schoolStampUrl ?? this.schoolStampUrl,
    );
  }

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
    principalName,
    principalDesignation,
    principalSignatureUrl,
    schoolStampUrl,
  ];
}