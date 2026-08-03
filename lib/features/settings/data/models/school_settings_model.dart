import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/school_settings_entity.dart';

class SchoolSettingsModel extends SchoolSettingsEntity {
  const SchoolSettingsModel({
    required super.id,
    required super.schoolName,
    required super.schoolCode,
    required super.currentSession,
    required super.sessionStartDate,
    required super.sessionEndDate,
    required super.currency,
    required super.currencySymbol,
    required super.dateFormat,
    required super.timeFormat,
    required super.admissionPrefix,
    required super.rollNumberPrefix,
    required super.receiptPrefix,
    required super.updatedAt,
    super.tagLine,
    super.address,
    super.city,
    super.country,
    super.phone,
    super.whatsApp,
    super.email,
    super.website,
    super.logoUrl,
    super.reportHeaderUrl,
    super.reportFooterUrl,
  });

  factory SchoolSettingsModel.fromEntity(SchoolSettingsEntity entity) {
    return SchoolSettingsModel(
      id: entity.id,
      schoolName: entity.schoolName,
      schoolCode: entity.schoolCode,
      currentSession: entity.currentSession,
      sessionStartDate: entity.sessionStartDate,
      sessionEndDate: entity.sessionEndDate,
      currency: entity.currency,
      currencySymbol: entity.currencySymbol,
      dateFormat: entity.dateFormat,
      timeFormat: entity.timeFormat,
      admissionPrefix: entity.admissionPrefix,
      rollNumberPrefix: entity.rollNumberPrefix,
      receiptPrefix: entity.receiptPrefix,
      updatedAt: entity.updatedAt,
      tagLine: entity.tagLine,
      address: entity.address,
      city: entity.city,
      country: entity.country,
      phone: entity.phone,
      whatsApp: entity.whatsApp,
      email: entity.email,
      website: entity.website,
      logoUrl: entity.logoUrl,
      reportHeaderUrl: entity.reportHeaderUrl,
      reportFooterUrl: entity.reportFooterUrl,
    );
  }

  factory SchoolSettingsModel.fromMap(Map<String, dynamic> map) {
    DateTime date(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.tryParse('$value') ?? DateTime.now();
    }

    return SchoolSettingsModel(
      id: map['id'] as String? ?? 'default',
      schoolName: map['schoolName'] as String? ?? 'Almustafa Model School',
      schoolCode: map['schoolCode'] as String? ?? 'AMS',
      currentSession: map['currentSession'] as String? ?? '2026-2027',
      sessionStartDate: date(map['sessionStartDate']),
      sessionEndDate: date(map['sessionEndDate']),
      currency: map['currency'] as String? ?? 'PKR',
      currencySymbol: map['currencySymbol'] as String? ?? 'Rs.',
      dateFormat: map['dateFormat'] as String? ?? 'dd-MM-yyyy',
      timeFormat: map['timeFormat'] as String? ?? '12 Hour',
      admissionPrefix: map['admissionPrefix'] as String? ?? 'AMS',
      rollNumberPrefix: map['rollNumberPrefix'] as String? ?? '',
      receiptPrefix: map['receiptPrefix'] as String? ?? 'REC',
      updatedAt: date(map['updatedAt']),
      tagLine: map['tagLine'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? 'Multan',
      country: map['country'] as String? ?? 'Pakistan',
      phone: map['phone'] as String? ?? '',
      whatsApp: map['whatsApp'] as String? ?? '',
      email: map['email'] as String? ?? '',
      website: map['website'] as String? ?? '',
      logoUrl: map['logoUrl'] as String? ?? '',
      reportHeaderUrl: map['reportHeaderUrl'] as String? ?? '',
      reportFooterUrl: map['reportFooterUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'schoolName': schoolName,
    'schoolCode': schoolCode,
    'currentSession': currentSession,
    'sessionStartDate': sessionStartDate.toIso8601String(),
    'sessionEndDate': sessionEndDate.toIso8601String(),
    'currency': currency,
    'currencySymbol': currencySymbol,
    'dateFormat': dateFormat,
    'timeFormat': timeFormat,
    'admissionPrefix': admissionPrefix,
    'rollNumberPrefix': rollNumberPrefix,
    'receiptPrefix': receiptPrefix,
    'updatedAt': updatedAt.toIso8601String(),
    'tagLine': tagLine,
    'address': address,
    'city': city,
    'country': country,
    'phone': phone,
    'whatsApp': whatsApp,
    'email': email,
    'website': website,
    'logoUrl': logoUrl,
    'reportHeaderUrl': reportHeaderUrl,
    'reportFooterUrl': reportFooterUrl,
    'schemaVersion': 1,
  };
}
