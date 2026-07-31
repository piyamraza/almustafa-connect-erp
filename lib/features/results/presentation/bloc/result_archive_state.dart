import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';

sealed class ResultArchiveState extends Equatable {
  const ResultArchiveState();

  @override
  List<Object?> get props => const [];
}

class ResultArchiveInitial extends ResultArchiveState {
  const ResultArchiveInitial();
}

class ResultArchiveLoading extends ResultArchiveState {
  const ResultArchiveLoading();
}

class ResultArchiveFailure extends ResultArchiveState {
  const ResultArchiveFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ResultArchiveLoaded extends ResultArchiveState {
  const ResultArchiveLoaded({
    required this.results,
    this.academicSession,
    this.examId,
    this.classId,
    this.sectionId,
    this.studentId,
    this.status,
    this.publicationRange,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  final List<ExamResultEntity> results;
  final String? academicSession;
  final String? examId;
  final String? classId;
  final String? sectionId;
  final String? studentId;
  final ResultStatus? status;
  final DateTimeRange? publicationRange;
  final String searchQuery;
  final bool isRefreshing;

  List<String> get sessions {
    final values = results
        .map((result) => result.academicSession.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values.reversed.toList(growable: false);
  }

  List<ExamResultEntity> get exams => _distinct(
    _base.where(
      (result) =>
          academicSession == null || result.academicSession == academicSession,
    ),
    (result) => result.examId,
    (result) => result.examName,
  );

  List<ExamResultEntity> get classes => _distinct(
    _base.where(
      (result) =>
          (academicSession == null ||
              result.academicSession == academicSession) &&
          (examId == null || result.examId == examId),
    ),
    (result) => result.classId,
    (result) => result.className,
  );

  List<ExamResultEntity> get sections => classId == null
      ? const []
      : _distinct(
          _base.where(
            (result) =>
                (academicSession == null ||
                    result.academicSession == academicSession) &&
                (examId == null || result.examId == examId) &&
                result.classId == classId,
          ),
          (result) => result.sectionId,
          (result) => result.sectionName,
        );

  List<ExamResultEntity> get students => _distinct(
    _base.where(
      (result) =>
          (academicSession == null ||
              result.academicSession == academicSession) &&
          (examId == null || result.examId == examId) &&
          (classId == null || result.classId == classId) &&
          (sectionId == null || result.sectionId == sectionId),
    ),
    (result) => result.studentId,
    (result) => result.studentName,
  );

  List<ExamResultEntity> get filteredResults {
    final query = searchQuery.trim().toLowerCase();
    final values = _base.where((result) {
      final publication = result.publishedAt ?? result.updatedAt;
      final inDateRange =
          publicationRange == null ||
          (!publication.isBefore(_dateOnly(publicationRange!.start)) &&
              !publication.isAfter(_endOfDay(publicationRange!.end)));
      final searchMatches =
          query.isEmpty ||
          [
            result.studentName,
            result.rollNumber,
            result.admissionNo,
            result.examName,
            result.className,
            result.sectionName,
          ].join(' ').toLowerCase().contains(query);
      return (academicSession == null ||
              result.academicSession == academicSession) &&
          (examId == null || result.examId == examId) &&
          (classId == null || result.classId == classId) &&
          (sectionId == null || result.sectionId == sectionId) &&
          (studentId == null || result.studentId == studentId) &&
          (status == null || result.status == status) &&
          inDateRange &&
          searchMatches;
    }).toList();
    values.sort(
      (first, second) => (second.publishedAt ?? second.updatedAt).compareTo(
        first.publishedAt ?? first.updatedAt,
      ),
    );
    return values;
  }

  List<ExamResultEntity> get _base => results;

  ResultArchiveLoaded copyWith({
    List<ExamResultEntity>? results,
    String? academicSession,
    String? examId,
    String? classId,
    String? sectionId,
    String? studentId,
    ResultStatus? status,
    DateTimeRange? publicationRange,
    String? searchQuery,
    bool? isRefreshing,
    bool clearSession = false,
    bool clearExam = false,
    bool clearClass = false,
    bool clearSection = false,
    bool clearStudent = false,
    bool clearStatus = false,
    bool clearPublicationRange = false,
  }) {
    return ResultArchiveLoaded(
      results: results ?? this.results,
      academicSession: clearSession
          ? null
          : academicSession ?? this.academicSession,
      examId: clearExam ? null : examId ?? this.examId,
      classId: clearClass ? null : classId ?? this.classId,
      sectionId: clearSection ? null : sectionId ?? this.sectionId,
      studentId: clearStudent ? null : studentId ?? this.studentId,
      status: clearStatus ? null : status ?? this.status,
      publicationRange: clearPublicationRange
          ? null
          : publicationRange ?? this.publicationRange,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    results,
    academicSession,
    examId,
    classId,
    sectionId,
    studentId,
    status,
    publicationRange,
    searchQuery,
    isRefreshing,
  ];
}

List<ExamResultEntity> _distinct(
  Iterable<ExamResultEntity> values,
  String Function(ExamResultEntity) id,
  String Function(ExamResultEntity) label,
) {
  final distinct = <String, ExamResultEntity>{};
  for (final value in values) {
    distinct.putIfAbsent(id(value), () => value);
  }
  final result = distinct.values.toList();
  result.sort((first, second) => label(first).compareTo(label(second)));
  return result;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
