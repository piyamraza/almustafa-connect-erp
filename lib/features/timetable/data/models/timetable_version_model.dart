import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/timetable_version_entity.dart';
import 'class_timetable_entry_model.dart';

class TimetableVersionModel extends TimetableVersionEntity {
  TimetableVersionModel({
    required super.id,
    required super.branchId,
    required super.academicSession,
    required super.name,
    required super.versionNumber,
    required super.status,
    required super.entries,
    required super.createdAt,
    required super.updatedAt,
    super.publishedAt,
  });

  factory TimetableVersionModel.fromEntity(TimetableVersionEntity entity) {
    return TimetableVersionModel(
      id: entity.id,
      branchId: entity.branchId,
      academicSession: entity.academicSession,
      name: entity.name,
      versionNumber: entity.versionNumber,
      status: entity.status,
      entries: entity.entries,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      publishedAt: entity.publishedAt,
    );
  }

  factory TimetableVersionModel.fromMap(Map<String, dynamic> map) {
    final rawEntries = (map['entries'] as List<dynamic>? ?? const []);
    return TimetableVersionModel(
      id: map['id'] as String? ?? '',
      branchId: map['branchId'] as String? ?? '',
      academicSession: map['academicSession'] as String? ?? '',
      name: map['name'] as String? ?? '',
      versionNumber: (map['versionNumber'] as num?)?.toInt() ?? 0,
      status: _statusFromName(map['status'] as String?),
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(ClassTimetableEntryModel.fromMap)
          .toList(growable: false),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      publishedAt: _nullableDate(map['publishedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'academicSession': academicSession,
      'name': name,
      'versionNumber': versionNumber,
      'status': status.name,
      'entries': entries
          .map((entry) => ClassTimetableEntryModel.fromEntity(entry).toMap())
          .toList(growable: false),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt == null
          ? null
          : Timestamp.fromDate(publishedAt!),
    };
  }

  static TimetableVersionStatus _statusFromName(String? value) {
    return TimetableVersionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => TimetableVersionStatus.draft,
    );
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _nullableDate(dynamic value) {
    if (value == null) return null;
    return _date(value);
  }
}
