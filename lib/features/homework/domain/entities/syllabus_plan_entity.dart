import 'package:equatable/equatable.dart';

class SyllabusPlanEntity extends Equatable {
  const SyllabusPlanEntity({
    required this.id,
    required this.academicSession,
    required this.title,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String academicSession;
  final String title;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  SyllabusPlanEntity copyWith({
    bool? isPublished,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) => SyllabusPlanEntity(
    id: id,
    academicSession: academicSession,
    title: title,
    isPublished: isPublished ?? this.isPublished,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
  );

  @override
  List<Object?> get props => [
    id,
    academicSession,
    title,
    isPublished,
    updatedAt,
    publishedAt,
  ];
}
