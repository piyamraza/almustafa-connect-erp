import 'package:equatable/equatable.dart';

enum RestoreStatus {
  requested,
  approved,
  processing,
  completed,
  rejected,
  failed,
}

class RestoreRequestEntity extends Equatable {
  const RestoreRequestEntity({
    required this.id,
    required this.backupId,
    required this.backupFileName,
    required this.requestedBy,
    required this.requestedAt,
    required this.status,
    required this.confirmationText,
    this.notes = '',
  });

  final String id;
  final String backupId;
  final String backupFileName;
  final String requestedBy;
  final DateTime requestedAt;
  final RestoreStatus status;
  final String confirmationText;
  final String notes;

  @override
  List<Object?> get props => [
    id,
    backupId,
    backupFileName,
    requestedBy,
    requestedAt,
    status,
    confirmationText,
    notes,
  ];
}
