import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../exams/domain/entities/exam_result_entity.dart';

sealed class ResultArchiveEvent extends Equatable {
  const ResultArchiveEvent();

  @override
  List<Object?> get props => const [];
}

class LoadResultArchive extends ResultArchiveEvent {
  const LoadResultArchive();
}

class RefreshResultArchive extends ResultArchiveEvent {
  const RefreshResultArchive();
}

class FilterArchiveBySession extends ResultArchiveEvent {
  const FilterArchiveBySession(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveByExam extends ResultArchiveEvent {
  const FilterArchiveByExam(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveByClass extends ResultArchiveEvent {
  const FilterArchiveByClass(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveBySection extends ResultArchiveEvent {
  const FilterArchiveBySection(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveByStudent extends ResultArchiveEvent {
  const FilterArchiveByStudent(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveByStatus extends ResultArchiveEvent {
  const FilterArchiveByStatus(this.value);

  final ResultStatus? value;

  @override
  List<Object?> get props => [value];
}

class FilterArchiveByPublicationDates extends ResultArchiveEvent {
  const FilterArchiveByPublicationDates(this.range);

  final DateTimeRange? range;

  @override
  List<Object?> get props => [range];
}

class SearchResultArchive extends ResultArchiveEvent {
  const SearchResultArchive(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
