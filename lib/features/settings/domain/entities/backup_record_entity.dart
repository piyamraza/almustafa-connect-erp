import 'package:equatable/equatable.dart';

enum BackupStatus { requested, processing, completed, failed }

class BackupRecordEntity extends Equatable {
  const BackupRecordEntity({
    required this.id,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    this.completedAt,
    this.fileName = '',
    this.fileUrl = '',
    this.notes = '',
    this.errorMessage = '',
  });

  final String id;
  final String requestedBy;
  final DateTime requestedAt;
  final BackupStatus status;
  final DateTime? completedAt;
  final String fileName;
  final String fileUrl;
  final String notes;
  final String errorMessage;

  @override
  List<Object?> get props => [
    id,
    requestedBy,
    requestedAt,
    status,
    completedAt,
    fileName,
    fileUrl,
    notes,
    errorMessage,
  ];
}
