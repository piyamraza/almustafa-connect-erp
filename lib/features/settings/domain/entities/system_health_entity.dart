import 'package:equatable/equatable.dart';

class SystemCollectionHealthEntity extends Equatable {
  const SystemCollectionHealthEntity({
    required this.name,
    required this.recordCount,
    required this.isReachable,
    this.errorMessage = '',
  });

  final String name;
  final int recordCount;
  final bool isReachable;
  final String errorMessage;

  @override
  List<Object?> get props => [name, recordCount, isReachable, errorMessage];
}

class SystemHealthEntity extends Equatable {
  const SystemHealthEntity({
    required this.checkedAt,
    required this.firestoreReachable,
    required this.authenticated,
    required this.currentUserId,
    required this.collections,
    required this.appVersion,
    required this.buildNumber,
    required this.firebaseProjectId,
    this.firestoreError = '',
  });

  final DateTime checkedAt;
  final bool firestoreReachable;
  final bool authenticated;
  final String currentUserId;
  final List<SystemCollectionHealthEntity> collections;
  final String appVersion;
  final String buildNumber;
  final String firebaseProjectId;
  final String firestoreError;

  int get totalRecords =>
      collections.fold<int>(0, (sum, item) => sum + item.recordCount);

  int get healthyCollections =>
      collections.where((item) => item.isReachable).length;

  @override
  List<Object?> get props => [
    checkedAt,
    firestoreReachable,
    authenticated,
    currentUserId,
    collections,
    appVersion,
    buildNumber,
    firebaseProjectId,
    firestoreError,
  ];
}
