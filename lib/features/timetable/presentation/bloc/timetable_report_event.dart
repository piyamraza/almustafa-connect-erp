import 'package:equatable/equatable.dart';

import '../../domain/entities/timetable_report_entity.dart';

sealed class TimetableReportEvent extends Equatable {
  const TimetableReportEvent();

  @override
  List<Object?> get props => const [];
}

class GenerateTimetableReportEvent extends TimetableReportEvent {
  const GenerateTimetableReportEvent(this.request);

  final TimetableReportRequestEntity request;

  @override
  List<Object?> get props => [request];
}

class ExportTimetableReportEvent extends TimetableReportEvent {
  const ExportTimetableReportEvent(this.action);

  final TimetableReportExportAction action;

  @override
  List<Object?> get props => [action];
}
