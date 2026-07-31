import 'package:equatable/equatable.dart';

import '../../domain/entities/timetable_report_entity.dart';

sealed class TimetableReportState extends Equatable {
  const TimetableReportState();

  TimetableReportEntity? get report => null;

  @override
  List<Object?> get props => const [];
}

class TimetableReportInitial extends TimetableReportState {
  const TimetableReportInitial();
}

class TimetableReportLoading extends TimetableReportState {
  const TimetableReportLoading();
}

class TimetableReportLoaded extends TimetableReportState {
  const TimetableReportLoaded(this.value, {this.successMessage});

  final TimetableReportEntity value;
  final String? successMessage;

  @override
  TimetableReportEntity get report => value;

  @override
  List<Object?> get props => [value, successMessage];
}

class TimetableReportExporting extends TimetableReportState {
  const TimetableReportExporting(this.value);

  final TimetableReportEntity value;

  @override
  TimetableReportEntity get report => value;

  @override
  List<Object?> get props => [value];
}

class TimetableReportError extends TimetableReportState {
  const TimetableReportError(this.message, {this.previousReport});

  final String message;
  final TimetableReportEntity? previousReport;

  @override
  TimetableReportEntity? get report => previousReport;

  @override
  List<Object?> get props => [message, previousReport];
}
