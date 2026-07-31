import 'package:equatable/equatable.dart';

import '../../domain/entities/result_analytics_entity.dart';

sealed class ResultsAnalyticsEvent extends Equatable {
  const ResultsAnalyticsEvent();

  @override
  List<Object?> get props => const [];
}

class LoadResultsAnalytics extends ResultsAnalyticsEvent {
  const LoadResultsAnalytics();
}

class RefreshResultsAnalytics extends ResultsAnalyticsEvent {
  const RefreshResultsAnalytics();
}

class FilterAnalyticsBySession extends ResultsAnalyticsEvent {
  const FilterAnalyticsBySession(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterAnalyticsByExam extends ResultsAnalyticsEvent {
  const FilterAnalyticsByExam(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterAnalyticsByClass extends ResultsAnalyticsEvent {
  const FilterAnalyticsByClass(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterAnalyticsBySection extends ResultsAnalyticsEvent {
  const FilterAnalyticsBySection(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterAnalyticsBySubject extends ResultsAnalyticsEvent {
  const FilterAnalyticsBySubject(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class FilterAnalyticsByStudent extends ResultsAnalyticsEvent {
  const FilterAnalyticsByStudent(this.value);

  final String? value;

  @override
  List<Object?> get props => [value];
}

class SearchAnalyticsStudents extends ResultsAnalyticsEvent {
  const SearchAnalyticsStudents(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SortAnalyticsSubjectRows extends ResultsAnalyticsEvent {
  const SortAnalyticsSubjectRows(this.sort);

  final AnalyticsSort sort;

  @override
  List<Object?> get props => [sort];
}

class SetAnalyticsBorderlineMargin extends ResultsAnalyticsEvent {
  const SetAnalyticsBorderlineMargin(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}

class SetAnalyticsLowPerformanceThreshold extends ResultsAnalyticsEvent {
  const SetAnalyticsLowPerformanceThreshold(this.value);

  final double value;

  @override
  List<Object?> get props => [value];
}
