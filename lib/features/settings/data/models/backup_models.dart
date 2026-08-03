import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/backup_record_entity.dart';
import '../../domain/entities/restore_request_entity.dart';

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime.now();
}

class BackupRecordModel extends BackupRecordEntity {
  const BackupRecordModel({
    required super.id,
    required super.requestedBy,
    required super.requestedAt,
    required super.status,
    super.completedAt,
    super.fileName,
    super.fileUrl,
    super.notes,
    super.errorMessage,
  });

  factory BackupRecordModel.fromEntity(BackupRecordEntity e) =>
      BackupRecordModel(
        id: e.id,
        requestedBy: e.requestedBy,
        requestedAt: e.requestedAt,
        status: e.status,
        completedAt: e.completedAt,
        fileName: e.fileName,
        fileUrl: e.fileUrl,
        notes: e.notes,
        errorMessage: e.errorMessage,
      );

  factory BackupRecordModel.fromMap(Map<String, dynamic> map) =>
      BackupRecordModel(
        id: map['id'] as String? ?? '',
        requestedBy: map['requestedBy'] as String? ?? '',
        requestedAt: _date(map['requestedAt']),
        status: BackupStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BackupStatus.requested,
        ),
        completedAt: map['completedAt'] == null
            ? null
            : _date(map['completedAt']),
        fileName: map['fileName'] as String? ?? '',
        fileUrl: map['fileUrl'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        errorMessage: map['errorMessage'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'requestedBy': requestedBy,
    'requestedAt': requestedAt.toIso8601String(),
    'status': status.name,
    'completedAt': completedAt?.toIso8601String(),
    'fileName': fileName,
    'fileUrl': fileUrl,
    'notes': notes,
    'errorMessage': errorMessage,
    'schemaVersion': 1,
  };
}

class RestoreRequestModel extends RestoreRequestEntity {
  const RestoreRequestModel({
    required super.id,
    required super.backupId,
    required super.backupFileName,
    required super.requestedBy,
    required super.requestedAt,
    required super.status,
    required super.confirmationText,
    super.notes,
  });

  factory RestoreRequestModel.fromEntity(RestoreRequestEntity e) =>
      RestoreRequestModel(
        id: e.id,
        backupId: e.backupId,
        backupFileName: e.backupFileName,
        requestedBy: e.requestedBy,
        requestedAt: e.requestedAt,
        status: e.status,
        confirmationText: e.confirmationText,
        notes: e.notes,
      );

  factory RestoreRequestModel.fromMap(Map<String, dynamic> map) =>
      RestoreRequestModel(
        id: map['id'] as String? ?? '',
        backupId: map['backupId'] as String? ?? '',
        backupFileName: map['backupFileName'] as String? ?? '',
        requestedBy: map['requestedBy'] as String? ?? '',
        requestedAt: _date(map['requestedAt']),
        status: RestoreStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => RestoreStatus.requested,
        ),
        confirmationText: map['confirmationText'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'backupId': backupId,
    'backupFileName': backupFileName,
    'requestedBy': requestedBy,
    'requestedAt': requestedAt.toIso8601String(),
    'status': status.name,
    'confirmationText': confirmationText,
    'notes': notes,
    'schemaVersion': 1,
  };
}
