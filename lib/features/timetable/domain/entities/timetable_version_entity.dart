import 'package:equatable/equatable.dart';

import 'class_timetable_entry_entity.dart';

enum TimetableVersionStatus { draft, published, archived }

class TimetableVersionEntity extends Equatable {
  TimetableVersionEntity({
    required this.id,
    required this.branchId,
    required this.academicSession,
    required this.name,
    required this.versionNumber,
    required this.status,
    required List<ClassTimetableEntryEntity> entries,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  }) : entries = List<ClassTimetableEntryEntity>.unmodifiable(entries);

  final String id;
  final String branchId;
  final String academicSession;
  final String name;
  final int versionNumber;
  final TimetableVersionStatus status;
  final List<ClassTimetableEntryEntity> entries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  int get entryCount => entries.length;

  TimetableVersionEntity copyWith({
    String? name,
    TimetableVersionStatus? status,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return TimetableVersionEntity(
      id: id,
      branchId: branchId,
      academicSession: academicSession,
      name: name ?? this.name,
      versionNumber: versionNumber,
      status: status ?? this.status,
      entries: entries,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    branchId,
    academicSession,
    name,
    versionNumber,
    status,
    entries,
    createdAt,
    updatedAt,
    publishedAt,
  ];
}
